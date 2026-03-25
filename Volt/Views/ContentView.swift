import SwiftUI

struct ContentView: View {
    @ObservedObject var voltStore: VoltStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BatteryTabView(voltStore: voltStore)
                .tabItem {
                    Label("Battery", systemImage: "bolt.fill")
                }
                .tag(0)

            StatsHistoryView(voltStore: voltStore)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(1)

            ChargingScheduleView(voltStore: voltStore)
                .tabItem {
                    Label("Schedule", systemImage: "clock")
                }
                .tag(2)

            SettingsTabView(voltStore: voltStore)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .frame(width: 380, height: 420)
        .onAppear {
            voltStore.startPolling(interval: 30)
        }
        .onDisappear {
            voltStore.stopPolling()
        }
    }
}

// MARK: - Battery Tab

struct BatteryTabView: View {
    @ObservedObject var voltStore: VoltStore
    @State private var showHealthDetail = false
    @State private var showWidgetSheet = false
    @State private var showRecommendations = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Volt")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                HStack(spacing: 12) {
                    Button(action: { showRecommendations = true }) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.primaryBlue)
                    }
                    .buttonStyle(.plain)

                    Button(action: { showWidgetSheet = true }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.primaryBlue)
                    }
                    .buttonStyle(.plain)
                    Text("Battery")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Divider()

            if voltStore.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                BatteryStatusSection(info: voltStore.currentCharge)
                    .padding(.horizontal, 16)

                Divider()
                    .padding(.horizontal, 16)

                LimitSection(voltStore: voltStore)
                    .padding(.horizontal, 16)

                HealthSectionView(voltStore: voltStore)
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
        .background(Theme.background)
        .sheet(isPresented: $showHealthDetail) {
            HealthDetailView(isPresented: $showHealthDetail)
                .environmentObject(voltStore)
        }
        .sheet(isPresented: $showWidgetSheet) {
            WidgetView(isPresented: $showWidgetSheet)
                .environmentObject(voltStore)
        }
        .sheet(isPresented: $showRecommendations) {
            RecommendationsView(isPresented: $showRecommendations)
                .environmentObject(voltStore)
        }
    }
}

// MARK: - Health Section View

struct HealthSectionView: View {
    @ObservedObject var voltStore: VoltStore
    @State private var showHealthDetail = false

    var body: some View {
        let info = voltStore.currentCharge
        return VStack(spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(healthColor(for: info.healthPercent))
                Text("Battery Health")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button(action: { showHealthDetail = true }) {
                    Text("Details")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.primaryBlue)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text(info.healthDescription)
                    .font(.system(size: 11))
                    .foregroundColor(healthColor(for: info.healthPercent))
                Spacer()
                Text("\(info.healthPercent)%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(12)
        .background(Theme.secondaryBg)
        .cornerRadius(6)
        .sheet(isPresented: $showHealthDetail) {
            HealthDetailView(isPresented: $showHealthDetail)
                .environmentObject(voltStore)
        }
    }

    private func healthColor(for percent: Int) -> Color {
        switch percent {
        case 80...: return Theme.accentGreen
        case 60..<80: return Theme.accentOrange
        default: return Theme.accentRed
        }
    }
}

// MARK: - Settings Tab

struct SettingsTabView: View {
    @ObservedObject var voltStore: VoltStore
    @State private var showingExportSheet = false
    @State private var showingExportView = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Notifications section
                settingsSection(title: "NOTIFICATIONS") {
                    VStack(spacing: 12) {
                        Toggle("Fully Charged Alert", isOn: $voltStore.notifyFullyCharged)
                            .toggleStyle(.switch)
                            .controlSize(.small)

                        Toggle("Low Battery Alert", isOn: $voltStore.notifyLowBattery)
                            .toggleStyle(.switch)
                            .controlSize(.small)

                        if voltStore.notifyLowBattery {
                            HStack {
                                Text("Threshold:")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                                Slider(
                                    value: Binding(
                                        get: { Double(voltStore.lowBatteryThreshold) },
                                        set: { voltStore.lowBatteryThreshold = Int($0) }
                                    ),
                                    in: 5...50,
                                    step: 5
                                )
                                Text("\(voltStore.lowBatteryThreshold)%")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .frame(width: 36)
                            }
                        }

                        Toggle("High Temperature Alert", isOn: $voltStore.notifyHighTemp)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                }

                // Export section
                settingsSection(title: "DATA") {
                    VStack(spacing: 8) {
                        Button(action: { showingExportView = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Data...")
                                Spacer()
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.primaryBlue)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // About section
                settingsSection(title: "ABOUT") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Volt")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("Battery monitor and optimizer for Mac")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background)
        .sheet(isPresented: $showingExportView) {
            ExportView(isPresented: $showingExportView)
                .environmentObject(voltStore)
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .tracking(0.05)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(12)
            .background(Theme.secondaryBg)
            .cornerRadius(10)
        }
    }

    private func exportSessions() {
        if let url = voltStore.exportSessionsCSV() {
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
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

// MARK: - Color Extension for Theme

extension Color {
    static let accentBlue = Theme.primaryBlue
}
