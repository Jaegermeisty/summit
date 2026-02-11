import SwiftUI
import SwiftData
import UIKit

@main
struct summitApp: App {
    @StateObject private var clipboard = ClipboardStore()
    @StateObject private var purchaseManager = PurchaseManager()

    init() {
        let tableView = UITableView.appearance()
        tableView.separatorStyle = .none
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(ModelContainer.shared)
        .environmentObject(clipboard)
        .environmentObject(purchaseManager)
    }
}
