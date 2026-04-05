import SwiftUI

struct VoltAPIView: View {
    @State private var isRunning = false
    @State private var portString = "8756"
    @State private var showAPIKey = false
    @State private var currentAPIKey: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing24) {
                HStack {
                    Text("REST API Server")
                        .font(.system(size: Theme.fontSizeTitle3, weight: .bold))

                    Spacer()

                    Toggle("Server", isOn: $isRunning)
                        .toggleStyle(.switch)
                        .onChange(of: isRunning) { newValue in
                            Task {
                                if newValue {
                                    await startServer()
                                } else {
                                    await stopServer()
                                }
                            }
                        }
                }

                Text("Enable the local API server to access Volt battery data from other apps, scripts, or the web dashboard.")
                    .foregroundColor(Theme.textSecondary)

                Divider()

                VStack(alignment: .leading, spacing: Theme.spacing16) {
                    Text("Configuration")
                        .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))

                    HStack {
                        Text("Port:")
                        TextField("Port", text: $portString)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .disabled(isRunning)
                    }

                    Button("Restart Server") {
                        Task {
                            await restartServer()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isRunning)
                }
                .padding(Theme.spacing16)
                .background(Theme.secondaryBackground)
                .cornerRadius(Theme.cornerRadiusMD)

                Divider()

                VStack(alignment: .leading, spacing: Theme.spacing16) {
                    Text("API Authentication")
                        .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))

                    if let apiKey = currentAPIKey {
                        HStack {
                            if showAPIKey {
                                Text(apiKey)
                                    .font(.system(size: Theme.fontSizeBody, design: .monospaced))
                                    .textSelection(.enabled)
                            } else {
                                Text(String(repeating: "•", count: 40))
                                    .font(.system(size: Theme.fontSizeBody, design: .monospaced))
                            }

                            Spacer()

                            Button(showAPIKey ? "Hide" : "Show") {
                                showAPIKey.toggle()
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Button("Generate API Key") {
                            currentAPIKey = VoltAPIService.shared.generateAPIKey()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(Theme.spacing16)
                .background(Theme.secondaryBackground)
                .cornerRadius(Theme.cornerRadiusMD)

                Divider()

                VStack(alignment: .leading, spacing: Theme.spacing16) {
                    Text("API Endpoints")
                        .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))

                    endpointsList
                }

                Divider()

                VStack(alignment: .leading, spacing: Theme.spacing16) {
                    Text("Example Usage")
                        .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))

                    codeBlock("""
                    # Get battery status
                    curl http://localhost:\(portString)/status

                    # Get battery history
                    curl http://localhost:\(portString)/history

                    # Get current power mode
                    curl http://localhost:\(portString)/power-mode

                    # Set power mode
                    curl -X PUT http://localhost:\(portString)/power-mode

                    # Get analytics
                    curl http://localhost:\(portString)/analytics

                    # Get energy cost estimate
                    curl http://localhost:\(portString)/energy-cost

                    # OpenAPI spec
                    http://localhost:\(portString)/openapi.json
                    """)
                }
            }
            .padding(Theme.spacing16)
        }
        .frame(minWidth: 600, minHeight: 600)
        .onAppear {
            portString = String(VoltAPIService.shared.port)
            isRunning = VoltAPIService.shared.isRunning
            currentAPIKey = VoltAPIService.shared.apiKey
        }
    }

    private var endpointsList: some View {
        VStack(alignment: .leading, spacing: Theme.spacing8) {
            endpointRow("GET", "/status", "Battery status")
            endpointRow("GET", "/history", "Battery health history")
            endpointRow("GET", "/power-mode", "Current power mode")
            endpointRow("PUT", "/power-mode", "Set power mode")
            endpointRow("GET", "/analytics", "Usage analytics")
            endpointRow("GET", "/energy-cost", "Energy cost estimate")
            endpointRow("GET", "/openapi.json", "OpenAPI 3.0 spec")
        }
        .padding(Theme.spacing16)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMD)
    }

    private func endpointRow(_ method: String, _ path: String, _ description: String) -> some View {
        HStack {
            Text(method)
                .font(.system(size: Theme.fontSizeCaption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(methodColor(method))
                .frame(width: 50, alignment: .leading)

            Text(path)
                .font(.system(size: Theme.fontSizeCaption, design: .monospaced))
                .textSelection(.enabled)

            Spacer()

            Text(description)
                .font(.system(size: Theme.fontSizeCaption))
                .foregroundColor(Theme.textSecondary)
        }
    }

    private func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return Theme.accentGreen
        case "PUT": return Theme.accentOrange
        case "POST": return Theme.primaryBlue
        case "DELETE": return Theme.danger
        default: return Theme.textSecondary
        }
    }

    private func codeBlock(_ code: String) -> some View {
        Text(code)
            .font(.system(size: Theme.fontSizeCaption, design: .monospaced))
            .textSelection(.enabled)
            .padding(Theme.spacing16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.tertiaryBackground)
            .cornerRadius(Theme.cornerRadiusMD)
    }

    private func startServer() async {
        do {
            if let port = UInt16(portString) {
                VoltAPIService.shared.port = port
                try VoltAPIService.shared.start()
            }
        } catch {
            print("Failed to start server: \(error)")
        }
    }

    private func stopServer() async {
        VoltAPIService.shared.stop()
    }

    private func restartServer() async {
        do {
            if let port = UInt16(portString) {
                try VoltAPIService.shared.restart(port: port)
            }
        } catch {
            print("Failed to restart server: \(error)")
        }
    }
}
