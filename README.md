# SubTrackr

A native iOS app to track and manage your subscriptions.

## Features

- **Subscription Management** - Add, edit, delete, and archive subscriptions
- **Calendar View** - See all renewals in a monthly calendar
- **Category Organization** - Organize by Streaming, Software, Fitness, Gaming, and more
- **Currency Support** - 120+ currencies with automatic conversion
- **Budget Tracking** - Set monthly limits with spending alerts
- **iOS Widgets** - Track spending from your home screen
- **Live Activities** - Follow upcoming renewals from the Lock Screen and Dynamic Island
- **CloudKit Sync** - Automatic sync across your Apple devices

## Demo

<p>
  <img src="media/Simulator Screenshot - iPhone 16e - 2026-02-27 at 12.09.06.png" width="130">
  <img src="media/Simulator Screenshot - iPhone 16e - 2026-02-27 at 12.09.11.png" width="130">
  <img src="media/Simulator Screenshot - iPhone 16e - 2026-02-27 at 12.09.15.png" width="130">
  <img src="media/Simulator Screenshot - iPhone 16e - 2026-02-27 at 12.09.20.png" width="130">
  <img src="media/Simulator Screenshot - iPhone 16e - 2026-02-27 at 12.09.35.png" width="130">
  <img src="media/Simulator Screenshot - iPhone 16e - 2026-02-27 at 12.12.41.png" width="130">
  <img src="media/Simulator Screenshot - iPhone 16e - 2026-02-27 at 12.10.02.png" width="130">
  <img src="media/Simulator Screenshot - iPhone 16e - 2026-02-27 at 12.12.20.png" width="130">
  <img src="media/Simulator Screenshot - iPhone 16e - 2026-02-27 at 12.12.13.png" width="130">
  <img src="media/Simulator Screenshot - iPhone 16e - 2026-02-27 at 12.12.05.png" width="130">
  <img src="media/Simulator Screenshot - iPhone 16e - 2026-02-27 at 12.11.16.png" width="130">
</p>

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Apple Developer Account (for CloudKit)

### Live Activity Support

Live Activities and Dynamic Island support require:

- iOS 16.1+ for Live Activities
- iPhone 14 Pro or later for Dynamic Island presentation

## Setup

1. Clone the repository
2. Open `SubTrackr.xcodeproj` in Xcode
3. Configure signing with your Apple Developer account
4. Build and run on a simulator or device

### CloudKit

The app uses CloudKit container `iCloud.com.iden.SubTrackr`. Enable CloudKit in your Apple Developer account.

### Widgets

Configure App Groups capability with `group.com.iden.SubTrackr` for both main app and widget targets.

### Live Activities

Enable Live Activities in the app target and keep the widget extension included in the build. SubTrackr uses the widget extension to render renewal status on the Lock Screen and in the Dynamic Island.

## Usage

- Tap **+** to add a subscription
- Swipe left to delete, swipe right to edit
- Tap calendar dates to view renewals
- Long press home screen to add widgets
- Open a subscription row menu and choose **Start Live Activity** to pin the next renewal to the Lock Screen or Dynamic Island
- Change currency in Settings
