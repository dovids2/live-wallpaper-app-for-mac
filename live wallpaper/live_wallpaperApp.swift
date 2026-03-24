import SwiftUI
import UniformTypeIdentifiers
import ServiceManagement
import AppKit
import Combine

class SettingsManager: NSObject, ObservableObject, NSWindowDelegate {
    private var window: NSWindow?
    
    func show() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.center()
        newWindow.title = "Live Wallpaper Settings"
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        
        let view = SettingsView(onClose: { [weak self] in
            self?.close()
        })
        
        newWindow.contentView = NSHostingView(rootView: view)
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = newWindow
    }
    
    func close() {
        DispatchQueue.main.async {
            self.window?.contentView = nil
            self.window?.close()
            self.window = nil
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        // Handle the case where the user clicks the red X button or close() is called
        // Use a slight delay to ensure the window's close sequence has progressed enough
        // but not so much that we cause a double-release if close() was called manually.
        self.window?.contentView = nil
        self.window = nil
    }
}

@main
struct live_wallpaperApp: App {
    @StateObject private var wallpaperManager = WallpaperManager()
    @StateObject private var settingsManager = SettingsManager()
    
    @State private var startAtLogin: Bool = {
        return SMAppService.mainApp.status == .enabled
    }()
    
    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    var body: some Scene {
        MenuBarExtra("Live Wallpaper", systemImage: "desktopcomputer") {
            Button("Select Video...") {
                selectVideo()
            }
            Button("Settings...") {
                settingsManager.show()
            }
            Button("Stop") {
                wallpaperManager.stop()
            }
            Divider()
            Toggle("Start at Login", isOn: $startAtLogin)
                .onChange(of: startAtLogin) { oldValue, newValue in
                    toggleStartAtLogin(newValue)
                }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    func toggleStartAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to toggle start at login: \(error)")
        }
    }
    
    func selectVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .video, .quickTimeMovie]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                wallpaperManager.setVideo(url: url)
            }
        }
    }
}
