# Volt — Brand Guide

## 1. Concept & Vision

Volt is a battery health companion that makes the invisible visible. It tracks charge cycles, monitors charging patterns, and helps users develop habits that extend battery longevity. The brand feels **precise, scientific, and empowering** — data-driven without being cold. Think of a high-end instrument panel: clean, purposeful, trustworthy.

**App type:** Menu bar utility (LSUIElement)
**Core function:** Battery health tracking, charging schedule, cycle count monitoring, and recommendations.

---

## 2. Icon Concept — "The Lightning Cell"

### Visual Description

A battery cell rendered as a clean, geometric shape with a lightning bolt inside. The bolt is the hero — it represents energy, speed, and the electrical nature of charging. The battery outline is rounded but precise, suggesting modern lithium-ion cells. The overall feel is **electric and energetic** but **clean and technical** — not cartoonish.

**Key elements:**
- **Shape:** A rounded rectangle resembling a battery cell (taller than wide, with a small positive terminal nub at the top)
- **Primary glyph:** A sharp lightning bolt centered within the battery, suggesting active charging
- **Fill:** A gradient from electric cyan to emerald green, representing energy flowing into the battery
- **Background:** Dark charcoal (`#1E1E2E`) — dark mode native, matches the app's data-dense aesthetic

### Color Palette

| Role | Hex | Usage |
|------|-----|-------|
| Background | `#1E1E2E` | Dark background |
| Surface | `#2A2A3E` | Card/panel backgrounds |
| Primary Accent | `#34C759` | Battery health, charged state |
| Energy Accent | `#00D4FF` | Charging, active energy, lightning bolt |
| Warning | `#FF9500` | Degrading health, recommendations |
| Danger | `#FF3B30` | Critical health, issues |
| Text Primary | `#FFFFFF` | Main text on dark |
| Text Secondary | `#8E8E93` | Labels, secondary info |

### Typography

- **Primary font:** SF Pro (system, clean and technical)
- **Headings:** SF Pro Medium, 15–17pt
- **Body:** SF Pro Text Regular, 12–13pt
- **Numbers/data:** SF Pro Rounded Medium (tabular figures for stats)
- **Fallback:** `.systemFont` with `design: .default`

### Visual Motif

**The Lightning Bolt** — energy flowing into a battery. The icon combines the universal battery symbol with the electric energy of a lightning bolt. The color gradient (cyan → green) tells the story: charging (cyan, energetic) → charged (green, healthy). The dark background reinforces that this is a tool that runs quietly, always monitoring.

### Icon at Different Sizes

| Size | Rendering |
|------|-----------|
| **16×16** | Small — battery outline with tiny lightning bolt, dark background. |
| **32×32** | Battery shape clearly visible, bolt inside, slight gradient hint. |
| **64×64** | Full battery cell with terminal nub, bold lightning bolt, gradient fill visible. |
| **128×128** | Gradient from cyan to green on the battery fill. Bolt is sharp and prominent. |
| **256×256** | Battery with subtle shine/reflection highlight at top-left. Drop shadow beneath. |
| **512×512** | Rich gradient, bolt with a subtle glow effect, faint circuit-line texture on battery body. |
| **1024×1024** | Full brand: dark charcoal background, large battery cell with gradient fill, bold lightning bolt with a soft cyan glow, small "health %" indicator or cycle count badge, polished shadows. |

---

## 3. Placeholder Icon (SwiftUI)

The placeholder icon renders the Volt brand concept as a SwiftUI view for preview. Place in `Volt/Views/AppIconView.swift`.

```swift
import SwiftUI

struct VoltAppIconView: View {
    var body: some View {
        VoltIconShape()
            .frame(width: 256, height: 256)
    }
}

struct VoltIconShape: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            ZStack {
                // Dark charcoal background
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(Color(hex: "1E1E2E"))

                // Battery body (rounded rect)
                VStack(spacing: 0) {
                    // Positive terminal nub
                    RoundedRectangle(cornerRadius: size * 0.02)
                        .fill(Color(hex: "34C759"))
                        .frame(width: size * 0.22, height: size * 0.04)
                        .offset(y: size * 0.01)

                    // Main battery body
                    RoundedRectangle(cornerRadius: size * 0.06)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "00D4FF"), Color(hex: "34C759")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.5, height: size * 0.55)
                        .overlay(
                            // Lightning bolt
                            ZStack {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: size * 0.28, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                    .shadow(color: Color(hex: "00D4FF").opacity(0.5), radius: size * 0.02)
                            }
                        )
                        .overlay(
                            // Battery shell outline
                            RoundedRectangle(cornerRadius: size * 0.06)
                                .stroke(Color.white.opacity(0.15), lineWidth: size * 0.01)
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
```

---

## 4. Secondary Icon Elements

- **Menu bar icon:** Small (18×18pt): battery outline with a tiny lightning bolt, dark background with subtle gradient. Charges to green when at 100%.
- **Tab/feature icons:** SF Symbols — `battery.100`, `bolt.fill`, `chart.line.uptrend.xyaxis`, `calendar`, `gearshape`
- **Health indicator:** Color-coded circle (green → orange → red) with percentage
- **Charging animation:** Lightning bolt pulses with a soft cyan glow

---

## 5. Spatial System

| Token | Value |
|-------|-------|
| Spacing XS | 4pt |
| Spacing SM | 8pt |
| Spacing MD | 12pt |
| Spacing LG | 16pt |
| Spacing XL | 24pt |
| Corner Radius SM | 4pt |
| Corner Radius MD | 8pt |
| Corner Radius LG | 12pt |
