import SwiftUI
import AppKit
import AVFoundation

class WallpaperWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)))
        
        // Added .fullScreenAuxiliary to keep it visible during full-screen transitions
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone, .fullScreenAuxiliary]
        
        self.ignoresMouseEvents = true
        self.canHide = false
        self.sharingType = .none
        self.isReleasedWhenClosed = false
        
        // Disable any window animations to prevent glitches
        self.animationBehavior = .none
    }
}

struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer
    
    class PlayerView: NSView {
        let playerLayer = AVPlayerLayer()
        
        init(player: AVPlayer) {
            super.init(frame: .zero)
            self.wantsLayer = true
            
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspectFill
            
            // Set as the primary layer for better performance and stability
            self.layer = playerLayer
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    func makeNSView(context: Context) -> PlayerView {
        return PlayerView(player: player)
    }
    
    func updateNSView(_ nsView: PlayerView, context: Context) {
        nsView.playerLayer.player = player
    }
}
