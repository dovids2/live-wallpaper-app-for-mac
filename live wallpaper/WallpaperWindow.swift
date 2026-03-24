import SwiftUI
import AppKit
import AVFoundation

// Standalone PlayerView for better performance and to avoid SwiftUI overhead in the wallpaper itself
class PlayerView: NSView {
    let playerLayer = AVPlayerLayer()
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        self.wantsLayer = true
        
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.drawsAsynchronously = true
        
        // Use a black background to prevent white flashes
        playerLayer.backgroundColor = NSColor.black.cgColor
        
        self.layer = playerLayer
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class WallpaperWindow: NSPanel {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        
        // Use the desktop window level to stay behind everything
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)))
        
        // Ensure it stays on all spaces and isn't hidden by system animations
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone, .fullScreenAuxiliary]
        
        self.ignoresMouseEvents = true
        self.canHide = false
        self.hidesOnDeactivate = false
        self.sharingType = .none
        self.isReleasedWhenClosed = false
        
        // Disable window animations
        self.animationBehavior = .none
    }
    
    // Ensure it can never become the focus
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

// Keep VideoPlayerView for SwiftUI previews or settings if needed, but we'll use PlayerView directly for the wallpaper
struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> PlayerView {
        return PlayerView(player: player)
    }
    
    func updateNSView(_ nsView: PlayerView, context: Context) {
        nsView.playerLayer.player = player
    }
}
