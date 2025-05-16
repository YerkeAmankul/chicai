import Foundation
import StoreKit

@MainActor
class StartupManager: ObservableObject {
    @Published var isReady = false

    func initialize() async {
        await updatePurchasedProducts()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isReady = true
        }
    }

    private func updatePurchasedProducts() async {
        var purchasedIDs = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                purchasedIDs.insert(transaction.productID)
            }
        }
        IAPManager.shared.isSubscribed = !purchasedIDs.isEmpty
    }
}
