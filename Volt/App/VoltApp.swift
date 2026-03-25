import AppKit
import SwiftUI

// MARK: - App Delegate

final class VoltAppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var updateTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = VoltState.shared
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        startStatusUpdateTimer()
        requestNotificationPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        updateTimer?.invalidate()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem.button else { return }
        button.title = "--%"
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 420)
        popover.behavior = .transient
        popover.animates = true

        let store = VoltState.shared.store
        let contentView = ContentView(voltStore: store)
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    private func startStatusUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refreshStatusTitle()
        }
        refreshStatusTitle()
    }

    private func refreshStatusTitle() {
        Task { @MainActor in
            let info = VoltState.shared.store.currentCharge
            let charge = info.charge
            let charging = info.isCharging
            let symbol = charging ? "⚡" : ""
            self.statusItem.button?.title = "\(symbol)\(charge)%"
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        VoltNotificationService.shared.requestAuthorization { _ in }
    }

    // MARK: - Actions

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            Task { @MainActor in
                VoltState.shared.store.refreshBatteryInfo()
                self.refreshStatusTitle()
            }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc private func syncNow() {
        VoltSyncManager.shared.syncNow()
    }
}

// MARK: - Glance View (iStats-style)

struct GlanceView: View {
    let charge: Int
    let isCharging: Bool
    let health: Int
    let temperature: Double
    let cycles: Int
    let profileName: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: CGFloat(charge) / 100.0)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(charge)%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(statusText)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 16) {
                statTile(icon: "heart.fill", label: "Health", value: "\(health)%")
                statTile(icon: "thermometer.medium", label: "Temp", value: "\(Int(temperature))°C")
                statTile(icon: "arrow.2.circlepath", label: "Cycles", value: "\(cycles)")
            }

            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.orange)
                Text(profileName)
                    .font(.system(size: 11, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .padding(16)
        .frame(width: 200, height: 220)
    }

    private func statTile(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }

    private var ringColor: Color {
        if charge < 20 { return .red }
        if charge < 50 { return .yellow }
        return .green
    }

    private var statusText: String {
        if isCharging { return "Charging" }
        return "On Battery"
    }
}

// MARK: - Main Actor VoltState (Singleton)

@MainActor
final class VoltState: ObservableObject {
    static let shared = VoltState()

    let batteryService = BatteryService()
    let store: VoltStore

    private init() {
        store = VoltStore(batteryService: batteryService)
        store.refreshBatteryInfo()
    }
}
