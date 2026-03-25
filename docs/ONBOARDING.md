# Volt — Onboarding Guide

Volt's onboarding is **brief, data-forward, and empowering**. It should feel like understanding your MacBook better — "Here's what's happening inside your battery, and here's how to keep it healthy." The flow consists of 4 screens.

**Tone:** Smart, encouraging, precise. "You're taking control of your battery health."

---

## Screen 1 — "Meet Volt"

**Concept illustration:** A dark-themed scene showing a MacBook battery with a subtle glow. A small lightning bolt icon pulses near the battery. Clean, minimal, technical.

**Headline:** "Your battery, in detail"

**Body:** "Volt monitors your MacBook's battery health, tracks charge cycles, and helps you develop charging habits that last."

**Primary CTA:** "Get Started →"

**Secondary:** "Skip"

**Visual elements:**
- Dark background (`#1E1E2E`)
- Electric cyan (`#00D4FF`) accent on the lightning bolt
- Battery icon with health percentage shown

---

## Screen 2 — "Charging Insights"

**Concept illustration:** A charging heatmap or timeline — showing typical charging patterns over a day/week. Shows when the user typically charges and for how long. Visual: a simple bar chart or heat grid in cyan/green.

**Headline:** "See how you charge"

**Body:** "Volt tracks your charging sessions automatically. You'll see patterns like peak charge times and how often you go from 20% to 80%."

**Key points (with icons):**
- ⚡ "Automatic session tracking — no setup needed"
- 📊 "Charging heatmap shows your weekly patterns"
- 🔋 "Optimal charge range: 20%–80%"

**Primary CTA:** "Continue →"

---

## Screen 3 — "Health That Matters"

**Concept illustration:** A battery health chart or gauge showing design capacity vs. current capacity. Shows cycle count. A small green checkmark suggests the battery is in good health.

**Headline:** "Know your battery's age"

**Body:** "Maximum capacity and cycle count tell the real story of your battery's health. Volt tracks both, with gentle alerts when something needs attention."

**Key points:**
- 📈 "Design vs. current capacity at a glance"
- 🔁 "Cycle count tracked over time"
- 🔔 "Get alerts when health dips below 80%"

**Primary CTA:** "Continue →"

---

## Screen 4 — "You're Powered Up"

**Concept illustration:** Volt icon in the menu bar (small battery+bolt), with a small checklist showing the features now active. Celebratory but not over the top — confident and clean.

**Headline:** "Volt is watching your battery"

**Body:** "Look for Volt in your menu bar. Click to see current charge, health status, and your charging schedule."

**Key callouts:**
- 🍎 "Find Volt in your menu bar — top right of your screen"
- ⚡ "Click to see real-time charge and health stats"
- ⏰ "Set a charging schedule in Settings"

**Primary CTA:** "Open Volt"

---

## Implementation Notes

- Show onboarding only on first launch (`UserDefaults` flag `hasSeenOnboarding`)
- Use `VStack` with page dots, swipe-able or tab-based
- Dark theme (`#1E1E2E` background) for all onboarding screens to match Volt's aesthetic
- All colors should come from `Theme.swift` (no hardcoded hex in UI code)
- Illustrations can use SwiftUI `Shape` + `Gradient` compositions
