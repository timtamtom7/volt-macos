import SwiftUI

// MARK: - Enterprise View

struct EnterpriseView: View {
    @StateObject private var fleetService = TeamFleetService.shared
    @State private var selectedTab = 0
    @State private var showEnrollment = false
    @State private var orgName = ""
    @State private var serverURL = ""
    @State private var enrollmentToken = ""

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("MDM Configuration").tag(0)
                Text("Compliance Reports").tag(1)
                Text("SSO Settings").tag(2)
                Text("License Management").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            TabView(selection: $selectedTab) {
                mdmConfigView.tag(0)
                complianceView.tag(1)
                ssoView.tag(2)
                licenseView.tag(3)
            }
            .tabViewStyle(.automatic)
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    // MARK: - MDM Config View

    private var mdmConfigView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Mobile Device Management")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    if fleetService.isMDMEnrolled {
                        Label("Enrolled", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                Text("Configure MDM settings for enterprise deployment. IT administrators can push power profiles and policies to managed Macs.")
                    .foregroundColor(.secondary)

                if fleetService.isMDMEnrolled {
                    enrolledMDMView
                } else {
                    notEnrolledView
                }
            }
            .padding()
        }
    }

    private var enrolledMDMView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let config = fleetService.mdmConfiguration {
                infoRow("Organization", config.organizationName)
                infoRow("Server", config.serverURL ?? "N/A")

                Divider()

                Text("Managed Settings")
                    .font(.headline)

                managedSettingsGrid(config.managedSettings)

                Divider()

                Text("Locked Settings")
                    .font(.headline)

                if config.lockedSettings.isEmpty {
                    Text("No settings locked")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(config.lockedSettings, id: \.self) { setting in
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                            Text(setting)
                        }
                    }
                }

                Button("Unenroll from MDM") {
                    fleetService.unenrollMDM()
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var notEnrolledView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Not Enrolled in MDM")
                .font(.headline)

            Text("Enter your MDM server details to enroll this Mac in enterprise management.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Enroll in MDM") {
                showEnrollment = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .sheet(isPresented: $showEnrollment) {
            enrollmentSheet
        }
    }

    private var enrollmentSheet: some View {
        VStack(spacing: 20) {
            Text("MDM Enrollment")
                .font(.title2)
                .fontWeight(.bold)

            TextField("Organization Name", text: $orgName)
                .textFieldStyle(.roundedBorder)

            TextField("MDM Server URL", text: $serverURL)
                .textFieldStyle(.roundedBorder)

            SecureField("Enrollment Token", text: $enrollmentToken)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    showEnrollment = false
                }
                .buttonStyle(.bordered)

                Button("Enroll") {
                    _ = fleetService.enrollMDM(
                        organizationName: orgName,
                        token: enrollmentToken,
                        serverURL: serverURL
                    )
                    showEnrollment = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(orgName.isEmpty || serverURL.isEmpty)
            }
        }
        .padding(32)
        .frame(width: 400)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func managedSettingsGrid(_ settings: ManagedSettings) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            settingToggle("Force Low Power Mode", isOn: settings.forceLowPowerMode)
            settingToggle("Disable Sleep Mode", isOn: settings.disableSleepMode)

            if let start = settings.quietHoursStart, let end = settings.quietHoursEnd {
                HStack {
                    Text("Quiet Hours")
                    Spacer()
                    Text("\(start) - \(end)")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func settingToggle(_ label: String, isOn: Bool) -> some View {
        HStack {
            Text(label)
            Spacer()
            Image(systemName: isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(isOn ? .green : .secondary)
        }
    }

    // MARK: - Compliance View

    private var complianceView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Compliance & Audit Reports")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Generate battery health compliance reports and audit logs for regulatory requirements.")
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    Button("Generate Compliance Report") {
                        generateComplianceReport()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Export Audit Log") {
                        exportAuditLog()
                    }
                    .buttonStyle(.bordered)
                }

                complianceInfoSection
            }
            .padding()
        }
    }

    private var complianceInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Reports")
                .font(.headline)

            reportRow("Battery Health Compliance", "PDF", "SOC 2 compliant battery health report")
            reportRow("Fleet Battery Summary", "CSV", "Overview of all fleet devices")
            reportRow("Audit Log", "JSON", "All power setting changes")
            reportRow("GDPR Data Export", "JSON", "All personal data in Volt")
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func reportRow(_ name: String, _ format: String, _ description: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(format)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }

    // MARK: - SSO View

    private var ssoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Single Sign-On (SSO)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Configure enterprise SSO for dashboard access. Supports Okta, Azure AD, and Google Workspace.")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Supported Providers")
                        .font(.headline)

                    HStack(spacing: 20) {
                        providerButton("Okta", icon: "O")
                        providerButton("Azure AD", icon: "A")
                        providerButton("Google", icon: "G")
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding()
        }
    }

    private func providerButton(_ name: String, icon: String) -> some View {
        VStack {
            Text(icon)
                .font(.title)
                .fontWeight(.bold)
                .frame(width: 50, height: 50)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(8)
            Text(name)
                .font(.caption)
        }
    }

    // MARK: - License View

    private var licenseView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Volume License Management")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Manage Apple VPP volume licenses for organization-wide deployment.")
                    .foregroundColor(.secondary)

                VStack(spacing: 16) {
                    licenseCard("Total Licenses", "100", icon: "doc.badge.plus")
                    licenseCard("Assigned", "75", icon: "person.badge.plus")
                    licenseCard("Available", "25", icon: "checkmark.circle")
                }

                Button("View in Apple Business Manager") {
                    // Open AB portal
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    private func licenseCard(_ title: String, _ value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func generateComplianceReport() {
        // Generate PDF report
    }

    private func exportAuditLog() {
        // Export JSON audit log
    }
}
