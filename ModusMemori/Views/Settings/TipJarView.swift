import StoreKit
import SwiftUI

struct TipJarView: View {
    @State private var store = TipJarService()
    @Environment(\.dismiss) private var dismiss

    private let labels = [
        "com.manicmutt.modusmemori.tip.small": ("Cup of Coffee", "cup.and.saucer.fill"),
        "com.manicmutt.modusmemori.tip.medium": ("Slice of Pizza", "fork.knife"),
        "com.manicmutt.modusmemori.tip.large": ("Movie Ticket", "ticket.fill")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.pink)

                    Text("Support ModusMemori")
                        .font(.title2.bold())

                    Text("ModusMemori is free with no ads or subscriptions. If it's helped your studies, a tip means a lot!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 32)

                Divider()

                // Product list
                if store.products.isEmpty {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity)
                        .padding(48)
                } else {
                    VStack(spacing: 12) {
                        ForEach(store.products, id: \.id) { product in
                            TipRow(
                                product: product,
                                label: labels[product.id]?.0 ?? product.displayName,
                                icon: labels[product.id]?.1 ?? "gift.fill",
                                isPurchasing: {
                                    if case .purchasing = store.purchaseState { return true }
                                    return false
                                }()
                            ) {
                                Task { await store.purchase(product) }
                            }
                        }
                    }
                    .padding()
                }

                Spacer()
            }
            .navigationTitle("Tip Jar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: Binding(
                get: {
                    if case .success = store.purchaseState { return true }
                    return false
                },
                set: { if !$0 { store.purchaseState = .idle } }
            )) {
                ThankYouView { dismiss() }
            }
            .alert("Purchase Failed", isPresented: Binding(
                get: {
                    if case .failed = store.purchaseState { return true }
                    return false
                },
                set: { if !$0 { store.purchaseState = .idle } }
            )) {
                Button("OK") { store.purchaseState = .idle }
            } message: {
                if case .failed(let error) = store.purchaseState {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Tip Row

private struct TipRow: View {
    let product: Product
    let label: String
    let icon: String
    let isPurchasing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.pink)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(product.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isPurchasing {
                    ProgressView()
                } else {
                    Text(product.displayPrice)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.pink)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isPurchasing)
    }
}

// MARK: - Thank You View

private struct ThankYouView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 64))
                .foregroundStyle(.pink)

            Text("Thank You!")
                .font(.largeTitle.bold())

            Text("Your support helps keep ModusMemori free and growing. Happy studying!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                onDone()
            } label: {
                Text("Back to Studying")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.pink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)
            }

            Spacer()
                .frame(height: 16)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    TipJarView()
}
