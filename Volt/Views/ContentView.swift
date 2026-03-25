import SwiftUI

struct ContentView: View {
    @ObservedObject var voltStore: VoltStore

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Volt")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("Battery")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Divider()

            if voltStore.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                // Battery status
                BatteryStatusSection(info: voltStore.currentCharge)
                    .padding(.horizontal, 16)

                Divider()
                    .padding(.horizontal, 16)

                // Limit controls
                LimitSection(voltStore: voltStore)
                    .padding(.horizontal, 16)

                // Note
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                    Text("Hardware-level limiting requires additional permissions")
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 320, height: 280)
        .background(Theme.background)
        .onAppear {
            voltStore.startPolling(interval: 30)
        }
        .onDisappear {
            voltStore.stopPolling()
        }
    }
}

// MARK: - Battery Status Section

struct BatteryStatusSection: View {
    let info: BatteryInfo

    var body: some View {
        HStack(spacing: 24) {
            // Large charge display
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(info.charge)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(chargeColor)
                    Text("%")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: info.isCharging ? "bolt.fill" : "bolt")
                        .font(.system(size: 11))
                        .foregroundColor(info.isCharging ? Theme.accentGreen : Theme.textSecondary)
                    Text(statusText)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            // Battery details
            VStack(alignment: .trailing, spacing: 5) {
                DetailRow(label: "Health", value: "\(info.healthPercent)%")
                DetailRow(label: "Cycles", value: "\(info.cycleCount)")
                DetailRow(label: "Temp", value: String(format: "%.1f°C", info.temperature))
            }
        }
    }

    private var chargeColor: Color {
        if info.charge >= 90 { return Theme.accentGreen }
        if info.charge >= 50 { return Theme.textPrimary }
        if info.charge >= 20 { return Theme.accentOrange }
        return Theme.accentRed
    }

    private var statusText: String {
        if info.isCharging { return "Charging" }
        if info.isPluggedIn { return "Plugged In" }
        return "On Battery"
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
            Text(value)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

// MARK: - Limit Section

struct LimitSection: View {
    @ObservedObject var voltStore: VoltStore

    var body: some View {
        VStack(spacing: 12) {
            // Toggle + limit display
            HStack {
                Toggle("Charging Limit", isOn: $voltStore.limitEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)

                Spacer()

                Text(voltStore.limitStatusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(voltStore.limitEnabled ? Theme.accentGreen : Theme.textSecondary)
            }

            // Slider
            VStack(spacing: 6) {
                Slider(
                    value: Binding(
                        get: { Double(voltStore.chargeLimit) },
                        set: { voltStore.chargeLimit = Int($0) }
                    ),
                    in: 50...100,
                    step: 5
                )
                .disabled(!voltStore.limitEnabled)

                HStack {
                    Text("50%")
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("100%")
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textSecondary)
                }
            }

            // Apply button
            Button(action: {
                voltStore.refreshBatteryInfo()
            }) {
                Text("Refresh")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}
