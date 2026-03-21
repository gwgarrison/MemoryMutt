import StoreKit
import SwiftUI

@MainActor
class TipJarService: ObservableObject {
    static let productIDs = [
        "com.manicmutt.modusmemori.tip.small",
        "com.manicmutt.modusmemori.tip.medium",
        "com.manicmutt.modusmemori.tip.large"
    ]

    @Published var products: [Product] = []
    @Published var purchaseState: PurchaseState = .idle

    enum PurchaseState {
        case idle, purchasing, success, failed(Error)
    }

    init() {
        Task { await loadProducts() }
    }

    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: Self.productIDs)
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            print("TipJarService: failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    purchaseState = .success
                case .unverified:
                    purchaseState = .failed(StoreError.unverified)
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error)
        }
    }
}

enum StoreError: LocalizedError {
    case unverified
    var errorDescription: String? { "Purchase could not be verified." }
}
