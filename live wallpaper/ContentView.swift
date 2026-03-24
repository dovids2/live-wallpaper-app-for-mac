import SwiftUI

struct SettingsView: View {
    @AppStorage("wallpaperOpacity") private var opacity: Double = 1.0
    
    var onClose: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Wallpaper Settings")
                .font(.headline)
            
            VStack(alignment: .leading) {
                Text("Opacity: \(Int(opacity * 100))%")
                Slider(value: $opacity, in: 0...1)
            }
            
            Button("Close") {
                onClose()
            }
        }
        .padding()
        .frame(width: 300)
    }
}

#Preview {
    SettingsView()
}
