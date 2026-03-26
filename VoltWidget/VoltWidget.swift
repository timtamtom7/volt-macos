import WidgetKit
import SwiftUI

@main
struct VoltWidgetBundle: WidgetBundle {
    var body: some Widget {
        VoltBatteryWidget()
        VoltHealthWidget()
    }
}

struct VoltEntry: TimelineEntry {
    let date: Date
    let batteryPercent: Int
    let healthPercent: Int
    let isCharging: Bool
    let timeRemaining: String?
}

struct VoltProvider: TimelineProvider {
    func placeholder(in context: Context) -> VoltEntry {
        VoltEntry(date: Date(), batteryPercent: 75, healthPercent: 92, isCharging: false, timeRemaining: "4h 30m")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (VoltEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<VoltEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }
    
    private func loadEntry() -> VoltEntry {
        let defaults = UserDefaults(suiteName: "group.com.volt.macos") ?? .standard
        let percent = defaults.integer(forKey: "widget_battery_percent")
        let health = defaults.integer(forKey: "widget_health_percent")
        let charging = defaults.bool(forKey: "widget_is_charging")
        let remaining = defaults.string(forKey: "widget_time_remaining")
        return VoltEntry(date: Date(), batteryPercent: percent > 0 ? percent : 75, healthPercent: health > 0 ? health : 92, isCharging: charging, timeRemaining: remaining)
    }
}

// MARK: - Battery Widget (Small)

struct VoltBatteryWidget: Widget {
    let kind = "VoltBatteryWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VoltProvider()) { entry in
            SmallBatteryView(entry: entry)
        }
        .configurationDisplayName("Battery")
        .description("Current battery percentage and status")
        .supportedFamilies([.systemSmall])
    }
}

struct SmallBatteryView: View {
    let entry: VoltEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                Text("Volt")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(entry.batteryPercent)")
                    .font(.system(size: 36, weight: .bold))
                Text("%")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            BatteryGaugeView(percent: entry.batteryPercent, isCharging: entry.isCharging)
            
            if entry.isCharging {
                Label("Charging", systemImage: "bolt.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
            } else if let remaining = entry.timeRemaining {
                Text(remaining)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct BatteryGaugeView: View {
    let percent: Int
    let isCharging: Bool
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                RoundedRectangle(cornerRadius: 4)
                    .fill(batteryColor)
                    .frame(width: geo.size.width * CGFloat(percent) / 100)
            }
        }
        .frame(height: 8)
    }
    
    var batteryColor: Color {
        if isCharging { return .green }
        if percent <= 20 { return .red }
        if percent <= 50 { return .orange }
        return .primary
    }
}

// MARK: - Health Widget (Medium)

struct VoltHealthWidget: Widget {
    let kind = "VoltHealthWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VoltProvider()) { entry in
            MediumHealthView(entry: entry)
        }
        .configurationDisplayName("Battery Health")
        .description("Battery percentage and health overview")
        .supportedFamilies([.systemMedium])
    }
}

struct MediumHealthView: View {
    let entry: VoltEntry
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("Volt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(entry.batteryPercent)%")
                    .font(.system(size: 40, weight: .bold))
                
                BatteryGaugeView(percent: entry.batteryPercent, isCharging: entry.isCharging)
                    .frame(height: 10)
                
                if entry.isCharging {
                    Label("Charging", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if let remaining = entry.timeRemaining {
                    Text(remaining + " remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("HEALTH")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(entry.healthPercent)%")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(healthColor)
                
                HealthRingView(percent: entry.healthPercent)
                
                Text("Battery health")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
    
    var healthColor: Color {
        if entry.healthPercent >= 80 { return .green }
        if entry.healthPercent >= 50 { return .orange }
        return .red
    }
}

struct HealthRingView: View {
    let percent: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(percent) / 100)
                .stroke(healthColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 50, height: 50)
    }
    
    var healthColor: Color {
        if percent >= 80 { return .green }
        if percent >= 50 { return .orange }
        return .red
    }
}
