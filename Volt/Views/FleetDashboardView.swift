import SwiftUI

// MARK: - Fleet Dashboard View

struct FleetDashboardView: View {
    @StateObject private var fleetService = TeamFleetService.shared
    @State private var showCreateFleet = false
    @State private var fleetName = ""
    @State private var adminEmail = ""
    @State private var inviteCode = ""

    var body: some View {
        Group {
            if let fleet = fleetService.currentFleet {
                fleetContent(fleet)
            } else {
                noFleetView
            }
        }
    }

    // MARK: - No Fleet View

    private var noFleetView: some View {
        VStack(spacing: 24) {
            Image(systemName: "server.rack")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Team Fleet Management")
                .font(.title)
                .fontWeight(.bold)

            Text("Share power profiles with your team, monitor fleet battery health, and manage power policies across organization.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 400)

            HStack(spacing: 16) {
                Button("Create Fleet") {
                    showCreateFleet = true
                }
                .buttonStyle(.borderedProminent)

                Button("Join Fleet") {
                    // Show join dialog
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .sheet(isPresented: $showCreateFleet) {
            createFleetSheet
        }
    }

    // MARK: - Fleet Content

    private func fleetContent(_ fleet: TeamFleet) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(fleet.name)
                            .font(.title)
                            .fontWeight(.bold)
                        Text("\(fleet.deviceCount) devices")
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Leave Fleet") {
                        fleetService.leaveFleet()
                    }
                    .foregroundColor(.red)
                }
                .padding()

                // Fleet Summary
                fleetSummarySection

                // Devices
                devicesSection

                // Power Profiles
                profilesSection
            }
        }
    }

    // MARK: - Fleet Summary

    private var fleetSummarySection: some View {
        let summary = fleetService.getFleetSummary()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Fleet Overview")
                .font(.headline)

            HStack(spacing: 20) {
                summaryCard("Devices", value: "\(summary.totalDevices)", icon: "laptopcomputer")
                summaryCard("Avg Health", value: "\(summary.averageHealth)%", icon: "battery.100")
                summaryCard("Need Service", value: "\(summary.devicesNeedingService)", icon: "exclamationmark.triangle")
                summaryCard("Avg Cycles", value: "\(summary.averageCyclesPerDevice)", icon: "arrow.triangle.2.circlepath")
            }

            HStack {
                Text("Fleet Health: \(summary.healthStatus)")
                    .font(.subheadline)
                    .foregroundColor(summary.averageHealth >= 80 ? .green : .orange)

                Spacer()

                Button("Export Report") {
                    exportReport()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func summaryCard(_ title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Devices Section

    private var devicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Devices")
                    .font(.headline)

                Spacer()

                Button("Refresh") {
                    Task {
                        await fleetService.refreshFleetDevices()
                    }
                }
                .buttonStyle(.bordered)
            }

            if fleetService.fleetDevices.isEmpty {
                Text("No devices in fleet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(fleetService.fleetDevices) { device in
                    deviceRow(device)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func deviceRow(_ device: FleetDevice) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.deviceName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(device.deviceModel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                HStack(spacing: 4) {
                    Image(systemName: healthIcon(device.batteryHealthPercent))
                        .foregroundColor(healthColor(device.batteryHealthPercent))
                    Text("\(device.batteryHealthPercent)%")
                        .fontWeight(.medium)
                }
                Text("Health")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .trailing) {
                Text("\(device.cycleCount)")
                    .fontWeight(.medium)
                Text("Cycles")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)

            if device.isBelowThreshold {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private func healthIcon(_ health: Int) -> String {
        switch health {
        case 90...: return "battery.100"
        case 70..<90: return "battery.75"
        case 50..<70: return "battery.50"
        default: return "battery.25"
        }
    }

    private func healthColor(_ health: Int) -> Color {
        switch health {
        case 80...: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }

    // MARK: - Profiles Section

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Power Profiles")
                    .font(.headline)

                Spacer()

                Button("Import") { }
                    .buttonStyle(.bordered)
            }

            Text("Share and discover power profiles with your team")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Create Fleet Sheet

    private var createFleetSheet: some View {
        VStack(spacing: 20) {
            Text("Create Fleet")
                .font(.title2)
                .fontWeight(.bold)

            TextField("Fleet Name", text: $fleetName)
                .textFieldStyle(.roundedBorder)

            TextField("Admin Email", text: $adminEmail)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    showCreateFleet = false
                }
                .buttonStyle(.bordered)

                Button("Create") {
                    _ = fleetService.createFleet(name: fleetName, adminEmail: adminEmail)
                    showCreateFleet = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(fleetName.isEmpty || adminEmail.isEmpty)
            }
        }
        .padding(32)
        .frame(width: 350)
    }

    // MARK: - Actions

    private func exportReport() {
        if let url = fleetService.exportFleetReportCSV() {
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
        }
    }
}
