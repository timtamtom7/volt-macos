import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    MeetVoltPage()
                        .tag(0)

                    ChargingInsightsPage()
                        .tag(1)

                    HealthThatMattersPage()
                        .tag(2)

                    YourePoweredUpPage(hasSeenOnboarding: $hasSeenOnboarding)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                PageIndicator(currentPage: currentPage, totalPages: 4)
                    .padding(.vertical, Theme.spacing24)

                ActionButton(
                    title: currentPage == 3 ? "Open Volt" : "Continue",
                    action: {
                        if currentPage < 3 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                currentPage += 1
                            }
                        } else {
                            hasSeenOnboarding = true
                        }
                    }
                )
                .padding(.horizontal, Theme.spacing40)
                .padding(.bottom, Theme.spacing32)
            }
        }
    }
}

// MARK: - Page 1: Meet Volt

struct MeetVoltPage: View {
    var body: some View {
        VStack(spacing: Theme.spacing24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "1E1E2E"))
                    .frame(width: 160, height: 160)

                Image(systemName: "battery.100.bolt")
                    .font(.system(size: 72, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00D4FF"), Color(hex: "34C759")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: Theme.spacing12) {
                Text("Your battery, in detail")
                    .font(.system(size: Theme.fontSizeLargeTitle, weight: .bold))
                    .foregroundColor(Theme.textPrimary)

                Text("Volt monitors your MacBook's battery health, tracks charge cycles, and helps you develop charging habits that last.")
                    .font(.system(size: Theme.fontSizeBody))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing32)
            }

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 2: Charging Insights

struct ChargingInsightsPage: View {
    var body: some View {
        VStack(spacing: Theme.spacing24) {
            Spacer()

            VStack(spacing: Theme.spacing16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: "00D4FF"))

                Text("See how you charge")
                    .font(.system(size: Theme.fontSizeLargeTitle, weight: .bold))
                    .foregroundColor(Theme.textPrimary)

                Text("Volt tracks your charging sessions automatically. You'll see patterns like peak charge times and how often you go from 20% to 80%.")
                    .font(.system(size: Theme.fontSizeBody))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing32)
            }

            VStack(alignment: .leading, spacing: Theme.spacing16) {
                FeatureRow(icon: "bolt.fill", iconColor: Color(hex: "00D4FF"), text: "Automatic session tracking — no setup needed")
                FeatureRow(icon: "square.grid.2x2", iconColor: Color(hex: "34C759"), text: "Charging heatmap shows your weekly patterns")
                FeatureRow(icon: "battery.75", iconColor: Color(hex: "34C759"), text: "Optimal charge range: 20%–80%")
            }
            .padding(.horizontal, Theme.spacing40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 3: Health That Matters

struct HealthThatMattersPage: View {
    var body: some View {
        VStack(spacing: Theme.spacing24) {
            Spacer()

            VStack(spacing: Theme.spacing16) {
                ZStack {
                    Circle()
                        .stroke(Color(hex: "34C759").opacity(0.3), lineWidth: 12)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: 0.87)
                        .stroke(Color(hex: "34C759"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("87%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        Text("Health")
                            .font(.system(size: Theme.fontSizeCaption))
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Text("Know your battery's age")
                    .font(.system(size: Theme.fontSizeLargeTitle, weight: .bold))
                    .foregroundColor(Theme.textPrimary)

                Text("Maximum capacity and cycle count tell the real story of your battery's health. Volt tracks both, with gentle alerts when something needs attention.")
                    .font(.system(size: Theme.fontSizeBody))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing32)
            }

            VStack(alignment: .leading, spacing: Theme.spacing12) {
                FeatureRow(icon: "chart.line.uptrend.xyaxis", iconColor: Color(hex: "34C759"), text: "Design vs. current capacity at a glance")
                FeatureRow(icon: "arrow.2.circlepath", iconColor: Color(hex: "00D4FF"), text: "Cycle count tracked over time")
                FeatureRow(icon: "bell.fill", iconColor: Color(hex: "FF9500"), text: "Get alerts when health dips below 80%")
            }
            .padding(.horizontal, Theme.spacing40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 4: You're Powered Up

struct YourePoweredUpPage: View {
    @Binding var hasSeenOnboarding: Bool

    var body: some View {
        VStack(spacing: Theme.spacing24) {
            Spacer()

            VStack(spacing: Theme.spacing16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "1E1E2E"))
                        .frame(width: 100, height: 100)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(hex: "00D4FF"))
                }

                Text("Volt is watching your battery")
                    .font(.system(size: Theme.fontSizeLargeTitle, weight: .bold))
                    .foregroundColor(Theme.textPrimary)

                Text("Look for Volt in your menu bar. Click to see current charge, health status, and your charging schedule.")
                    .font(.system(size: Theme.fontSizeBody))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing32)
            }

            VStack(alignment: .leading, spacing: Theme.spacing12) {
                FeatureRow(icon: "apple.logo", iconColor: Theme.textPrimary, text: "Find Volt in your menu bar — top right of your screen")
                FeatureRow(icon: "bolt.fill", iconColor: Color(hex: "00D4FF"), text: "Click to see real-time charge and health stats")
                FeatureRow(icon: "clock", iconColor: Color(hex: "00D4FF"), text: "Set a charging schedule in Settings")
            }
            .padding(.horizontal, Theme.spacing40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Supporting Views

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: Theme.spacing8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Theme.primaryBlue : Theme.textSecondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentPage)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let text: String

    var body: some View {
        HStack(spacing: Theme.spacing12) {
            Image(systemName: icon)
                .font(.system(size: Theme.fontSizeBody))
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(text)
                .font(.system(size: Theme.fontSizeSubheadline))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

struct ActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: Theme.fontSizeBody, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacing12)
                .background(
                    Capsule()
                        .fill(Theme.primaryBlue)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
