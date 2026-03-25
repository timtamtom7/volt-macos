import AppKit
import SwiftUI

// MARK: - MainActor VoltState

@MainActor
final class VoltState: ObservableObject {
    let batteryService = BatteryService()
    let store: VoltStore

    init() {
        store = VoltStore(batteryService: batteryService)
        store.loadSettings()
        store.refreshBatteryInfo()
    }
}

// MARK: - App Delegate

final class VoltAppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var voltState: VoltState!
    private var eventMonitor: Any?
    private var updateTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        voltState = VoltState()
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        startStatusUpdateTimer()
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
        popover.contentSize = NSSize(width: 320, height: 280)
        popover.behavior = .transient
        popover.animates = true

        let contentView = ContentView(voltStore: voltState.store)
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
            let info = self.voltState.store.currentCharge
            let charge = info.charge
            let charging = info.isCharging
            let symbol = charging ? "⚡" : ""
            self.statusItem.button?.title = "\(symbol)\(charge)%"
        }
    }

    // MARK: - Actions

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            Task { @MainActor in
                self.voltState.store.refreshBatteryInfo()
                self.refreshStatusTitle()
            }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
