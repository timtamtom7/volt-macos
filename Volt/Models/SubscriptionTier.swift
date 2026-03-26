import Foundation

/// R16: Subscription tier for Volt
public enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case household = "household"
    case enterprise = "enterprise"
    
    public var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Volt Pro"
        case .household: return "Volt Household"
        case .enterprise: return "Volt Enterprise"
        }
    }
    
    public var monthlyPrice: Decimal? {
        switch self {
        case .free: return nil
        case .pro: return 1.99
        case .household: return 3.99
        case .enterprise: return nil
        }
    }
    
    public var yearlyPrice: Decimal? {
        switch self {
        case .free: return nil
        case .pro: return 12.99
        case .household: return 29.99
        case .enterprise: return nil
        }
    }
    
    public var maxMacs: Int {
        switch self {
        case .free: return 1
        case .pro: return 1
        case .household: return 5
        case .enterprise: return Int.max
        }
    }
    
    public var supportsCustomModes: Bool { self != .free }
    public var supportsMLPredictions: Bool { self == .pro || self == .household || self == .enterprise }
    public var supportsEnergyCost: Bool { self == .pro || self == .household || self == .enterprise }
    public var supportsAdvancedWidgets: Bool { self == .pro || self == .household || self == .enterprise }
    public var supportsShortcuts: Bool { self == .pro || self == .household || self == .enterprise }
    
    public var trialDays: Int {
        switch self {
        case .free: return 0
        case .pro, .household: return 14
        case .enterprise: return 30
        }
    }
}

public struct Subscription: Codable {
    public let tier: SubscriptionTier
    public let status: SubscriptionStatus
    public let expiresAt: Date?
    public let trialEndsAt: Date?
    public let isFamilyShared: Bool
    public let transactionId: String?
    
    public init(
        tier: SubscriptionTier,
        status: SubscriptionStatus,
        expiresAt: Date? = nil,
        trialEndsAt: Date? = nil,
        isFamilyShared: Bool = false,
        transactionId: String? = nil
    ) {
        self.tier = tier
        self.status = status
        self.expiresAt = expiresAt
        self.trialEndsAt = trialEndsAt
        self.isFamilyShared = isFamilyShared
        self.transactionId = transactionId
    }
    
    public var isActive: Bool { status == .active || status == .inTrial }
}

public enum SubscriptionStatus: String, Codable {
    case active, inTrial, expired, cancelled
}
