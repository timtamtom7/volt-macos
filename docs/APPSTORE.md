# Volt — App Store Submission Guide

## App Store Metadata

### Category
- **Primary Category:** Utilities
- **Secondary Category:** Health & Fitness (for battery tracking)

### Title
Volt — Battery Health Monitor

### Subtitle
Track & optimize your MacBook battery

### Description
Volt is a native macOS menu bar app that monitors your MacBook's battery health, tracks charge cycles, and provides AI-powered insights to extend battery longevity.

**Key Features:**
- Real-time battery monitoring with charge percentage, health status, and temperature
- Automatic charging session tracking with duration and capacity analysis
- AI-powered health predictions and optimization recommendations
- Configurable charging schedules with limit alerts
- Beautiful dark-mode interface with liquid glass design
- Widget support for your desktop
- REST API for automation integrations

**Why Volt?**
- No complicated setup — works automatically
- Privacy-focused — all data stays on your device
- Beautiful UI that matches macOS Sonoma
- Regular updates with new features

### Keywords
battery, health, monitor, macbook, charging, optimize, power, energy, cycle count, lifespan, utility

### Privacy Policy URL
Required - add your privacy policy hosted URL

### Marketing URL
Optional - volt.app (if you have a website)

### Support URL
Optional - for support inquiries

---

## Screenshots Required

### App Store Icon
- 1024×1024 PNG (will be auto-scaled)

### Mac Screenshots (all 16:9 aspect ratio)
- 1280×720 (small)
- 1440×900 (medium)
- 2560×1440 (large)
- 2880×1800 (extra large)

### Recommended Screenshots
1. **Main Battery View** - Showing charge %, health ring, temperature
2. **Charging History** - Heatmap or stats chart
3. **Settings** - Notification toggles
4. **Menu Bar** - Small compact view in menu bar
5. **Widget** - Desktop widget showing battery status

---

## Build for App Store

```bash
# Clean build
xcodebuild clean -scheme Volt -configuration Release

# Build for App Store
xcodebuild -scheme Volt -configuration Release \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  CODE_SIGN_TEAM_ID="YOUR_TEAM_ID" \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID" \
  build

# Create archive and upload
xcrun altool --upload-app -f ./build/Release/Volt.app -t osx -u "developer@email.com" -p "app-specific-password"
```

---

## TestFlight (Beta)

1. Create app in App Store Connect
2. Add beta testers under "TestFlight" tab
3. Upload build via Xcode or altool
4. Build must be code-signed with Development or Distribution certificate

---

## App Store Connect Checklist

- [ ] App name and subtitle finalized
- [ ] Description written (1700 char limit)
- [ ] Keywords (100 char limit)
- [ ] Privacy policy URL added
- [ ] App icon uploaded (1024×1024)
- [ ] Screenshots for all required sizes
- [ ] Build uploaded and processed
- [ ] Pricing and availability set
- [ ] Content rights completed
- [ ] Export Compliance Answered (if applicable)

---

## Common Rejection Reasons

1. **Missing privacy policy** - Required for all apps
2. **Insufficient beta testing** - Use TestFlight
3. **Crashes on launch** - Test thoroughly
4. **Sample code/template apps** - Must be unique
5. **Incomplete metadata** - All fields filled

---

## Version History

### 1.0.0 (Initial Release)
- Battery monitoring
- Charging session tracking
- Health predictions
- Charging schedules
- Widget support
- REST API
