import SwiftUI

struct RecommendationsView: View {
    @EnvironmentObject var voltStore: VoltStore
    @Binding var isPresented: Bool

    private var recommendations: [ChargingRecommendation] {
        analyzeChargingPatterns()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Smart Recommendations")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            if recommendations.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(recommendations) { rec in
                            recommendationCard(rec)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(width: 440, height: 480)
        .background(Theme.background)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundColor(Theme.accentGreen)

            Text("Great charging habits!")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Text("Your charging patterns look optimal. Keep up the good work!")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func recommendationCard(_ rec: ChargingRecommendation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: rec.type.icon)
                .font(.system(size: 16))
                .foregroundColor(rec.type.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(rec.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                Text(rec.description)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)

                if let action = rec.actionText {
                    Text(action)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.primaryBlue)
                        .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(rec.type.backgroundColor.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(rec.type.borderColor, lineWidth: 1)
        )
    }

    private func analyzeChargingPatterns() -> [ChargingRecommendation] {
        var recommendations: [ChargingRecommendation] = []
        let sessions = voltStore.recentSessions
        let info = voltStore.currentCharge

        // Check battery health
        if info.healthPercent < 80 {
            recommendations.append(ChargingRecommendation(
                type: .warning,
                title: "Battery Health Below Optimal",
                description: "Your battery health is at \(info.healthPercent)%. Consider optimizing your charging habits to preserve battery longevity.",
                actionText: "Avoid keeping your Mac plugged in at 100% for extended periods"
            ))
        }

        // Check for overnight charging
        let overnightCharging = sessions.filter { session in
            guard let duration = session.duration else { return false }
            return duration > 480 // More than 8 hours
        }
        if overnightCharging.count > 3 {
            recommendations.append(ChargingRecommendation(
                type: .info,
                title: "Frequent Long Charging Sessions",
                description: "You've had \(overnightCharging.count) charging sessions over 8 hours recently. Consider unplugging once you reach 80%.",
                actionText: nil
            ))
        }

        // Check for frequent top-ups
        let shortSessions = sessions.filter { session in
            guard let duration = session.duration else { return false }
            let chargeAdded = (session.endCharge ?? session.startCharge) - session.startCharge
            return duration < 30 && chargeAdded < 20
        }
        if shortSessions.count > 5 {
            recommendations.append(ChargingRecommendation(
                type: .info,
                title: "Many Short Charging Sessions",
                description: "You've had \(shortSessions.count) short charging sessions. Frequent partial charges are actually better for battery health than deep cycles.",
                actionText: nil
            ))
        }

        // Check temperature
        if info.temperature > 35 {
            recommendations.append(ChargingRecommendation(
                type: .warning,
                title: "Elevated Temperature",
                description: "Your battery is running at \(String(format: "%.1f", info.temperature))°C. High temperatures can degrade battery health over time.",
                actionText: "Ensure adequate ventilation and avoid using your Mac on soft surfaces"
            ))
        }

        // Check cycle count vs health
        if info.cycleCount > 200 && info.healthPercent > 85 {
            recommendations.append(ChargingRecommendation(
                type: .success,
                title: "Excellent Battery Condition",
                description: "With \(info.cycleCount) cycles, your battery still maintains \(info.healthPercent)% health. Your charging habits are excellent.",
                actionText: nil
            ))
        }

        // Check if always at 100%
        let alwaysFull = sessions.filter { ($0.endCharge ?? 0) >= 95 }
        if alwaysFull.count > sessions.count / 2 && sessions.count > 5 {
            recommendations.append(ChargingRecommendation(
                type: .info,
                title: "Consider Reducing Charge Limit",
                description: "Most of your sessions charge to 100%. If you're typically near a power outlet, consider limiting charge to 80% for better long-term battery health.",
                actionText: "Enable the 80% charge limit in Settings"
            ))
        }

        // Check for deep discharges
        let deepDischarges = sessions.filter { $0.startCharge < 20 }
        if deepDischarges.count > 2 {
            recommendations.append(ChargingRecommendation(
                type: .info,
                title: "Deep Discharges Detected",
                description: "You've had \(deepDischarges.count) sessions starting below 20%. While occasional deep discharges are fine, try to charge before reaching critically low levels.",
                actionText: nil
            ))
        }

        return recommendations
    }
}

struct ChargingRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let actionText: String?
}

enum RecommendationType {
    case success
    case info
    case warning

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return Theme.accentGreen
        case .info: return Theme.primaryBlue
        case .warning: return Theme.accentOrange
        }
    }

    var backgroundColor: Color {
        switch self {
        case .success: return Theme.accentGreen
        case .info: return Theme.primaryBlue
        case .warning: return Theme.accentOrange
        }
    }

    var borderColor: Color {
        color.opacity(0.3)
    }
}
