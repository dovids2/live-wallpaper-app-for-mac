import SwiftUI
import AppKit
import AVFoundation
import Combine

class WallpaperManager: NSObject, ObservableObject {
    private var windows: [WallpaperWindow] = []
    private var players: [AVQueuePlayer] = []
    private var loopers: [AVPlayerLooper] = []
    private var cancellables = Set<AnyCancellable>()
    
    // Track the last screen configuration to avoid unnecessary re-creation
    private var lastScreenConfig: String = ""
    
    // The original source URL (user selected)
    private var sourceURL: URL?
    
    // The local copy used for playback
    private var localURL: URL?
    
    var currentSourceURL: URL? { sourceURL }

    override init() {
        super.init()
        
        if let savedData = UserDefaults.standard.data(forKey: "wallpaperBookmark") {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: savedData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                if url.startAccessingSecurityScopedResource() {
                    self.sourceURL = url
                    self.setupPlaybackFromSource(url: url)
                    url.stopAccessingSecurityScopedResource()
                }
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        }
        
        // Only observe opacity changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.applySettings()
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }

    func applySettings() {
        let opacity = UserDefaults.standard.double(forKey: "wallpaperOpacity")
        for window in windows {
            window.alphaValue = opacity
        }
    }

    @objc func screenParametersChanged() {
        // Only update if the screen configuration actually changed (resolution, number of screens)
        let currentConfig = NSScreen.screens.map { "\($0.frame)" }.joined(separator: "|")
        if currentConfig != lastScreenConfig {
            updateWindows()
        }
    }

    func setVideo(url: URL) {
        let isSecured = url.startAccessingSecurityScopedResource()
        defer {
            if isSecured {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        self.sourceURL = url
        
        do {
            let bookmark = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmark, forKey: "wallpaperBookmark")
        } catch {
            print("Failed to create bookmark: \(error)")
        }
        
        setupPlaybackFromSource(url: url)
    }
    
    private func setupPlaybackFromSource(url: URL) {
        let fileManager = FileManager.default
        guard let cachesFolder = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("Failed to find caches directory")
            return
        }
        
        let destinationURL = cachesFolder.appendingPathComponent("current_wallpaper.mov")
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: url, to: destinationURL)
            self.localURL = destinationURL
            
            // Force an update when a new video is set
            DispatchQueue.main.async { [weak self] in
                self?.lastScreenConfig = "" // Reset to force update
                self?.updateWindows()
            }
        } catch {
            print("Failed to copy video to caches: \(error)")
        }
    }

    func updateWindows() {
        // Record current config
        let currentConfig = NSScreen.screens.map { "\($0.frame)" }.joined(separator: "|")
        self.lastScreenConfig = currentConfig

        // Stop and clear in safe order
        for player in players {
            player.pause()
        }
        loopers.removeAll()
        players.removeAll()
        
        for window in windows {
            window.contentView = nil
            window.close()
        }
        windows.removeAll()

        guard let url = localURL else { return }

        for screen in NSScreen.screens {
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            let queuePlayer = AVQueuePlayer(playerItem: playerItem)
            let playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
            
            queuePlayer.isMuted = true
            
            players.append(queuePlayer)
            loopers.append(playerLooper)
            
            let window = WallpaperWindow(screen: screen)
            
            // Use PlayerView directly - much faster than NSHostingView
            let view = PlayerView(player: queuePlayer)
            window.contentView = view
            
            // orderBack(nil) puts it at the bottom of its level (.desktopWindow)
            window.orderBack(nil)
            windows.append(window)
            
            queuePlayer.play()
        }
        applySettings()
    }
    
    func stop() {
        UserDefaults.standard.removeObject(forKey: "wallpaperBookmark")
        sourceURL = nil
        localURL = nil
        lastScreenConfig = ""
        
        for player in players {
            player.pause()
        }
        loopers.removeAll()
        players.removeAll()
        
        for window in windows {
            window.contentView = nil
            window.close()
        }
        windows.removeAll()
    }
}
