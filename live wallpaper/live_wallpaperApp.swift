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
        self.window?.contentView = nil
        self.window = nil
    }
}

class MainWindowManager: NSObject, ObservableObject, NSWindowDelegate {
    private var window: NSWindow?
    private let library: LibraryManager
    private let wallpaperManager: WallpaperManager
    
    init(library: LibraryManager, wallpaperManager: WallpaperManager) {
        self.library = library
        self.wallpaperManager = wallpaperManager
        super.init()
    }
    
    func show() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.center()
        newWindow.title = "Live Wallpaper Library"
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        
        let view = MainView(library: library, wallpaperManager: wallpaperManager)
        newWindow.contentView = NSHostingView(rootView: view)
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = newWindow
    }
    
    func windowWillClose(_ notification: Notification) {
        self.window?.contentView = nil
        self.window = nil
    }
}

@main
struct live_wallpaperApp: App {
    @StateObject private var wallpaperManager = WallpaperManager()
    @StateObject private var libraryManager = LibraryManager()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var mainWindowManager: MainWindowManager
    
    @State private var startAtLogin: Bool = {
        return SMAppService.mainApp.status == .enabled
    }()
    
    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        
        let wm = WallpaperManager()
        let lm = LibraryManager()
        let mwm = MainWindowManager(library: lm, wallpaperManager: wm)
        
        _wallpaperManager = StateObject(wrappedValue: wm)
        _libraryManager = StateObject(wrappedValue: lm)
        _mainWindowManager = StateObject(wrappedValue: mwm)
        
        // Show the library window on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            mwm.show()
        }
    }
    
    var body: some Scene {
        MenuBarExtra("Live Wallpaper", systemImage: "desktopcomputer") {
            Button("Library...") {
                mainWindowManager.show()
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
}
