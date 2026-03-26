import Foundation
import StoreKit

/// R16: Subscription management with StoreKit 2
@available(macOS 13.0, *)
public final class VoltSubscriptionManager: ObservableObject {
    
    public static let shared = VoltSubscriptionManager()
    
    @Published public private(set) var currentSubscription: Subscription?
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var isLoading = false
    
    private let proMonthlyID = "com.volt.macos.pro.monthly"
    private let proYearlyID = "com.volt.macos.pro.yearly"
    private let householdMonthlyID = "com.volt.macos.household.monthly"
    private let householdYearlyID = "com.volt.macos.household.yearly"
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
    }
    
    public func loadProducts() async {
        isLoading = true
        do {
            let productIDs = [proMonthlyID, proYearlyID, householdMonthlyID, householdYearlyID]
            products = try await Product.products(for: productIDs).sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
        isLoading = false
    }
    
    public func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    public func updateSubscriptionStatus() async {
        var finalSub = Subscription(tier: .free, status: .active)
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == proMonthlyID || transaction.productID == proYearlyID {
                    finalSub = Subscription(
                        tier: .pro,
                        status: transaction.revocationDate == nil ? .active : .expired,
                        expiresAt: transaction.expirationDate,
                        transactionId: String(transaction.id)
                    )
                } else if transaction.productID == householdMonthlyID || transaction.productID == householdYearlyID {
                    finalSub = Subscription(
                        tier: .household,
                        status: transaction.revocationDate == nil ? .active : .expired,
                        expiresAt: transaction.expirationDate,
                        isFamilyShared: true,
                        transactionId: String(transaction.id)
                    )
                }
            } catch { continue }
        }
        
        await MainActor.run { self.currentSubscription = finalSub }
    }
    
    public func canAccessFeature(_ feature: VoltFeature) -> Bool {
        guard let sub = currentSubscription else { return false }
        switch feature {
        case .customModes: return sub.tier != .free
        case .mlPredictions: return sub.tier == .pro || sub.tier == .household || sub.tier == .enterprise
        case .energyCost: return sub.tier == .pro || sub.tier == .household || sub.tier == .enterprise
        case .advancedWidgets: return sub.tier == .pro || sub.tier == .household || sub.tier == .enterprise
        case .householdMacs: return sub.tier == .household || sub.tier == .enterprise
        case .teamFleet: return sub.tier == .enterprise
        case .sso: return sub.tier == .enterprise
        case .mdm: return sub.tier == .enterprise
        }
    }
    
    public func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    await self?.updateSubscriptionStatus()
                    if let t = transaction { await t.finish() }
                } catch { continue }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw VoltSubscriptionError.failedVerification
        case .verified(let safe): return safe
        }
    }
}

public enum VoltFeature {
    case customModes, mlPredictions, energyCost, advancedWidgets, householdMacs, teamFleet, sso, mdm
}

public enum VoltSubscriptionError: Error {
    case failedVerification
}
