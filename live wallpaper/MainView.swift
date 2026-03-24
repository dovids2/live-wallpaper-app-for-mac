import SwiftUI
import AVFoundation

struct LibraryItemView: View {
    let item: WallpaperItem
    let isSelected: Bool
    
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    
    var body: some View {
        VStack {
            ZStack {
                if let player = player {
                    VideoPlayerView(player: player)
                        .frame(width: 160, height: 90)
                        .cornerRadius(8)
                } else {
                    Color.black
                        .frame(width: 160, height: 90)
                        .cornerRadius(8)
                }
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .frame(width: 160, height: 90)
                }
            }
            
            Text(item.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 160)
        }
        .onAppear {
            setupPreview()
        }
        .onDisappear {
            player?.pause()
            player = nil
            looper = nil
        }
    }
    
    private func setupPreview() {
        let playerItem = AVPlayerItem(url: item.url)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.isMuted = true
        looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        player = queuePlayer
        player?.play()
    }
}

struct MainView: View {
    @ObservedObject var library: LibraryManager
    @ObservedObject var wallpaperManager: WallpaperManager
    
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 160), spacing: 20)
    ]
    
    var body: some View {
        VStack {
            HStack {
                Text("Wallpaper Library")
                    .font(.largeTitle.bold())
                Spacer()
                Button(action: importNewVideo) {
                    Label("Import Video", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(library.wallpapers) { item in
                        LibraryItemView(
                            item: item,
                            isSelected: wallpaperManager.currentSourceURL == item.url
                        )
                        .onTapGesture {
                            wallpaperManager.setVideo(url: item.url)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                library.deleteWallpaper(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    private func importNewVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .video, .quickTimeMovie]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            library.importVideo(from: url)
        }
    }
}
