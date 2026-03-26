import Foundation
import ServiceManagement
import Combine

class AppDefaults: ObservableObject {
    @Published var startAtLogin: Bool {
        didSet {
            toggleStartAtLogin(startAtLogin)
        }
    }
    
    init() {
        self.startAtLogin = SMAppService.mainApp.status == .enabled
    }
    
    private func toggleStartAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("Failed to toggle start at login: \(error)")
        }
    }
}
