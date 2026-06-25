import SwiftUI
import SwiftData

@main
struct HaloApp: App {
    @AppStorage(SettingsKey.listenInBackground, store: .shared)
    private var listenInBackground: Bool = SettingsDefault.listenInBackground

    init() {
        SettingsDefault.register()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .task {
                    await NotificationService.shared.requestAuthorizationIfNeeded()
                }
                .task(id: listenInBackground) {
                    if listenInBackground {
                        await HaloListener.shared.enable()
                    } else {
                        HaloListener.shared.disable()
                    }
                }
        }
        .modelContainer(DataController.shared.container)
    }
}
