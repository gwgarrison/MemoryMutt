import StoreKit

@Observable
@MainActor
class TipJarService {
    static let productIDs = [
        "com.manicmutt.modusmemori.tip.small",
        "com.manicmutt.modusmemori.tip.medium",
        "com.manicmutt.modusmemori.tip.large"
    ]

    var products: [Product] = []
    var purchaseState: PurchaseState = .idle
    var loadingState: LoadingState = .loading

    enum PurchaseState {
        case idle, purchasing, success, failed(Error)
    }

    enum LoadingState {
        case loading, loaded, failed
    }

    init() {
        Task { await loadProducts() }
    }

    func loadProducts() async {
        loadingState = .loading
        do {
            let fetched = try await Product.products(for: Self.productIDs)
            products = fetched.sorted { $0.price < $1.price }
            loadingState = fetched.isEmpty ? .failed : .loaded
        } catch {
            print("TipJarService: failed to load products: \(error)")
            loadingState = .failed
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
