import Foundation

/// AI-powered battery health prediction model
final class HealthPredictionModel {
    static let shared = HealthPredictionModel()
    
    private init() {}
    
    // MARK: - Health Trend Prediction
    
    struct HealthTrend {
        let predictedMonthsUntil80Percent: Int?
        let monthlyDegradationRate: Double
        let trend: Trend
        let confidence: Double
        
        enum Trend {
            case improving
            case stable
            case degrading
            case unknown
        }
    }
    
    /// Predict when battery health will fall below 80%
    func predictHealthDegradation(
        currentHealth: Int,
        cycleCount: Int,
        sessions: [ChargingSession],
        batteryModel: String = "Unknown Mac"
    ) -> HealthTrend {
        guard !sessions.isEmpty else {
            return HealthTrend(
                predictedMonthsUntil80Percent: nil,
                monthlyDegradationRate: 0,
                trend: .unknown,
                confidence: 0
            )
        }
        
        // Analyze health history from sessions
        let healthHistory = extractHealthHistory(sessions: sessions)
        
        guard healthHistory.count >= 2 else {
            // Not enough data - use average degradation estimates
            let avgMonthlyRate = estimateAverageDegradationRate(model: batteryModel)
            return HealthTrend(
                predictedMonthsUntil80Percent: calculateMonthsUntilTarget(
                    currentHealth: currentHealth,
                    targetHealth: 80,
                    monthlyRate: avgMonthlyRate
                ),
                monthlyDegradationRate: avgMonthlyRate,
                trend: .unknown,
                confidence: 0.3
            )
        }
        
        // Calculate actual degradation rate from history
        let monthlyRate = calculateDegradationRate(from: healthHistory)
        let trend = determineTrend(healthHistory: healthHistory)
        let confidence = min(0.9, Double(healthHistory.count) / 10.0 + 0.2) // More data = higher confidence
        
        let monthsUntil80 = calculateMonthsUntilTarget(
            currentHealth: currentHealth,
            targetHealth: 80,
            monthlyRate: monthlyRate
        )
        
        return HealthTrend(
            predictedMonthsUntil80Percent: monthsUntil80,
            monthlyDegradationRate: monthlyRate,
            trend: trend,
            confidence: confidence
        )
    }
    
    // MARK: - Health Comparison
    
    /// Compare user's battery health to average for their Mac model
    func compareToAverage(currentHealth: Int, cycleCount: Int, batteryModel: String) -> (comparison: String, percentile: Int) {
        // Estimated average health for given cycle count and model
        // These are rough estimates based on typical lithium-ion battery behavior
        let avgHealthForCycles = estimateAverageHealthForCycles(cycleCount: cycleCount, model: batteryModel)
        
        let diff = currentHealth - avgHealthForCycles
        
        if diff > 5 {
            return ("Your battery is performing better than average for this model.", 75)
        } else if diff < -5 {
            return ("Your battery health is degrading faster than average. Consider reviewing your charging habits.", 25)
        } else {
            return ("Your battery health is within normal range for this model.", 50)
        }
    }
    
    // MARK: - Private Helpers
    
    private func extractHealthHistory(sessions: [ChargingSession]) -> [(date: Date, health: Int)] {
        // Group sessions by month and estimate health from charging patterns
        // This is simplified - real implementation would track health over time
        var history: [(Date, Int)] = []
        
        // Sort sessions by date
        let sortedSessions = sessions.sorted { $0.startedAt < $1.startedAt }
        
        // Estimate health based on session count and duration
        // More charging sessions and longer durations correlate with more wear
        var estimatedHealth = 100
        
        for (index, session) in sortedSessions.enumerated() {
            // Rough estimate: each significant charging event reduces health slightly
            let duration = session.duration ?? 0
            if duration > 3600 { // More than 1 hour
                estimatedHealth = max(0, estimatedHealth - 1)
            }
            
            // Add monthly data points
            if index == 0 || Calendar.current.component(.month, from: sortedSessions[index-1].startedAt) != Calendar.current.component(.month, from: session.startedAt) {
                history.append((session.startedAt, estimatedHealth))
            }
        }
        
        return history
    }
    
    private func calculateDegradationRate(from history: [(date: Date, health: Int)]) -> Double {
        guard history.count >= 2 else { return 0.5 } // Default ~0.5% per month
        
        let first = history.first!
        let last = history.last!
        
        let monthsDiff = Calendar.current.dateComponents([.month], from: first.date, to: last.date).month ?? 1
        let months = max(1, monthsDiff)
        
        let healthDiff = first.health - last.health
        return Double(healthDiff) / Double(months)
    }
    
    private func determineTrend(healthHistory: [(date: Date, health: Int)]) -> HealthTrend.Trend {
        guard healthHistory.count >= 3 else { return .unknown }
        
        // Simple linear regression to determine trend
        let n = Double(healthHistory.count)
        var sumX: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumX2: Double = 0
        
        for (i, point) in healthHistory.enumerated() {
            let x = Double(i)
            let y = Double(point.health)
            sumX += x
            sumY += y
            sumXY += x * y
            sumX2 += x * x
        }
        
        let denominator = n * sumX2 - sumX * sumX
        guard abs(denominator) > 0.001 else { return .stable }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        
        if slope > 0.1 {
            return .improving
        } else if slope < -0.1 {
            return .degrading
        } else {
            return .stable
        }
    }
    
    private func calculateMonthsUntilTarget(currentHealth: Int, targetHealth: Int, monthlyRate: Double) -> Int? {
        guard monthlyRate > 0 else { return nil }
        guard currentHealth > targetHealth else { return 0 }
        
        let diff = currentHealth - targetHealth
        return Int(ceil(Double(diff) / monthlyRate))
    }
    
    private func estimateAverageDegradationRate(model: String) -> Double {
        // Typical lithium-ion battery: ~1-2% per month with regular use
        // Conservative estimate
        return 1.0
    }
    
    private func estimateAverageHealthForCycles(cycleCount: Int, model: String) -> Int {
        // Rough estimate: ~0.1% health loss per cycle for first 500 cycles
        // Then increasing rate after that
        if cycleCount < 100 {
            return 100 - (cycleCount / 10)
        } else if cycleCount < 500 {
            return 90 - ((cycleCount - 100) / 50)
        } else {
            return 82 - ((cycleCount - 500) / 100)
        }
    }
}
