import SwiftUI

@main
struct CampusApp: App {
    @StateObject private var laundry = LaundryStore()
    @StateObject private var campusNet = CampusNetStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            StoreShell()
                .environmentObject(laundry)
                .environmentObject(campusNet)
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
