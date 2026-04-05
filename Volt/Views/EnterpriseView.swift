import SwiftUI

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
            .padding(Theme.spacing16)

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

    private var mdmConfigView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing24) {
                HStack {
                    Text("Mobile Device Management")
                        .font(.system(size: Theme.fontSizeTitle3, weight: .bold))

                    Spacer()

                    if fleetService.isMDMEnrolled {
                        Label("Enrolled", systemImage: "checkmark.circle.fill")
                            .foregroundColor(Theme.accentGreen)
                    }
                }

                Text("Configure MDM settings for enterprise deployment. IT administrators can push power profiles and policies to managed Macs.")
                    .foregroundColor(Theme.textSecondary)

                if fleetService.isMDMEnrolled {
                    enrolledMDMView
                } else {
                    notEnrolledView
                }
            }
            .padding(Theme.spacing16)
        }
    }

    private var enrolledMDMView: some View {
        VStack(alignment: .leading, spacing: Theme.spacing16) {
            if let config = fleetService.mdmConfiguration {
                infoRow("Organization", config.organizationName)
                infoRow("Server", config.serverURL ?? "N/A")

                Divider()

                Text("Managed Settings")
                    .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))

                managedSettingsGrid(config.managedSettings)

                Divider()

                Text("Locked Settings")
                    .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))

                if config.lockedSettings.isEmpty {
                    Text("No settings locked")
                        .foregroundColor(Theme.textSecondary)
                } else {
                    ForEach(config.lockedSettings, id: \.self) { setting in
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(Theme.accentOrange)
                            Text(setting)
                        }
                    }
                }

                Button("Unenroll from MDM") {
                    fleetService.unenrollMDM()
                }
                .foregroundColor(Theme.danger)
            }
        }
        .padding(Theme.spacing16)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusLG)
    }

    private var notEnrolledView: some View {
        VStack(spacing: Theme.spacing16) {
            Image(systemName: "building.2")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Theme.textSecondary)

            Text("Not Enrolled in MDM")
                .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))

            Text("Enter your MDM server details to enroll this Mac in enterprise management.")
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textSecondary)

            Button("Enroll in MDM") {
                showEnrollment = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(Theme.spacing40)
        .frame(maxWidth: .infinity)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusLG)
        .sheet(isPresented: $showEnrollment) {
            enrollmentSheet
        }
    }

    private var enrollmentSheet: some View {
        VStack(spacing: Theme.spacing20) {
            Text("MDM Enrollment")
                .font(.system(size: Theme.fontSizeTitle3, weight: .bold))

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
        .padding(Theme.spacing32)
        .frame(width: 400)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func managedSettingsGrid(_ settings: ManagedSettings) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacing8) {
            settingToggle("Force Low Power Mode", isOn: settings.forceLowPowerMode)
            settingToggle("Disable Sleep Mode", isOn: settings.disableSleepMode)

            if let start = settings.quietHoursStart, let end = settings.quietHoursEnd {
                HStack {
                    Text("Quiet Hours")
                    Spacer()
                    Text("\(start) - \(end)")
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private func settingToggle(_ label: String, isOn: Bool) -> some View {
        HStack {
            Text(label)
            Spacer()
            Image(systemName: isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(isOn ? Theme.accentGreen : Theme.textSecondary)
        }
    }

    private var complianceView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing24) {
                Text("Compliance & Audit Reports")
                    .font(.system(size: Theme.fontSizeTitle3, weight: .bold))

                Text("Generate battery health compliance reports and audit logs for regulatory requirements.")
                    .foregroundColor(Theme.textSecondary)

                HStack(spacing: Theme.spacing16) {
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
            .padding(Theme.spacing16)
        }
    }

    private var complianceInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing12) {
            Text("Available Reports")
                .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))

            reportRow("Battery Health Compliance", "PDF", "SOC 2 compliant battery health report")
            reportRow("Fleet Battery Summary", "CSV", "Overview of all fleet devices")
            reportRow("Audit Log", "JSON", "All power setting changes")
            reportRow("GDPR Data Export", "JSON", "All personal data in Volt")
        }
        .padding(Theme.spacing16)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusLG)
    }

    private func reportRow(_ name: String, _ format: String, _ description: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .fontWeight(.medium)
                Text(description)
                    .font(.system(size: Theme.fontSizeCaption, weight: .regular))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Text(format)
                .font(.system(size: Theme.fontSizeCaption, weight: .regular))
                .padding(.horizontal, Theme.spacing8)
                .padding(.vertical, Theme.spacing4)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(Theme.cornerRadiusSM)
        }
        .padding(.vertical, Theme.spacing4)
    }

    private var ssoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing24) {
                Text("Single Sign-On (SSO)")
                    .font(.system(size: Theme.fontSizeTitle3, weight: .bold))

                Text("Configure enterprise SSO for dashboard access. Supports Okta, Azure AD, and Google Workspace.")
                    .foregroundColor(Theme.textSecondary)

                VStack(alignment: .leading, spacing: Theme.spacing16) {
                    Text("Supported Providers")
                        .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))

                    HStack(spacing: Theme.spacing20) {
                        providerButton("Okta", icon: "O")
                        providerButton("Azure AD", icon: "A")
                        providerButton("Google", icon: "G")
                    }
                }
                .padding(Theme.spacing16)
                .background(Theme.secondaryBackground)
                .cornerRadius(Theme.cornerRadiusLG)
            }
            .padding(Theme.spacing16)
        }
    }

    private func providerButton(_ name: String, icon: String) -> some View {
        VStack {
            Text(icon)
                .font(.system(size: Theme.fontSizeTitle2, weight: .bold))
                .frame(width: 50, height: 50)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(Theme.cornerRadiusMD)
            Text(name)
                .font(.system(size: Theme.fontSizeCaption, weight: .regular))
        }
    }

    private var licenseView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing24) {
                Text("Volume License Management")
                    .font(.system(size: Theme.fontSizeTitle3, weight: .bold))

                Text("Manage Apple VPP volume licenses for organization-wide deployment.")
                    .foregroundColor(Theme.textSecondary)

                VStack(spacing: Theme.spacing16) {
                    licenseCard("Total Licenses", "100", icon: "doc.badge.plus")
                    licenseCard("Assigned", "75", icon: "person.badge.plus")
                    licenseCard("Available", "25", icon: "checkmark.circle")
                }

                Button("View in Apple Business Manager") {
                }
                .buttonStyle(.bordered)
            }
            .padding(Theme.spacing16)
        }
    }

    private func licenseCard(_ title: String, _ value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: Theme.fontSizeTitle3, weight: .medium))
                .foregroundColor(Theme.primaryBlue)

            VStack(alignment: .leading) {
                Text(value)
                    .font(.system(size: Theme.fontSizeTitle3, weight: .bold))
                Text(title)
                    .font(.system(size: Theme.fontSizeCaption, weight: .regular))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(Theme.spacing16)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusLG)
    }

    private func generateComplianceReport() {
    }

    private func exportAuditLog() {
    }
}
