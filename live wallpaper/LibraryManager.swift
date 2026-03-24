import Foundation
import AppKit
import Combine

struct WallpaperItem: Identifiable, Hashable {
    let id: UUID = UUID()
    let url: URL
    let name: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: WallpaperItem, rhs: WallpaperItem) -> Bool {
        lhs.url == rhs.url
    }
}

class LibraryManager: ObservableObject {
    @Published var wallpapers: [WallpaperItem] = []
    
    private let fileManager = FileManager.default
    private let libraryURL: URL
    
    init() {
        // Create library folder in Application Support
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        libraryURL = appSupport.appendingPathComponent("com.livewallpaper.app/Library", isDirectory: true)
        
        try? fileManager.createDirectory(at: libraryURL, withIntermediateDirectories: true)
        
        refreshLibrary()
    }
    
    func refreshLibrary() {
        do {
            let files = try fileManager.contentsOfDirectory(at: libraryURL, includingPropertiesForKeys: nil)
            wallpapers = files.filter { url in
                let ext = url.pathExtension.lowercased()
                return ["mp4", "mov", "m4v"].contains(ext)
            }.map { url in
                WallpaperItem(url: url, name: url.deletingPathExtension().lastPathComponent)
            }
        } catch {
            print("Error scanning library: \(error)")
        }
    }
    
    func importVideo(from sourceURL: URL) {
        let destinationURL = libraryURL.appendingPathComponent(sourceURL.lastPathComponent)
        
        // Handle security scope if needed
        let isSecured = sourceURL.startAccessingSecurityScopedResource()
        defer { if isSecured { sourceURL.stopAccessingSecurityScopedResource() } }
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            refreshLibrary()
        } catch {
            print("Error importing video: \(error)")
        }
    }
    
    func deleteWallpaper(_ item: WallpaperItem) {
        try? fileManager.removeItem(at: item.url)
        refreshLibrary()
    }
}
