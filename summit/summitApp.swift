import SwiftUI
import SwiftData

@main
struct summitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(ModelContainer.shared)
    }
}
