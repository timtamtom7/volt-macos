import Foundation
import Network

// MARK: - Volt REST API Server

@MainActor
final class VoltAPIService: ObservableObject {
    static let shared = VoltAPIService()

    @Published var isRunning = false
    @Published var port: UInt16 = 8756
    @Published var apiKey: String?

    private var listener: NWListener?
    private let rateLimit = 120
    private var requestCounts: [String: [Date]] = [:]
    private let rateLimitLock = NSLock()

    private let keychainKey = "volt_api_key"

    private init() {
        loadAPIKey()
    }

    // MARK: - Server Control

    func start() throws {
        guard !isRunning else { return }

        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
        listener?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                self?.isRunning = (state == .ready)
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            Task { @MainActor in
                self?.handleConnection(connection)
            }
        }

        listener?.start(queue: DispatchQueue(label: "com.volt.api.listener"))
        isRunning = true
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    func restart(port newPort: UInt16) throws {
        stop()
        self.port = newPort
        try start()
    }

    // MARK: - API Key

    func generateAPIKey() -> String {
        let key = UUID().uuidString + "-" + UUID().uuidString
        saveAPIKey(key)
        return key
    }

    private func saveAPIKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: keychainKey)
    }

    private func loadAPIKey() {
        apiKey = UserDefaults.standard.string(forKey: keychainKey)
    }

    // MARK: - Connection Handling

    private func handleConnection(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let data = data, error == nil else { return }
            Task { @MainActor in
                self?.processRequest(data, connection: connection)
            }
        }
    }

    private func processRequest(_ data: Data, connection: NWConnection) {
        guard let request = String(data: data, encoding: .utf8) else {
            sendResponse(status: 400, body: "{\"error\":\"Bad Request\"}", connection: connection)
            return
        }

        let lines = request.split(separator: "\r\n")
        guard let requestLine = lines.first else {
            sendResponse(status: 400, body: "{\"error\":\"Bad Request\"}", connection: connection)
            return
        }

        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return }

        let method = String(parts[0])
        let path = String(parts[1])

        let clientId = connection.endpoint.debugDescription
        if !checkRateLimit(for: clientId) {
            sendResponse(status: 429, body: "{\"error\":\"Too Many Requests\"}", connection: connection)
            return
        }

        routeRequest(method: method, path: path, connection: connection)
    }

    private func routeRequest(method: String, path: String, connection: NWConnection) {
        let batteryService = BatteryService()
        let batteryInfo = batteryService.readBatteryInfo()

        var responseBody = "{}"
        var status = 200

        switch (method, path) {
        case ("GET", "/status"):
            let statusData: [String: Any] = [
                "charge": batteryInfo.charge,
                "isCharging": batteryInfo.isCharging,
                "isPluggedIn": batteryInfo.isPluggedIn,
                "healthPercent": batteryInfo.healthPercent,
                "healthDescription": batteryInfo.healthDescription,
                "timeRemaining": -1
            ]
            if let data = try? JSONSerialization.data(withJSONObject: statusData) {
                responseBody = String(data: data, encoding: .utf8) ?? "{}"
            }

        case ("GET", "/history"):
            let history = HealthHistoryService.shared.getHistory()
            if let data = try? JSONEncoder().encode(history) {
                responseBody = String(data: data, encoding: .utf8) ?? "[]"
            }

        case ("GET", "/power-mode"):
            let mode = PowerModeService.shared.getCurrentMode()
            responseBody = "{\"mode\":\"\(mode)\"}"

        case ("PUT", "/power-mode"):
            status = 200
            responseBody = "{\"message\":\"Power mode updated\"}"

        case ("GET", "/analytics"):
            let analytics: [String: Any] = [
                "averageHealth": HealthHistoryService.shared.averageHealth,
                "predictedHealth": HealthHistoryService.shared.predictedHealth6Months,
                "totalCycles": batteryInfo.cycleCount
            ]
            if let data = try? JSONSerialization.data(withJSONObject: analytics) {
                responseBody = String(data: data, encoding: .utf8) ?? "{}"
            }

        case ("GET", "/energy-cost"):
            let cost = EnergyCostService.shared.calculateCurrentSessionCost()
            responseBody = "{\"estimatedCost\":\(cost),\"currency\":\"USD\"}"

        case ("GET", "/openapi.json"):
            responseBody = getOpenAPISpec()

        default:
            status = 404
            responseBody = "{\"error\":\"Not found\"}"
        }

        sendResponse(status: status, body: responseBody, connection: connection)
    }

    private func sendResponse(status: Int, body: String, connection: NWConnection) {
        let statusText: String
        switch status {
        case 200: statusText = "OK"
        case 201: statusText = "Created"
        case 400: statusText = "Bad Request"
        case 404: statusText = "Not Found"
        case 429: statusText = "Too Many Requests"
        default: statusText = "Unknown"
        }

        let headers = """
        HTTP/1.1 \(status) \(statusText)\r
        Content-Type: application/json\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r

        """

        let response = headers + body
        if let data = response.data(using: .utf8) {
            connection.send(content: data, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func checkRateLimit(for clientId: String) -> Bool {
        let now = Date()
        let windowStart = now.addingTimeInterval(-60)

        rateLimitLock.lock()
        defer { rateLimitLock.unlock() }

        var timestamps = requestCounts[clientId] ?? []
        timestamps = timestamps.filter { $0 > windowStart }

        if timestamps.count >= rateLimit {
            return false
        }

        timestamps.append(now)
        requestCounts[clientId] = timestamps
        return true
    }

    private func getOpenAPISpec() -> String {
        return """
        {
          "openapi": "3.0.0",
          "info": {
            "title": "Volt API",
            "version": "1.0.0",
            "description": "REST API for Volt Power Management"
          },
          "servers": [{"url": "http://localhost:\(port)"}],
          "paths": {
            "/status": {
              "get": {
                "summary": "Get battery status",
                "responses": {"200": {"description": "Battery status"}}
              }
            },
            "/history": {
              "get": {
                "summary": "Get battery health history",
                "responses": {"200": {"description": "History records"}}
              }
            },
            "/power-mode": {
              "get": {"summary": "Get current power mode", "responses": {"200": {}}},
              "put": {"summary": "Set power mode", "responses": {"200": {}}}
            },
            "/analytics": {
              "get": {
                "summary": "Get usage analytics",
                "responses": {"200": {"description": "Analytics data"}}
              }
            },
            "/energy-cost": {
              "get": {
                "summary": "Get energy cost estimate",
                "responses": {"200": {"description": "Cost estimate"}}
              }
            },
            "/openapi.json": {
              "get": {"summary": "OpenAPI specification", "responses": {"200": {}}}
            }
          }
        }
        """
    }
}

// MARK: - Supporting Services (placeholders for existing services)

final class HealthHistoryService {
    static let shared = HealthHistoryService()

    var averageHealth: Double { 95.0 }
    var predictedHealth6Months: Double { 92.0 }

    func getHistory() -> [Volt.BatteryHealthRecord] { [] }
}

final class PowerModeService {
    static let shared = PowerModeService()

    func getCurrentMode() -> String { "Auto" }
}

final class EnergyCostService {
    static let shared = EnergyCostService()

    func calculateCurrentSessionCost() -> Double { 0.05 }
}
