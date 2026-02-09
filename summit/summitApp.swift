import SwiftUI
import SwiftData

@main
struct summitApp: App {
    @StateObject private var clipboard = ClipboardStore()
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(ModelContainer.shared)
        .environmentObject(clipboard)
        .environmentObject(purchaseManager)
    }
}
