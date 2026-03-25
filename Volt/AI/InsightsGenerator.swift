import Foundation

/// Generates AI-powered insights for battery and power management
final class VoltInsightsGenerator {
    static let shared = VoltInsightsGenerator()
    
    private let optimizer = PowerOptimizationEngine.shared
    private let healthPredictor = HealthPredictionModel.shared
    
    private init() {}
    
    // MARK: - Insight Types
    
    enum InsightType {
        case powerTip
        case healthAlert
        case chargingSuggestion
        case optimization
    }
    
    struct Insight: Identifiable {
        let id = UUID()
        let type: InsightType
        let title: String
        let body: String
        let severity: Severity
        let actionLabel: String?
        
        enum Severity {
            case info
            case tip
            case warning
            case critical
        }
    }
    
    // MARK: - Generate Insights
    
    func generateInsights(
        sessions: [ChargingSession],
        currentHealth: Int,
        cycleCount: Int,
        chargeLimit: Int,
        currentCharge: Int,
        isCharging: Bool,
        batteryModel: String
    ) -> [Insight] {
        var insights: [Insight] = []
        
        // Power optimization insights
        let optimizationInsights = generateOptimizationInsights(
            sessions: sessions,
            chargeLimit: chargeLimit
        )
        insights.append(contentsOf: optimizationInsights)
        
        // Health insights
        let healthInsights = generateHealthInsights(
            currentHealth: currentHealth,
            cycleCount: cycleCount,
            sessions: sessions,
            batteryModel: batteryModel
        )
        insights.append(contentsOf: healthInsights)
        
        // Charging insights
        let chargingInsights = generateChargingInsights(
            sessions: sessions,
            currentCharge: currentCharge,
            isCharging: isCharging,
            chargeLimit: chargeLimit
        )
        insights.append(contentsOf: chargingInsights)
        
        return insights
    }
    
    // MARK: - Optimization Insights
    
    private func generateOptimizationInsights(sessions: [ChargingSession], chargeLimit: Int) -> [Insight] {
        var insights: [Insight] = []
        
        let (score, _) = optimizer.calculateOptimizationScore(
            sessions: sessions,
            currentHealth: 80, // Will be overridden
            chargeLimit: chargeLimit
        )
        
        if score < 60 {
            insights.append(Insight(
                type: .optimization,
                title: "Power Optimization Available",
                body: "Your power settings could be optimized. Review your charging habits for better battery health.",
                severity: .tip,
                actionLabel: "View Suggestions"
            ))
        }
        
        let suggestedLimit = optimizer.suggestOptimalChargeLimit(sessions: sessions, currentHealth: 80)
        if abs(suggestedLimit - chargeLimit) >= 10 {
            insights.append(Insight(
                type: .optimization,
                title: "Charge Limit Suggestion",
                body: "Based on your usage patterns, we suggest a charge limit of \(suggestedLimit)% instead of \(chargeLimit)%.",
                severity: .tip,
                actionLabel: "Update Limit"
            ))
        }
        
        return insights
    }
    
    // MARK: - Health Insights
    
    private func generateHealthInsights(
        currentHealth: Int,
        cycleCount: Int,
        sessions: [ChargingSession],
        batteryModel: String
    ) -> [Insight] {
        var insights: [Insight] = []
        
        // Health trend prediction
        let trend = healthPredictor.predictHealthDegradation(
            currentHealth: currentHealth,
            cycleCount: cycleCount,
            sessions: sessions,
            batteryModel: batteryModel
        )
        
        if let monthsUntil80 = trend.predictedMonthsUntil80Percent {
            if monthsUntil80 > 24 {
                insights.append(Insight(
                    type: .healthAlert,
                    title: "Excellent Battery Health",
                    body: "At your current rate, your battery should maintain good health for over 2 more years.",
                    severity: .info,
                    actionLabel: nil
                ))
            } else if monthsUntil80 > 12 {
                insights.append(Insight(
                    type: .healthAlert,
                    title: "Healthy Battery Trend",
                    body: "Your battery is expected to stay above 80% health for about \(monthsUntil80) more months with current usage.",
                    severity: .info,
                    actionLabel: nil
                ))
            } else if monthsUntil80 > 0 {
                insights.append(Insight(
                    type: .healthAlert,
                    title: "Battery Health Declining",
                    body: "At your current rate, your battery may fall below 80% health in about \(monthsUntil80) months. Consider optimizing your charging habits.",
                    severity: .warning,
                    actionLabel: "View Tips"
                ))
            }
        }
        
        // Comparison to average
        let (comparison, _) = healthPredictor.compareToAverage(
            currentHealth: currentHealth,
            cycleCount: cycleCount,
            batteryModel: batteryModel
        )
        
        if !comparison.isEmpty {
            insights.append(Insight(
                type: .healthAlert,
                title: "Battery Comparison",
                body: comparison,
                severity: .info,
                actionLabel: nil
            ))
        }
        
        return insights
    }
    
    // MARK: - Charging Insights
    
    private func generateChargingInsights(
        sessions: [ChargingSession],
        currentCharge: Int,
        isCharging: Bool,
        chargeLimit: Int
    ) -> [Insight] {
        var insights: [Insight] = []
        
        // Overcharging alert
        let overchargePattern = optimizer.detectOverchargingPattern(sessions: sessions)
        if overchargePattern.isOvercharging {
            insights.append(Insight(
                type: .chargingSuggestion,
                title: "Charging Pattern Alert",
                body: overchargePattern.suggestion,
                severity: .tip,
                actionLabel: "Learn More"
            ))
        }
        
        // Deep discharge alert
        let dischargePattern = optimizer.detectDeepDischargePattern(sessions: sessions)
        if dischargePattern.isDeepDischarging {
            insights.append(Insight(
                type: .chargingSuggestion,
                title: "Deep Discharge Detected",
                body: dischargePattern.suggestion,
                severity: .tip,
                actionLabel: "View Tips"
            ))
        }
        
        // Smart notification suggestions
        if isCharging && currentCharge >= chargeLimit {
            insights.append(Insight(
                type: .chargingSuggestion,
                title: "Fully Charged",
                body: "Your Mac has reached \(currentCharge)%. Consider unplugging to preserve long-term battery health.",
                severity: .tip,
                actionLabel: nil
            ))
        }
        
        return insights
    }
}
