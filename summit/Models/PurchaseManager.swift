//
//  PurchaseManager.swift
//  Summit
//
//  Created on 2026-02-09
//

import Foundation
import Combine
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var isPro: Bool = false
    @Published private(set) var product: Product?
    @Published private(set) var lastErrorMessage: String?

    // TODO: Replace with your real App Store Connect Product ID.
    private let productId = "com.mathias.summit"
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [productId])
            product = products.first
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func purchase() async {
        if product == nil {
            await loadProducts()
        }
        guard let product else { return }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await handleTransaction(transaction)
                } else {
                    lastErrorMessage = "Purchase verification failed."
                }
            case .pending:
                break
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func refreshEntitlements() async {
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == productId, transaction.revocationDate == nil {
                hasEntitlement = true
            }
        }
        isPro = hasEntitlement
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await handleTransaction(transaction)
            }
        }
    }

    private func handleTransaction(_ transaction: Transaction) async {
        guard transaction.productID == productId else { return }
        if transaction.revocationDate == nil {
            isPro = true
        } else {
            await refreshEntitlements()
        }
        await transaction.finish()
    }
}
