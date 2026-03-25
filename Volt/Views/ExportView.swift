import SwiftUI

struct ExportView: View {
    @EnvironmentObject var voltStore: VoltStore
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Export Data")
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

            ScrollView {
                VStack(spacing: 16) {
                    // Session Export
                    exportSection(
                        title: "Charging Sessions",
                        description: "Export all charging session records with duration and charge data",
                        icon: "bolt.circle",
                        action: exportSessions
                    )

                    // Stats Export
                    exportSection(
                        title: "Daily Statistics",
                        description: "Export daily battery statistics over time",
                        icon: "chart.bar",
                        action: exportStats
                    )

                    // Full Export
                    exportSection(
                        title: "Full Export (JSON)",
                        description: "Complete backup of all charging data",
                        icon: "doc.text",
                        action: exportFull
                    )
                }
                .padding(16)
            }
        }
        .frame(width: 400, height: 340)
        .background(Theme.background)
    }

    private func exportSection(title: String, description: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Theme.primaryBlue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(12)
            .background(Theme.secondaryBg)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func exportSessions() {
        if let url = ChargingExportService.shared.exportSessionsToCSV(sessions: voltStore.recentSessions) {
            ChargingExportService.shared.shareExport(at: url)
        }
    }

    private func exportStats() {
        if let url = ChargingExportService.shared.exportDailyStatsToCSV(stats: voltStore.weeklyHistory) {
            ChargingExportService.shared.shareExport(at: url)
        }
    }

    private func exportFull() {
        if let url = ChargingExportService.shared.exportAllData(
            sessions: voltStore.recentSessions,
            stats: voltStore.weeklyHistory
        ) {
            ChargingExportService.shared.shareExport(at: url)
        }
    }
}
