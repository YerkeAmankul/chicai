import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var occuredError: IAPError?
    var onSubscriptionSuccess: (() -> Void)?
    
    static let monthlyID = "yerke.amankul.AIOutfitGeneration.subscription.monthly"
    static let yearlyID = "yerke.amankul.AIOutfitGeneration.subscription.yearly"
    
    init() {
        observeTransactionUpdates()
    }
    
    func fetchSubscription() {
        if !isSubscribed() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                Task {
                    await self.requestProducts()
                    await self.updatePurchasedProducts()
                }
            }
        }
    }

    func requestProducts() async {
        do {
            products = try await Product.products(for: [SubscriptionManager.monthlyID, SubscriptionManager.yearlyID]).sorted(by: { $0.displayPrice > $1.displayPrice })
        } catch {
            occuredError = IAPError(message: error.localizedDescription)
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    onSubscriptionSuccess?()
                    await updatePurchasedProducts()
                }
            case .userCancelled, .pending:
                break
            default:
                break
            }
        } catch {
            occuredError = IAPError(message: error.localizedDescription)
            print("Purchase failed: \(error)")
        }
    }
    
    func updatePurchasedProducts() async {
        var purchasedIDs = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                purchasedIDs.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchasedIDs
        IAPManager.shared.isSubscribed = isSubscribed()
    }
    
    func isSubscribed() -> Bool {
        return purchasedProductIDs.contains(SubscriptionManager.monthlyID) || purchasedProductIDs.contains(SubscriptionManager.yearlyID)
    }
    
    func restorePurchases() async {
        var restored = false
        
        for await result in Transaction.all {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                await transaction.finish()
                restored = true
                onSubscriptionSuccess?()
            }
        }
        
        await updatePurchasedProducts()
        
        if !restored {
            occuredError = IAPError(message: String(localized: "Нет покупок для восстановления"))
        }
    }
    
    struct IAPError: Identifiable {
        let id = UUID()
        let message: String
    }
    
    func observeTransactionUpdates() {
        Task.detached(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await MainActor.run {
                        self.purchasedProductIDs.insert(transaction.productID)
                    }
                }
            }
        }
    }
}
