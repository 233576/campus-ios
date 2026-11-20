import SwiftUI

@main
struct CampusApp: App {
    @StateObject private var laundry = LaundryStore()
    @StateObject private var campusNet = CampusNetStore()
    @Environment(\.scenePhase) private var scenePhase

    /// 外观偏好只在这里落地：nil = 交给系统，light/dark = 强制。
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.defaultValue

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            CampusShell()
                .environmentObject(laundry)
                .environmentObject(campusNet)
                .preferredColorScheme(appearance.colorScheme)
                .onAppear {
                    laundry.restore()
                    campusNet.restore()
                }
                .onChange(of: scenePhase) { phase in
                    switch phase {
                    case .background:
                        campusNet.stopAuto()
                        laundry.stopClock()
                    case .active:
                        laundry.startClock()
                    default:
                        break
                    }
                }
        }
    }
}
