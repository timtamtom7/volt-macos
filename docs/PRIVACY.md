# Volt Privacy Policy

Last updated: April 2026

## Overview
Volt is a battery health monitoring application for macOS. This privacy policy explains how Volt collects, uses, and protects information.

## Data Collection

### Battery Information
Volt reads battery information directly from your Mac's System Management Controller (SMC) via IOKit. This includes:
- Current charge level
- Charging status
- Battery health percentage
- Cycle count
- Temperature

### Local Storage
All battery data collected by Volt is stored locally on your device:
- Charging session history
- Daily battery statistics
- Health snapshots
- User preferences

Volt does **not** collect, transmit, or store any of this data on external servers.

## Data Usage

The battery information collected is used solely to:
- Display real-time battery status in the menu bar
- Track charging session history
- Generate health predictions and recommendations
- Provide widget data (via App Groups, shared only with the Volt widget)

## Third-Party Services

Volt uses the following third-party services:
- **Apple IOKit** - For reading battery hardware information (on-device only)
- **SQLite.swift** - Local database library (all data stored locally)
- **CryptoKit** - For encrypting sensitive data in Keychain (iCloud Keychain)

## Data Sharing

Volt does not share any personal or battery data with:
- Third parties
- Advertisers
- Analytics services

## User Rights

You have full control over your data:
- **Delete data:** Use "Wipe All Data" in Settings to delete all stored data
- **Export data:** Export charging history as CSV
- **Reset:** Uninstalling Volt removes all local data

## Children Under 13

Volt is not directed to children under 13 years of age. We do not knowingly collect information from children under 13.

## Changes to This Policy

We may update this privacy policy from time to time. Any changes will be reflected on this page with an updated "Last updated" date.

## Contact

For privacy concerns, contact:
- Email: privacy@volt.app
- Website: volt.app/privacy

---

## Volt App Store Information (Required by Apple)

### Data Collection
- **Battery and power data:** Used for battery health monitoring (all stored locally)
- **Device usage data:** Not collected

### Privacy Classification (Apple App Store Connect)
- **Privacy Labels:** 
  - Battery/Battery Usage Information: Stored on device only
  - Contact Information: Not collected
  - Health Information: Not collected
  - Location: Not collected
  - Browsing History: Not collected

### App Tracking transparency
Volt does not track users across apps or websites.

### Encryption
Volt uses AES-256 encryption for sensitive data stored in Keychain.
