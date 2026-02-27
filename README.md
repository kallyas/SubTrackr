# SubTrackr

A native iOS app to track and manage your subscriptions.

## Features

- **Subscription Management** - Add, edit, delete, and archive subscriptions
- **Calendar View** - See all renewals in a monthly calendar
- **Category Organization** - Organize by Streaming, Software, Fitness, Gaming, and more
- **Currency Support** - 120+ currencies with automatic conversion
- **Budget Tracking** - Set monthly limits with spending alerts
- **iOS Widgets** - Track spending from your home screen
- **CloudKit Sync** - Automatic sync across your Apple devices

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Apple Developer Account (for CloudKit)

## Setup

1. Clone the repository
2. Open `SubTrackr.xcodeproj` in Xcode
3. Configure signing with your Apple Developer account
4. Build and run on a simulator or device

### CloudKit

The app uses CloudKit container `iCloud.com.iden.SubTrackr`. Enable CloudKit in your Apple Developer account.

### Widgets

Configure App Groups capability with `group.com.iden.SubTrackr` for both main app and widget targets.

## Usage

- Tap **+** to add a subscription
- Swipe left to delete, swipe right to edit
- Tap calendar dates to view renewals
- Long press home screen to add widgets
- Change currency in Settings
