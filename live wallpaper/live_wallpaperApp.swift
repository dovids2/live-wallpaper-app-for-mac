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
    private let appDefaults: AppDefaults
    
    init(library: LibraryManager, wallpaperManager: WallpaperManager, appDefaults: AppDefaults) {
        self.library = library
        self.wallpaperManager = wallpaperManager
        self.appDefaults = appDefaults
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
        
        let view = MainView(library: library, wallpaperManager: wallpaperManager, appDefaults: appDefaults)
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
    @StateObject private var appDefaults = AppDefaults()
    @StateObject private var mainWindowManager: MainWindowManager
    
    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        
        let wm = WallpaperManager()
        let lm = LibraryManager()
        let ad = AppDefaults()
        let mwm = MainWindowManager(library: lm, wallpaperManager: wm, appDefaults: ad)
        
        _wallpaperManager = StateObject(wrappedValue: wm)
        _libraryManager = StateObject(wrappedValue: lm)
        _appDefaults = StateObject(wrappedValue: ad)
        _mainWindowManager = StateObject(wrappedValue: mwm)
        
        // Only show the library window on launch if no wallpaper is set
        if !wm.hasPersistedWallpaper {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                mwm.show()
            }
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
            Toggle("Start at Login", isOn: $appDefaults.startAtLogin)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
