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
        let next = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
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

// MARK: - Widget Theme

enum WidgetTheme {
    static let accentCyan = Color(hex: "00D4FF")
    static let primaryGreen = Color(hex: "34C759")
    static let warning = Color.orange
    static let danger = Color.red
    static let textSecondary = Color.secondary
    static let cornerRadiusSM: CGFloat = 6
    static let cornerRadiusMD: CGFloat = 8
    static let cornerRadiusLG: CGFloat = 12
    static let fontSizeCaption: CGFloat = 11
    static let fontSizeCaption2: CGFloat = 10
    static let fontSizeSubheadline: CGFloat = 12
    static let fontSizeTitle3: CGFloat = 16
    static let fontSizeTitle2: CGFloat = 18
    static let fontSizeLargeTitle: CGFloat = 28
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
                    .foregroundColor(WidgetTheme.accentCyan)
                Text("Volt")
                    .font(.system(size: WidgetTheme.fontSizeCaption, weight: .regular))
                    .foregroundColor(WidgetTheme.textSecondary)
            }
            
            Spacer()
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(entry.batteryPercent)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("%")
                    .font(.system(size: WidgetTheme.fontSizeTitle3, weight: .medium))
                    .foregroundColor(WidgetTheme.textSecondary)
            }
            
            BatteryGaugeView(percent: entry.batteryPercent, isCharging: entry.isCharging)
            
            if entry.isCharging {
                Label("Charging", systemImage: "bolt.fill")
                    .font(.system(size: WidgetTheme.fontSizeCaption2, weight: .regular))
                    .foregroundColor(WidgetTheme.primaryGreen)
            } else if let remaining = entry.timeRemaining {
                Text(remaining)
                    .font(.system(size: WidgetTheme.fontSizeCaption, weight: .regular))
                    .foregroundColor(WidgetTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding(WidgetTheme.cornerRadiusMD)
    }
}

struct BatteryGaugeView: View {
    let percent: Int
    let isCharging: Bool
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: WidgetTheme.cornerRadiusSM)
                    .fill(Color.gray.opacity(0.3))
                RoundedRectangle(cornerRadius: WidgetTheme.cornerRadiusSM)
                    .fill(batteryColor)
                    .frame(width: geo.size.width * CGFloat(percent) / 100)
            }
        }
        .frame(height: 8)
    }
    
    var batteryColor: Color {
        if isCharging { return WidgetTheme.primaryGreen }
        if percent <= 20 { return WidgetTheme.danger }
        if percent <= 50 { return WidgetTheme.warning }
        return Color.primary
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
                        .foregroundColor(WidgetTheme.accentCyan)
                    Text("Volt")
                        .font(.system(size: WidgetTheme.fontSizeCaption, weight: .regular))
                        .foregroundColor(WidgetTheme.textSecondary)
                }
                
                Text("\(entry.batteryPercent)%")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                
                BatteryGaugeView(percent: entry.batteryPercent, isCharging: entry.isCharging)
                    .frame(height: 10)
                
                if entry.isCharging {
                    Label("Charging", systemImage: "bolt.fill")
                        .font(.system(size: WidgetTheme.fontSizeCaption, weight: .regular))
                        .foregroundColor(WidgetTheme.primaryGreen)
                } else if let remaining = entry.timeRemaining {
                    Text(remaining + " remaining")
                        .font(.system(size: WidgetTheme.fontSizeCaption, weight: .regular))
                        .foregroundColor(WidgetTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("HEALTH")
                    .font(.system(size: WidgetTheme.fontSizeCaption2, weight: .regular))
                    .foregroundColor(WidgetTheme.textSecondary)
                
                Text("\(entry.healthPercent)%")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(healthColor)
                
                HealthRingView(percent: entry.healthPercent)
                
                Text("Battery health")
                    .font(.system(size: WidgetTheme.fontSizeCaption2, weight: .regular))
                    .foregroundColor(WidgetTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(WidgetTheme.cornerRadiusMD)
    }
    
    var healthColor: Color {
        if entry.healthPercent >= 80 { return WidgetTheme.primaryGreen }
        if entry.healthPercent >= 50 { return WidgetTheme.warning }
        return WidgetTheme.danger
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
        if percent >= 80 { return WidgetTheme.primaryGreen }
        if percent >= 50 { return WidgetTheme.warning }
        return WidgetTheme.danger
    }
}

// MARK: - Color Extension for Widget

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
