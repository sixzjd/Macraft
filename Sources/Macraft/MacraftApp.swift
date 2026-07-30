import SwiftUI
import AppKit

// MARK: - App Entry
@main
struct MacraftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var mojang = MojangService()
    @State private var launchService = GameLaunchService()
    @State private var installer = VersionInstaller()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(mojang)
                .environment(launchService)
                .environment(installer)
                .frame(minWidth: 1000, minHeight: 660)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1160, height: 740)
    }
}

// MARK: - App Delegate
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
