import SwiftUI
import AppKit
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Dial

struct Dial: View {
    @EnvironmentObject var m: TimerModel
    var compact = false
    @State private var dragging = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let k = s / 400
            let accent = m.accent
            let secs = m.status == .overflow ? 0 : m.timeLeft
            let f = min(secs / 3600, 0.99999)
            let settable = m.status == .idle && !compact

            ZStack {
                Canvas { ctx, size in
                    let c = CGPoint(x: size.width / 2, y: size.height / 2)
                    func pt(_ r: Double, _ a: Double) -> CGPoint { CGPoint(x: c.x + r * k * sin(a), y: c.y - r * k * cos(a)) }
                    let lit = Int(ceil(secs / 60))
                    for i in 0..<60 {
                        let a = Double(i) / 60 * .pi * 2, major = i % 5 == 0
                        var p = Path()
                        p.move(to: pt(190, a)); p.addLine(to: pt(190 - (major ? 14 : 7), a))
                        let col = i < lit ? accent : (major ? Palette.major : Palette.line)
                        ctx.stroke(p, with: .color(col), style: StrokeStyle(lineWidth: (major ? 2.4 : 1.4) * k, lineCap: .round))
                        if major && !compact {
                            ctx.draw(Text("\(i)").font(.system(size: max(9, 11 * k), weight: .medium, design: .monospaced)).foregroundColor(Palette.muted), at: pt(162, a))
                        }
                    }
                    if f > 0 {
                        var w = Path()
                        w.move(to: c)
                        w.addLine(to: pt(150, 0))
                        w.addArc(center: c, radius: 150 * k, startAngle: .degrees(-90), endAngle: .degrees(-90 + f * 360), clockwise: false)
                        w.closeSubpath()
                        ctx.fill(w, with: .color(accent.opacity(0.2)))
                        var e = Path()
                        e.addArc(center: c, radius: 150 * k, startAngle: .degrees(-90), endAngle: .degrees(-90 + f * 360), clockwise: false)
                        ctx.stroke(e, with: .color(accent), style: StrokeStyle(lineWidth: 3 * k, lineCap: .round))
                    }
                }

                Circle()
                    .fill(Palette.surface)
                    .frame(width: 224 * k, height: 224 * k)
                    .shadow(color: .black.opacity(0.14), radius: 16 * k, y: 6 * k)

                if settable {
                    let a = f * .pi * 2
                    Circle()
                        .fill(Palette.surface)
                        .overlay(Circle().stroke(accent, lineWidth: 3 * k))
                        .frame(width: 18 * k, height: 18 * k)
                        .position(x: s / 2 + 150 * k * sin(a), y: s / 2 - 150 * k * cos(a))
                }

                VStack(spacing: 6 * k) {
                    Text(m.eyebrow.uppercased())
                        .font(.system(size: 10 * k * (compact ? 1.5 : 1.05), weight: .medium, design: .monospaced))
                        .tracking(1.6 * k)
                        .foregroundStyle(accent)
                    Text(m.display)
                        .font(.system(size: 62 * k, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(m.status == .overflow ? accent : Palette.ink)
                        .contentTransition(.numericText(countsDown: true))
                    if !compact {
                        Text(m.subtitle)
                            .font(.system(size: 11.5 * k))
                            .foregroundStyle(Palette.muted)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 170 * k)
                    }
                }
            }
            .frame(width: s, height: s)
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { g in
                    guard settable else { return }
                    let x = g.location.x - s / 2, y = g.location.y - s / 2
                    if !dragging {
                        guard hypot(x, y) > 100 * k else { return }
                        dragging = true
                    }
                    var a = atan2(x, -y); if a < 0 { a += .pi * 2 }
                    var mins = Int((a / (.pi * 2) * 60).rounded()); if mins == 0 { mins = 60 }
                    let cur = m.prefs.minutes(m.mode)
                    if cur >= 55 && mins <= 5 { mins = 60 } else if cur <= 5 && mins >= 55 { mins = 1 }
                    m.setMinutes(mins)
                }
                .onEnded { _ in dragging = false })
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .animation(.easeInOut(duration: 0.6), value: m.mode)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Controls

struct PillButton: ButtonStyle {
    var color: Color
    var compact = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 14 : 16, weight: .semibold))
            .foregroundStyle(Palette.onAccent)
            .padding(.horizontal, compact ? 18 : 28)
            .frame(minWidth: compact ? 124 : 168, minHeight: compact ? 40 : 52)
            .background(Capsule().fill(color))
            .shadow(color: color.opacity(0.45), radius: 14, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct RoundIconButton: ButtonStyle {
    var size: CGFloat = 46
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Palette.ink)
            .frame(width: size, height: size)
            .background(Circle().fill(Palette.surface))
            .overlay(Circle().stroke(Palette.line, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct Controls: View {
    @EnvironmentObject var m: TimerModel
    var compact = false
    var body: some View {
        HStack(spacing: compact ? 10 : 14) {
            Button { m.reset() } label: { Image(systemName: "arrow.counterclockwise") }
                .buttonStyle(RoundIconButton(size: compact ? 38 : 46)).help("Reset (⌘R)")
            Button(m.primaryLabel) { m.primary() }
                .buttonStyle(PillButton(color: m.accent, compact: compact))
            Button { m.skip() } label: { Image(systemName: "forward.end.fill") }
                .buttonStyle(RoundIconButton(size: compact ? 38 : 46)).help("Skip (⌘→)")
        }
    }
}

struct ModePicker: View {
    @EnvironmentObject var m: TimerModel
    @Namespace private var ns
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Mode.allCases) { mode in
                let on = m.mode == mode
                Button { withAnimation(.snappy) { m.select(mode) } } label: {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(on ? Palette.onAccent : Palette.muted)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background {
                            if on { Capsule().fill(m.accent).matchedGeometryEffect(id: "pill", in: ns) }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(Palette.surface.opacity(0.7)))
        .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
    }
}

// MARK: - Rail

struct SectionLabel: View {
    var text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
            .tracking(1.3)
            .foregroundStyle(Palette.muted)
    }
}

struct Rail: View {
    var body: some View {
        ScrollView(showsIndicators: false) { RailContent() }
    }
}

struct RailContent: View {
    @EnvironmentObject var m: TimerModel
    @FocusState private var intentFocused: Bool

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: "Intention")
                    #if SNAPSHOT // ImageRenderer can't draw AppKit-backed text fields
                    Text(m.intent).frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .padding(.bottom, 8)
                        .overlay(alignment: .bottom) { Rectangle().fill(Palette.line).frame(height: 1.5) }
                    #else
                    TextField("What’s this session for?", text: $m.intent)
                        .textFieldStyle(.plain)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .focused($intentFocused)
                        .onSubmit { if m.status == .idle && m.mode == .focus { m.start() } }
                        .padding(.bottom, 8)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(intentFocused ? m.accent : Palette.line).frame(height: 1.5)
                        }
                    #endif
                    HStack(spacing: 6) {
                        ForEach(Tag.all) { t in
                            let on = m.tag == t.id
                            Button { m.tag = t.id } label: {
                                HStack(spacing: 6) {
                                    Circle().fill(t.color).frame(width: 7, height: 7)
                                    Text(t.name).font(.system(size: 12))
                                }
                                .foregroundStyle(on ? Palette.ink : Palette.muted)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Capsule().fill(on ? Palette.surface : .clear))
                                .overlay(Capsule().stroke(on ? Palette.ink : Palette.line, lineWidth: 1))
                                .contentShape(Capsule())
                            }.buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: "Cycle")
                    CycleDots()
                }

                StatsCard()

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "Completed today")
                    let today = m.realToday
                    if today.isEmpty {
                        Text("Nothing yet. Your finished focus sessions land here.")
                            .font(.system(size: 12.5)).foregroundStyle(Palette.muted)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(today.prefix(8).enumerated()), id: \.element.id) { i, s in
                                if i > 0 { Rectangle().fill(Palette.line).frame(height: 1) }
                                HStack(spacing: 10) {
                                    Circle().fill(Tag.find(s.tag).color).frame(width: 8, height: 8)
                                    Text(s.intent.isEmpty ? Tag.find(s.tag).name : s.intent)
                                        .font(.system(size: 13)).lineLimit(1)
                                    Spacer()
                                    Text("\(Int(s.minutes.rounded()))m").font(.system(size: 11.5, design: .monospaced)).foregroundStyle(Palette.muted)
                                    Text(s.end.formatted(date: .omitted, time: .shortened)).font(.system(size: 11.5, design: .monospaced)).foregroundStyle(Palette.muted)
                                }
                                .padding(.vertical, 9)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }
}

struct CycleDots: View {
    @EnvironmentObject var m: TimerModel
    var body: some View {
        let every = m.prefs.every
        let inCycle = m.round % every
        let done = (m.round > 0 && inCycle == 0 && m.mode == .long) ? every : inCycle
        let left = every - done
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(0..<every, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(i < done ? Palette.focus : Palette.surface2)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(i == done && m.mode == .focus ? Palette.focus : (i < done ? .clear : Palette.line), lineWidth: 1.2))
                        .frame(width: 24, height: 8)
                }
            }
            Text(m.mode == .long ? "Long break earned" : left == 1 ? "Long break after this one" : "\(left) until long break")
                .font(.system(size: 12.5)).foregroundStyle(Palette.muted)
        }
    }
}

struct StatsCard: View {
    @EnvironmentObject var m: TimerModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionLabel(text: "Today")
                Spacer()
                if m.isSample {
                    Text("SAMPLE WEEK")
                        .font(.system(size: 9.5, weight: .medium, design: .monospaced)).tracking(0.8)
                        .foregroundStyle(Palette.muted)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Palette.surface2))
                }
            }
            HStack(alignment: .top) {
                stat("\(m.todayMinutes)", "focus minutes")
                stat("\(m.todaySessions.count)", "sessions")
                stat("\(m.streak)", "day streak")
            }
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    SectionLabel(text: "Daily goal")
                    Spacer()
                    Text("\(min(m.todaySessions.count, m.prefs.goal)) / \(m.prefs.goal)")
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced)).foregroundStyle(Palette.muted)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Palette.surface2)
                        Capsule().fill(Palette.focus)
                            .frame(width: g.size.width * min(1, Double(m.todaySessions.count) / Double(m.prefs.goal)))
                    }
                }.frame(height: 6)
            }
            WeekChart(data: m.week)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.line, lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
    }

    func stat(_ v: String, _ l: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(v).font(.system(size: 28, weight: .medium, design: .rounded)).monospacedDigit().foregroundStyle(Palette.ink)
            Text(l).font(.system(size: 11.5)).foregroundStyle(Palette.muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WeekChart: View {
    var data: [(label: String, minutes: Int, today: Bool)]
    var body: some View {
        let mx = Double(max(60, data.map(\.minutes).max() ?? 0))
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(data.enumerated()), id: \.offset) { _, d in
                VStack(spacing: 4) {
                    Spacer(minLength: 0)
                    if d.minutes > 0 {
                        Text("\(d.minutes)").font(.system(size: 9.5, weight: .medium, design: .monospaced)).foregroundStyle(Palette.ink)
                    }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(d.today ? Palette.focus : Palette.focus.opacity(0.35))
                        .frame(width: 24, height: d.minutes > 0 ? max(3, Double(d.minutes) / mx * 80) : 0)
                    Text(d.label).font(.system(size: 9.5, design: .monospaced)).foregroundStyle(Palette.muted)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 118)
    }
}

// MARK: - Main window

struct MainView: View {
    @EnvironmentObject var m: TimerModel
    var scrollingRail = true
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()
            RadialGradient(colors: [m.accent.opacity(0.16), .clear], center: UnitPoint(x: 0.25, y: 0.35), startRadius: 0, endRadius: 620)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.9), value: m.mode)

            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    HStack(spacing: 9) {
                        BrandMark(accent: m.accent).frame(width: 22, height: 22)
                        Text("Pomelo").font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    ModePicker()
                    Spacer()
                    Button { m.prefs.keepOnTop.toggle() } label: { Image(systemName: m.prefs.keepOnTop ? "pin.fill" : "pin") }
                        .buttonStyle(RoundIconButton(size: 34)).help("Keep window on top")
                    Button { cycleAppearance() } label: { Image(systemName: appearanceIcon) }
                        .buttonStyle(RoundIconButton(size: 34)).help("Appearance: \(m.prefs.appearance.title)")
                    Button { openSettings() } label: { Image(systemName: "slider.horizontal.3") }
                        .buttonStyle(RoundIconButton(size: 34)).help("Settings (⌘,)")
                }
                .padding(.leading, 70) // clear the traffic lights

                HStack(alignment: .top, spacing: 40) {
                    VStack(spacing: 20) {
                        Dial().frame(maxWidth: 470, maxHeight: 470)
                        Controls()
                    }
                    .frame(maxWidth: .infinity)
                    Group { if scrollingRail { Rail() } else { RailContent() } }.frame(width: 330)
                }
            }
            .padding(.horizontal, 26).padding(.top, 12).padding(.bottom, 24)

            if let b = m.banner {
                VStack { Spacer()
                    Text(b).font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.bg)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.ink))
                        .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: m.banner)
        .foregroundStyle(Palette.ink)
        .frame(minWidth: 900, minHeight: 640)
        .onAppear { DispatchQueue.main.async { m.applyWindowPrefs() } }
    }

    var appearanceIcon: String {
        switch m.prefs.appearance { case .system: "circle.lefthalf.filled"; case .light: "sun.max"; case .dark: "moon" }
    }
    func cycleAppearance() {
        let all = AppearancePref.allCases
        m.prefs.appearance = all[(all.firstIndex(of: m.prefs.appearance)! + 1) % all.count]
    }
}

struct BrandMark: View {
    var accent: Color
    var body: some View {
        ZStack {
            Circle().stroke(Palette.ink, lineWidth: 1.8)
            PieWedge(fraction: 0.2).fill(accent).padding(2.5)
            Circle().fill(Palette.ink).frame(width: 4, height: 4)
        }
    }
}

struct PieWedge: Shape {
    var fraction: Double
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        p.move(to: c)
        p.addArc(center: c, radius: r.width / 2, startAngle: .degrees(-90), endAngle: .degrees(-90 + fraction * 360), clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - Menu bar panel

struct MenuPanel: View {
    @EnvironmentObject var m: TimerModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Label(m.mode.title, systemImage: m.mode.symbol)
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(m.accent)
                Spacer()
                CycleMini()
            }
            Dial(compact: true).frame(width: 200, height: 200)
            if !m.intent.isEmpty && m.mode == .focus {
                Text(m.intent).font(.system(size: 12)).foregroundStyle(Palette.muted).lineLimit(1)
            }
            Controls(compact: true)
            Picker("Sound", selection: $m.prefs.ambient) {
                ForEach(Ambient.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.menu)
            .font(.system(size: 12))
            .onChange(of: m.prefs.ambient) { m.ambientChanged() }
            Divider()
            HStack {
                Button("Open Pomelo") {
                    NSApp.setActivationPolicy(.regular)
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(Palette.muted)
        }
        .padding(16)
        .frame(width: 290)
        .background(Palette.bg)
        .foregroundStyle(Palette.ink)
    }
}

struct CycleMini: View {
    @EnvironmentObject var m: TimerModel
    var body: some View {
        let every = m.prefs.every, inCycle = m.round % every
        let done = (m.round > 0 && inCycle == 0 && m.mode == .long) ? every : inCycle
        HStack(spacing: 4) {
            ForEach(0..<every, id: \.self) { i in
                Circle().fill(i < done ? Palette.focus : Palette.surface2).frame(width: 7, height: 7)
            }
        }
    }
}

struct MenuBarLabel: View {
    @EnvironmentObject var m: TimerModel
    var body: some View {
        if m.status != .idle && m.prefs.menuBarCountdown {
            HStack(spacing: 4) {
                Image(systemName: m.status == .paused ? "pause.circle" : m.mode.symbol)
                Text(m.display).monospacedDigit()
            }
        } else {
            Image(systemName: "timer")
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var m: TimerModel
    @State private var confirmClear = false

    var body: some View {
        Form {
            Section("Durations") {
                Stepper("Focus: \(m.prefs.focus) min", value: $m.prefs.focus, in: 1...60)
                Stepper("Short break: \(m.prefs.short) min", value: $m.prefs.short, in: 1...30)
                Stepper("Long break: \(m.prefs.long) min", value: $m.prefs.long, in: 1...60)
                Stepper("Long break every \(m.prefs.every) sessions", value: $m.prefs.every, in: 2...8)
                Stepper("Daily goal: \(m.prefs.goal) sessions", value: $m.prefs.goal, in: 1...16)
            }
            Section("Flow") {
                Toggle("Start breaks automatically", isOn: $m.prefs.autoBreak)
                Toggle("Start focus after breaks", isOn: $m.prefs.autoFocus)
                Toggle(isOn: $m.prefs.overflow) {
                    Text("Overflow")
                    Text("Keep counting past zero until you finish")
                }
            }
            Section("Sound") {
                Toggle("Chime when a session ends", isOn: $m.prefs.sound)
                Picker("Ambient during focus", selection: $m.prefs.ambient) {
                    ForEach(Ambient.allCases) { Text($0.title).tag($0) }
                }
                if m.prefs.ambient == .file {
                    LabeledContent("File", value: m.prefs.ambientFile.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "None selected")
                    Button("Choose audio file") { chooseAudioFile() }
                    Text("The file loops during focus and must remain in its chosen location.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Appearance") {
                Picker("Theme", selection: $m.prefs.appearance) {
                    ForEach(AppearancePref.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.segmented)
                Toggle("Show countdown in menu bar", isOn: $m.prefs.menuBarCountdown)
                Toggle("Keep window on top", isOn: $m.prefs.keepOnTop)
            }
            Section("Data") {
                Button(confirmClear ? "Click again to clear history" : "Clear history", role: .destructive) {
                    if confirmClear { m.clearHistory(); confirmClear = false }
                    else { confirmClear = true; DispatchQueue.main.asyncAfter(deadline: .now() + 3) { confirmClear = false } }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 600)
        .onChange(of: m.prefs.focus) { m.prefsChangedDuration() }
        .onChange(of: m.prefs.short) { m.prefsChangedDuration() }
        .onChange(of: m.prefs.long) { m.prefsChangedDuration() }
        .onChange(of: m.prefs.ambient) { m.ambientChanged() }
        .onChange(of: m.prefs.ambientFile) { m.ambientChanged() }
    }

    private func chooseAudioFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if (try? AVAudioPlayer(contentsOf: url)) != nil {
            m.prefs.ambientFile = url.path
        } else {
            let a = NSAlert()
            a.messageText = "Cannot open audio file"
            a.informativeText = "Pomelo could not open that file. Try a WAV, MP3, or M4A file."
            a.runModal()
        }
    }
}
