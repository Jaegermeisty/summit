import SwiftUI
import SwiftData

@main
struct summitApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(ModelContainer.shared)
    }
}
