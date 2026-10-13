import SwiftUI
import AppKit
import Combine
import UserNotifications
import AVFoundation

// MARK: - Types

enum Mode: String, Codable, CaseIterable, Identifiable {
    case focus, short, long
    var id: String { rawValue }
    var title: String {
        switch self { case .focus: "Focus"; case .short: "Short break"; case .long: "Long break" }
    }
    var symbol: String {
        switch self { case .focus: "circle.lefthalf.filled"; case .short: "cup.and.saucer"; case .long: "leaf" }
    }
}

enum Status: String, Codable { case idle, running, paused, overflow }
enum Ambient: String, Codable, CaseIterable, Identifiable {
    case off, rain1, rain2, rain3, rain4, umbrella, fireplace, beach, jungle, file
    var id: String { rawValue }
    var title: String {
        switch self {
        case .off: "Off"
        case .rain1: "Rain recording 1"
        case .rain2: "Rain recording 2"
        case .rain3: "Rain recording 3"
        case .rain4: "Rain recording 4"
        case .umbrella: "Rain under an umbrella"
        case .fireplace: "Fireplace"
        case .beach: "Beach waves"
        case .jungle: "Jungle"
        case .file: "Custom audio file"
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        if raw == "brown" || raw == "rain" { self = .off; return }  // removed generated sounds
        guard let v = Ambient(rawValue: raw) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown ambient \(raw)"))
        }
        self = v
    }
}
enum AppearancePref: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct Tag: Identifiable, Hashable {
    let id: String, name: String, color: Color
    static let all: [Tag] = [
        Tag(id: "deep", name: "Deep work", color: Palette.focus),
        Tag(id: "write", name: "Writing", color: Color(hex: 0xD9822B)),
        Tag(id: "study", name: "Study", color: Palette.short),
        Tag(id: "admin", name: "Admin", color: Palette.long),
    ]
    static func find(_ id: String) -> Tag { all.first { $0.id == id } ?? all[0] }
}

struct Prefs: Codable, Equatable {
    var focus = 25, short = 5, long = 15, every = 4, goal = 8
    var autoBreak = true, autoFocus = false, overflow = false, sound = true
    var ambient: Ambient = .off
    var ambientFile: String?
    var appearance: AppearancePref = .system
    var menuBarCountdown = true
    var keepOnTop = false

    func minutes(_ m: Mode) -> Int { switch m { case .focus: focus; case .short: short; case .long: long } }
    mutating func set(_ m: Mode, _ v: Int) { switch m { case .focus: focus = v; case .short: short = v; case .long: long = v } }
}

struct Session: Codable, Identifiable {
    var id = UUID()
    var end: Date
    var minutes: Double
    var intent: String
    var tag: String
}

// MARK: - Palette (mirrors the web tokens)

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
    static func dyn(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { ap in
            let h = ap.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: 1)
        })
    }
}

enum Palette {
    static let bg = Color.dyn(0xF2F3F7, 0x0C0E16)
    static let surface = Color.dyn(0xFFFFFF, 0x151827)
    static let surface2 = Color.dyn(0xE8EAF1, 0x1D2133)
    static let ink = Color.dyn(0x151827, 0xE9EBF4)
    static let muted = Color.dyn(0x666B83, 0x8F94AD)
    static let line = Color.dyn(0xDADDE7, 0x272B3E)
    static let major = Color.dyn(0xA7ABBC, 0x4A4F68)
    static let focus = Color.dyn(0x3346E0, 0x8190FF)
    static let short = Color.dyn(0x0C8467, 0x3ECFA6)
    static let long = Color.dyn(0xA93D7A, 0xF07DB8)
    static let onAccent = Color.dyn(0xFFFFFF, 0x0C0E16)
    static func accent(_ m: Mode) -> Color { switch m { case .focus: focus; case .short: short; case .long: long } }
}

// MARK: - Timer model

@MainActor
final class TimerModel: ObservableObject {
    static let shared = TimerModel()

    @Published var prefs: Prefs { didSet { if prefs != oldValue { savePrefs(); applyWindowPrefs() } } }
    @Published private(set) var history: [Session]
    @Published private(set) var mode: Mode = .focus
    @Published private(set) var status: Status = .idle
    @Published private(set) var round = 0
    @Published var intent = ""
    @Published var tag = "deep"
    @Published private(set) var now = Date()
    @Published var banner: String?

    private var remaining: TimeInterval
    private(set) var endAt = Date.distantPast
    private var ticker: AnyCancellable?
    private var activity: NSObjectProtocol?
    private let noise = AmbientPlayer()
    private var bannerTask: Task<Void, Never>?

    private init() {
        let d = UserDefaults.standard
        let p = (d.data(forKey: "prefs")).flatMap { try? JSONDecoder().decode(Prefs.self, from: $0) } ?? Prefs()
        prefs = p
        history = (d.data(forKey: "history")).flatMap { try? JSONDecoder().decode([Session].self, from: $0) } ?? []
        remaining = Double(p.focus) * 60
        round = d.integer(forKey: "round")
        ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect().sink { [weak self] t in
            MainActor.assumeIsolated { self?.tick(t) }
        }
    }

    // Derived
    var accent: Color { Palette.accent(mode) }
    var total: TimeInterval { Double(prefs.minutes(mode)) * 60 }
    var timeLeft: TimeInterval { status == .running ? max(0, endAt.timeIntervalSince(now)) : remaining }
    var overflowTime: TimeInterval { max(0, now.timeIntervalSince(endAt)) }
    var display: String { status == .overflow ? "+" + Self.fmt(overflowTime, up: true) : Self.fmt(timeLeft, up: false) }
    var isActive: Bool { status == .running || status == .overflow }

    var eyebrow: String { status == .overflow ? "Overflow" : mode.title }
    var subtitle: String {
        switch status {
        case .overflow: return "Keep going, or finish when ready"
        case .paused: return "Paused"
        case .idle: return mode == .focus ? "Drag the dial to set" : "Stand up. Look far away."
        case .running:
            let t = intent.trimmingCharacters(in: .whitespaces)
            if mode == .focus && !t.isEmpty { return t }
            return (mode == .focus ? "Until " : "Back at ") + endAt.formatted(date: .omitted, time: .shortened)
        }
    }
    var primaryLabel: String {
        switch status {
        case .running: "Pause"
        case .paused: "Resume"
        case .overflow: "Finish session"
        case .idle: mode == .focus ? "Start focus" : "Start break"
        }
    }

    static func fmt(_ t: TimeInterval, up: Bool) -> String {
        let s = up ? Int(t.rounded(.down)) : Int(t.rounded(.up))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    // MARK: Actions

    func primary() {
        switch status {
        case .running: pause()
        case .overflow: finishFocus(extra: overflowTime)
        default: start()
        }
    }

    func start() {
        guard status == .idle || status == .paused else { return }
        endAt = Date().addingTimeInterval(remaining > 0 ? remaining : total)
        now = Date()
        status = .running
        sideEffects()
    }

    func pause() {
        guard status == .running else { return }
        remaining = max(0, endAt.timeIntervalSinceNow)
        status = .paused
        sideEffects()
    }

    func reset() {
        status = .idle
        remaining = total
        sideEffects()
    }

    func skip() {
        if status == .overflow { return finishFocus(extra: overflowTime) }
        if mode == .focus { round += 1; switchMode(nextBreak, autostart: false) }
        else { if mode == .long { round = 0 }; switchMode(.focus, autostart: false) }
    }

    func select(_ m: Mode) {
        guard m != mode || status != .idle else { return }
        switchMode(m, autostart: false)
    }

    func setMinutes(_ m: Int) {
        guard status == .idle else { return }
        let v = max(1, min(60, m))
        guard prefs.minutes(mode) != v else { return }
        prefs.set(mode, v)
        remaining = total
    }

    func prefsChangedDuration() { if status == .idle { remaining = total } }

    func clearHistory() { history = []; saveHistory(); flash("History cleared") }

    // MARK: Internals

    private var nextBreak: Mode { round % prefs.every == 0 ? .long : .short }

    private func switchMode(_ m: Mode, autostart: Bool) {
        mode = m
        status = .idle
        remaining = total
        UserDefaults.standard.set(round, forKey: "round")
        sideEffects()
        if autostart { start() }
    }

    private func tick(_ t: Date) {
        now = t
        if status == .running && endAt <= t { complete() }
    }

    private func complete() {
        if mode == .focus {
            if prefs.overflow {
                status = .overflow
                chime(soft: true)
                notify("Focus time’s up", "You’re in overflow. Finish when you reach a stopping point.")
                sideEffects()
                return
            }
            chime(soft: false)
            finishFocus(extra: 0)
        } else {
            chime(soft: true)
            if mode == .long { round = 0 }
            notify("Break’s over", "Ready for the next focus session?")
            flash("Break’s over.")
            switchMode(.focus, autostart: prefs.autoFocus)
        }
    }

    private func finishFocus(extra: TimeInterval) {
        let s = Session(end: Date(), minutes: Double(prefs.focus) + extra / 60,
                        intent: intent.trimmingCharacters(in: .whitespaces), tag: tag)
        history.append(s)
        if history.count > 5000 { history.removeFirst(history.count - 5000) }
        saveHistory()
        round += 1
        let b = nextBreak
        let msg = b == .long ? "Round complete. Take \(prefs.long) minutes." : "Session logged. Take \(prefs.short)."
        notify("Focus session complete", msg)
        flash(msg)
        switchMode(b, autostart: prefs.autoBreak)
    }

    private func sideEffects() {
        // Keep the display awake while a session runs
        if isActive, activity == nil {
            activity = ProcessInfo.processInfo.beginActivity(options: [.idleDisplaySleepDisabled, .userInitiated], reason: "Pomelo session")
        } else if !isActive, let a = activity {
            ProcessInfo.processInfo.endActivity(a); activity = nil
        }
        if mode == .focus && isActive {
            if !noise.play(prefs.ambient, file: prefs.ambientFile) {
                flash("Could not play the audio file. Choose another file in Settings.")
            }
        } else { noise.stop() }
    }

    func ambientChanged() { sideEffects() }

    private func chime(soft: Bool) {
        guard prefs.sound else { return }
        NSSound(named: soft ? "Tink" : "Glass")?.play()
    }

    private func notify(_ title: String, _ body: String) {
        let c = UNMutableNotificationContent()
        c.title = title; c.body = body
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
    }

    func flash(_ s: String) {
        banner = s
        bannerTask?.cancel()
        bannerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.4))
            if !Task.isCancelled { self?.banner = nil }
        }
    }

    private func savePrefs() {
        if let d = try? JSONEncoder().encode(prefs) { UserDefaults.standard.set(d, forKey: "prefs") }
    }
    private func saveHistory() {
        if let d = try? JSONEncoder().encode(history) { UserDefaults.standard.set(d, forKey: "history") }
    }

    func applyWindowPrefs() {
        switch prefs.appearance {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
        for w in NSApp.windows where w.identifier?.rawValue.hasPrefix("main") == true {
            w.level = prefs.keepOnTop ? .floating : .normal
        }
    }

    // MARK: Stats

    var isSample: Bool { history.isEmpty }
    private var statData: [Session] { history.isEmpty ? Self.sample : history }

    var todaySessions: [Session] { statData.filter { Calendar.current.isDateInToday($0.end) } }
    var todayMinutes: Int { Int(todaySessions.reduce(0) { $0 + $1.minutes }.rounded()) }
    var realToday: [Session] { history.filter { Calendar.current.isDateInToday($0.end) }.reversed() }

    var streak: Int {
        let cal = Calendar.current
        let days = Set(statData.map { cal.startOfDay(for: $0.end) })
        var d = cal.startOfDay(for: Date())
        if !days.contains(d) { d = cal.date(byAdding: .day, value: -1, to: d)! }
        var n = 0
        while days.contains(d) { n += 1; d = cal.date(byAdding: .day, value: -1, to: d)! }
        return n
    }

    var week: [(label: String, minutes: Int, today: Bool)] {
        let cal = Calendar.current
        let f = DateFormatter(); f.dateFormat = "EEE"
        return (0..<7).reversed().map { back in
            let day = cal.date(byAdding: .day, value: -back, to: cal.startOfDay(for: Date()))!
            let mins = statData.filter { cal.isDate($0.end, inSameDayAs: day) }.reduce(0) { $0 + $1.minutes }
            return (back == 0 ? "Today" : f.string(from: day), Int(mins.rounded()), back == 0)
        }
    }

    private static let sample: [Session] = {
        let cal = Calendar.current
        var out: [Session] = []
        for (i, n) in [5, 7, 3, 8, 6, 2, 0].enumerated() {
            let day = cal.date(byAdding: .day, value: -(6 - i), to: cal.startOfDay(for: Date()))!.addingTimeInterval(9 * 3600)
            for k in 0..<n { out.append(Session(end: day.addingTimeInterval(Double(k) * 1900), minutes: 25, intent: "", tag: "deep")) }
        }
        return out
    }()
}

// MARK: - Ambient audio

final class AmbientPlayer {
    private var player: AVAudioPlayer?
    private var kind: Ambient = .off
    private var path: String?

    /// Returns false when the sound could not be played.
    func play(_ k: Ambient, file: String?) -> Bool {
        if k == kind, path == file, player != nil { return true }
        stop()
        guard k != .off else { return true }
        let url: URL?
        if k == .file { url = file.map { URL(fileURLWithPath: $0) } }
        else { url = Bundle.main.url(forResource: k.rawValue, withExtension: "mp3", subdirectory: "Sounds") }
        guard let url, let p = try? AVAudioPlayer(contentsOf: url) else { return false }
        p.numberOfLoops = -1
        p.volume = 0.5
        guard p.play() else { return false }
        player = p; kind = k; path = file
        return true
    }

    func stop() {
        player?.stop()
        player = nil
        kind = .off
        path = nil
    }
}

// MARK: - Screenshot demo state (compiled only with -D SNAPSHOT)

#if SNAPSHOT
extension TimerModel {
    func loadDemo() {
        let cal = Calendar.current
        var h: [Session] = []
        let intents = ["Refactor the sync engine", "Read: Designing Data-Intensive Apps", "Inbox zero", "Sketch onboarding flow"]
        for (back, n) in [(6, 5), (5, 7), (4, 3), (3, 8), (2, 6), (1, 4)] {
            let day = cal.date(byAdding: .day, value: -back, to: cal.startOfDay(for: Date()))!.addingTimeInterval(9 * 3600)
            for k in 0..<n { h.append(Session(end: day.addingTimeInterval(Double(k) * 1900), minutes: 25, intent: intents[k % 4], tag: Tag.all[k % 4].id)) }
        }
        let start = cal.startOfDay(for: Date()).addingTimeInterval(9 * 3600)
        h.append(Session(end: start, minutes: 25, intent: "Inbox zero", tag: "admin"))
        h.append(Session(end: start.addingTimeInterval(1900), minutes: 31, intent: "Outline chapter 3", tag: "write"))
        history = h
        round = 2
        intent = "Draft the Q4 roadmap"
        tag = "deep"
        mode = .focus
        remaining = 17 * 60 + 42
        status = .paused
    }
}
#endif
