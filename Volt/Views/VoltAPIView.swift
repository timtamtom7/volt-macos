import SwiftUI

// MARK: - Volt API View

struct VoltAPIView: View {
    @State private var isRunning = false
    @State private var portString = "8756"
    @State private var showAPIKey = false
    @State private var currentAPIKey: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text("REST API Server")
                        .font(.title2)
                        .fontWeight(.bold)

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
                    .foregroundColor(.secondary)

                Divider()

                // Configuration
                VStack(alignment: .leading, spacing: 16) {
                    Text("Configuration")
                        .font(.headline)

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
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                Divider()

                // API Key
                VStack(alignment: .leading, spacing: 16) {
                    Text("API Authentication")
                        .font(.headline)

                    if let apiKey = currentAPIKey {
                        HStack {
                            if showAPIKey {
                                Text(apiKey)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            } else {
                                Text(String(repeating: "•", count: 40))
                                    .font(.system(.body, design: .monospaced))
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
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                Divider()

                // Endpoints
                VStack(alignment: .leading, spacing: 16) {
                    Text("API Endpoints")
                        .font(.headline)

                    endpointsList
                }

                Divider()

                // Example Usage
                VStack(alignment: .leading, spacing: 16) {
                    Text("Example Usage")
                        .font(.headline)

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
            .padding()
        }
        .frame(minWidth: 600, minHeight: 600)
        .onAppear {
            portString = String(VoltAPIService.shared.port)
            isRunning = VoltAPIService.shared.isRunning
            currentAPIKey = VoltAPIService.shared.apiKey
        }
    }

    private var endpointsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            endpointRow("GET", "/status", "Battery status")
            endpointRow("GET", "/history", "Battery health history")
            endpointRow("GET", "/power-mode", "Current power mode")
            endpointRow("PUT", "/power-mode", "Set power mode")
            endpointRow("GET", "/analytics", "Usage analytics")
            endpointRow("GET", "/energy-cost", "Energy cost estimate")
            endpointRow("GET", "/openapi.json", "OpenAPI 3.0 spec")
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func endpointRow(_ method: String, _ path: String, _ description: String) -> some View {
        HStack {
            Text(method)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(methodColor(method))
                .frame(width: 50, alignment: .leading)

            Text(path)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)

            Spacer()

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return .green
        case "PUT": return .orange
        case "POST": return .blue
        case "DELETE": return .red
        default: return .gray
        }
    }

    private func codeBlock(_ code: String) -> some View {
        Text(code)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
    }

    // MARK: - Actions

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
