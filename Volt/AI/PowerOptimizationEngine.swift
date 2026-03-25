import Foundation

/// AI-powered power optimization engine for Volt
final class PowerOptimizationEngine {
    static let shared = PowerOptimizationEngine()
    
    private init() {}
    
    // MARK: - Optimal Charge Limit Suggestion
    
    /// Analyze charging patterns and suggest optimal charge limit
    func suggestOptimalChargeLimit(sessions: [ChargingSession], currentHealth: Int) -> Int {
        guard !sessions.isEmpty else { return 80 }
        
        // Analyze typical usage patterns
        let avgChargeUsed = calculateAverageChargeUsed(sessions: sessions)
        let maxChargeNeeded = calculateMaxChargeNeeded(sessions: sessions)
        
        // If user regularly uses more than 80%, suggest higher limit
        if maxChargeNeeded >= 90 {
            return 100
        } else if maxChargeNeeded >= 80 {
            return 85
        } else if maxChargeNeeded >= 70 {
            return 80
        } else {
            return 75 // Conservative for battery longevity
        }
    }
    
    // MARK: - Charging Pattern Analysis
    
    /// Detect if user tends to overcharge (stay at 100% for long periods)
    func detectOverchargingPattern(sessions: [ChargingSession]) -> (isOvercharging: Bool, suggestion: String) {
        let long100Sessions = sessions.filter { session in
            guard session.endCharge == 100, let endedAt = session.endedAt else { return false }
            let duration = endedAt.timeIntervalSince(session.startedAt)
            return duration > 3600 * 2 // More than 2 hours at 100%
        }
        
        if long100Sessions.count >= 3 {
            return (true, "You often leave your Mac charging at 100% for extended periods. Consider unplugging when fully charged to reduce battery stress.")
        }
        
        return (false, "")
    }
    
    /// Detect if user frequently drains below 20%
    func detectDeepDischargePattern(sessions: [ChargingSession]) -> (isDeepDischarging: Bool, suggestion: String) {
        var lowDrainCount = 0
        var totalDrains = 0
        
        for session in sessions {
            if let endCharge = session.endCharge, endCharge < 20 {
                lowDrainCount += 1
            }
            totalDrains += 1
        }
        
        if totalDrains > 0 && (Double(lowDrainCount) / Double(totalDrains)) > 0.3 {
            return (true, "You frequently drain your battery below 20%. Keeping it above 20% can help extend battery lifespan.")
        }
        
        return (false, "")
    }
    
    // MARK: - Usage Pattern Learning
    
    /// Learn typical work hours for smart notifications
    func learnWorkPattern(sessions: [ChargingSession]) -> (startHour: Int, endHour: Int) {
        var hourCounts = [Int: Int]() // hour -> count of sessions starting in that hour
        
        for session in sessions {
            let hour = Calendar.current.component(.hour, from: session.startedAt)
            hourCounts[hour, default: 0] += 1
        }
        
        guard let mostCommonHour = hourCounts.max(by: { $0.value < $1.value })?.key else {
            return (9, 17) // Default work hours
        }
        
        // Assume 8-hour work day
        let startHour = mostCommonHour
        let endHour = (startHour + 8) % 24
        
        return (startHour, endHour)
    }
    
    /// Calculate average charge used between charging sessions
    private func calculateAverageChargeUsed(sessions: [ChargingSession]) -> Double {
        guard sessions.count >= 2 else { return 50.0 }
        
        var totalUsed: Double = 0
        var count = 0
        
        for i in 1..<sessions.count {
            let prevSession = sessions[i - 1]
            let currentSession = sessions[i]
            
            // Estimate discharge between sessions
            guard let endCharge = prevSession.endCharge else { continue }
            let startCharge = currentSession.startCharge
            let used = Double(endCharge - startCharge)
            if used > 0 && used < 100 {
                totalUsed += used
                count += 1
            }
        }
        
        return count > 0 ? totalUsed / Double(count) : 50.0
    }
    
    /// Calculate maximum charge needed based on usage patterns
    private func calculateMaxChargeNeeded(sessions: [ChargingSession]) -> Int {
        guard sessions.count >= 2 else { return 80 }
        
        var maxNeeded = 0
        
        for i in 1..<sessions.count {
            let prevSession = sessions[i - 1]
            let currentSession = sessions[i]
            
            // Estimate the minimum charge they needed
            guard let endCharge = prevSession.endCharge else { continue }
            let needed = endCharge - currentSession.startCharge
            if needed > maxNeeded && needed > 0 && needed <= 100 {
                maxNeeded = needed
            }
        }
        
        return maxNeeded == 0 ? 80 : maxNeeded
    }
    
    // MARK: - Optimization Score
    
    /// Calculate overall power optimization score (0-100)
    func calculateOptimizationScore(sessions: [ChargingSession], currentHealth: Int, chargeLimit: Int) -> (score: Int, factors: [String: Double]) {
        var factors: [String: Double] = [:]
        var weightedScore: Double = 0
        var weightTotal: Double = 0
        
        // Factor 1: Charge limit usage (30% weight)
        let limitScore: Double
        if chargeLimit <= 80 {
            limitScore = 100
        } else if chargeLimit <= 90 {
            limitScore = 80
        } else {
            limitScore = 50
        }
        factors["chargeLimitScore"] = limitScore
        weightedScore += limitScore * 0.30
        weightTotal += 0.30
        
        // Factor 2: Health score (30% weight)
        let healthScore = Double(currentHealth)
        factors["healthScore"] = healthScore
        weightedScore += healthScore * 0.30
        weightTotal += 0.30
        
        // Factor 3: Charging pattern score (25% weight)
        let overchargePattern = detectOverchargingPattern(sessions: sessions)
        let dischargePattern = detectDeepDischargePattern(sessions: sessions)
        let patternScore: Double
        if !overchargePattern.isOvercharging && !dischargePattern.isDeepDischarging {
            patternScore = 100
        } else if !overchargePattern.isOvercharging || !dischargePattern.isDeepDischarging {
            patternScore = 70
        } else {
            patternScore = 40
        }
        factors["patternScore"] = patternScore
        weightedScore += patternScore * 0.25
        weightTotal += 0.25
        
        // Factor 4: Temperature management (15% weight)
        // Note: ChargingSession doesn't store temperature, so we use a default good score
        // In production, this would use BatterySnapshot data
        let tempScore: Double = 85
        factors["temperatureScore"] = tempScore
        weightedScore += tempScore * 0.15
        weightTotal += 0.15
        
        // Calculate final score
        let finalScore = Int(weightedScore / weightTotal)
        return (max(0, min(100, finalScore)), factors)
    }
}
