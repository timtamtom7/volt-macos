import SwiftUI

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

    private var noFleetView: some View {
        VStack(spacing: Theme.spacing24) {
            Image(systemName: "server.rack")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(Theme.textSecondary)

            Text("Team Fleet Management")
                .font(.system(size: Theme.fontSizeTitle2, weight: .bold))

            Text("Share power profiles with your team, monitor fleet battery health, and manage power policies across your organization.")
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: 400)

            HStack(spacing: Theme.spacing16) {
                Button("Create Fleet") {
                    showCreateFleet = true
                }
                .buttonStyle(.borderedProminent)

                Button("Join Fleet") {
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(Theme.spacing16)
        .sheet(isPresented: $showCreateFleet) {
            createFleetSheet
        }
    }

    private func fleetContent(_ fleet: TeamFleet) -> some View {
        ScrollView {
            VStack(spacing: Theme.spacing24) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(fleet.name)
                            .font(.system(size: Theme.fontSizeTitle2, weight: .bold))
                        Text("\(fleet.deviceCount) devices")
                            .foregroundColor(Theme.textSecondary)
                    }

                    Spacer()

                    Button("Leave Fleet") {
                        fleetService.leaveFleet()
                    }
                    .foregroundColor(Theme.danger)
                }
                .padding(Theme.spacing16)

                fleetSummarySection
                devicesSection
                profilesSection
            }
        }
    }

    private var fleetSummarySection: some View {
        let summary = fleetService.getFleetSummary()

        return VStack(alignment: .leading, spacing: Theme.spacing12) {
            Text("Fleet Overview")
                .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))

            HStack(spacing: Theme.spacing20) {
                summaryCard("Devices", value: "\(summary.totalDevices)", icon: "laptopcomputer")
                summaryCard("Avg Health", value: "\(summary.averageHealth)%", icon: "battery.100")
                summaryCard("Need Service", value: "\(summary.devicesNeedingService)", icon: "exclamationmark.triangle")
                summaryCard("Avg Cycles", value: "\(summary.averageCyclesPerDevice)", icon: "arrow.triangle.2.circlepath")
            }

            HStack {
                Text("Fleet Health: \(summary.healthStatus)")
                    .font(.system(size: Theme.fontSizeSubheadline, weight: .medium))
                    .foregroundColor(summary.averageHealth >= 80 ? Theme.accentGreen : Theme.accentOrange)

                Spacer()

                Button("Export Report") {
                    exportReport()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(Theme.spacing16)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusLG)
    }

    private func summaryCard(_ title: String, value: String, icon: String) -> some View {
        VStack(spacing: Theme.spacing4) {
            Image(systemName: icon)
                .font(.system(size: Theme.fontSizeTitle3, weight: .medium))
                .foregroundColor(Theme.primaryBlue)
            Text(value)
                .font(.system(size: Theme.fontSizeTitle3, weight: .bold))
            Text(title)
                .font(.system(size: Theme.fontSizeCaption, weight: .regular))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var devicesSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing12) {
            HStack {
                Text("Devices")
                    .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))

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
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(fleetService.fleetDevices) { device in
                    deviceRow(device)
                }
            }
        }
        .padding(Theme.spacing16)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusLG)
    }

    private func deviceRow(_ device: FleetDevice) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.deviceName)
                    .font(.system(size: Theme.fontSizeSubheadline, weight: .medium))
                Text(device.deviceModel)
                    .font(.system(size: Theme.fontSizeCaption, weight: .regular))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                HStack(spacing: Theme.spacing4) {
                    Image(systemName: healthIcon(device.batteryHealthPercent))
                        .foregroundColor(healthColor(device.batteryHealthPercent))
                    Text("\(device.batteryHealthPercent)%")
                        .fontWeight(.medium)
                }
                Text("Health")
                    .font(.system(size: Theme.fontSizeCaption2, weight: .regular))
                    .foregroundColor(Theme.textSecondary)
            }

            VStack(alignment: .trailing) {
                Text("\(device.cycleCount)")
                    .fontWeight(.medium)
                Text("Cycles")
                    .font(.system(size: Theme.fontSizeCaption2, weight: .regular))
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(width: 60)
        }
        .padding(.vertical, Theme.spacing4)
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
        case 80...: return Theme.accentGreen
        case 60..<80: return Theme.accentOrange
        default: return Theme.danger
        }
    }

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing12) {
            HStack {
                Text("Power Profiles")
                    .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))

                Spacer()

                Button("Import") { }
                    .buttonStyle(.bordered)
            }

            Text("Share and discover power profiles with your team")
                .font(.system(size: Theme.fontSizeCaption, weight: .regular))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.spacing16)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusLG)
    }

    private var createFleetSheet: some View {
        VStack(spacing: Theme.spacing20) {
            Text("Create Fleet")
                .font(.system(size: Theme.fontSizeTitle3, weight: .bold))

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
        .padding(Theme.spacing32)
        .frame(width: 350)
    }

    private func exportReport() {
        if let url = fleetService.exportFleetReportCSV() {
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
        }
    }
}
