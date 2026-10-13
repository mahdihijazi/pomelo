import SwiftUI
import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ n: Notification) {
        let c = UNUserNotificationCenter.current()
        c.delegate = self
        c.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        MainActor.assumeIsolated { TimerModel.shared.applyWindowPrefs() }
        // Menu-bar-first: no Dock icon unless the main window is open.
        let nc = NotificationCenter.default
        nc.addObserver(forName: NSWindow.didMiniaturizeNotification, object: nil, queue: .main) { n in
            guard let w = n.object as? NSWindow, AppDelegate.isMain(w) else { return }
            w.deminiaturize(nil); w.orderOut(nil)
            NSApp.setActivationPolicy(.accessory)
        }
        nc.addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: .main) { n in
            guard let w = n.object as? NSWindow, AppDelegate.isMain(w) else { return }
            NSApp.setActivationPolicy(.accessory)
        }
        DispatchQueue.main.async {
            for w in NSApp.windows where AppDelegate.isMain(w) { w.orderOut(nil) }
            NSApp.setActivationPolicy(.accessory)
        }
    }
    static func isMain(_ w: NSWindow) -> Bool { w.identifier?.rawValue.hasPrefix("main") == true }
    func userNotificationCenter(_ c: UNUserNotificationCenter, willPresent n: UNNotification,
                                withCompletionHandler done: @escaping (UNNotificationPresentationOptions) -> Void) {
        done([.banner])
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { false }
}

@main
struct PomeloApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = TimerModel.shared

    var body: some Scene {
        Window("Pomelo", id: "main") {
            MainView().environmentObject(model)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Timer") {
                Button(model.primaryLabel) { model.primary() }.keyboardShortcut(.return, modifiers: .command)
                Button("Reset") { model.reset() }.keyboardShortcut("r", modifiers: .command)
                Button("Skip") { model.skip() }.keyboardShortcut(.rightArrow, modifiers: .command)
                Divider()
                ForEach(Array(Mode.allCases.enumerated()), id: \.element) { i, mode in
                    Button(mode.title) { model.select(mode) }.keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: .command)
                }
                Divider()
                Toggle("Keep Window on Top", isOn: $model.prefs.keepOnTop).keyboardShortcut("t", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra {
            MenuPanel().environmentObject(model)
        } label: {
            MenuBarLabel().environmentObject(model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView().environmentObject(model)
        }
    }
}
