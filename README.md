# SubTrackr

A modern, native iOS subscription tracking app that helps you manage and monitor all your recurring subscriptions with CloudKit sync, iOS widgets, and comprehensive currency support.

## Features

### 📱 Core Functionality
- **Subscription Management**: Add, edit, and delete recurring subscriptions
- **Multiple Billing Cycles**: Support for weekly, monthly, quarterly, semi-annual, and annual billing
- **Cost Tracking**: Monitor monthly costs and total spending across all subscriptions
- **iOS Native Calendar**: Swipe-based calendar view matching Apple Calendar design
  - Swipe up/down to navigate months
  - Tiny colored dots for subscription events
  - Red circle for today's date
  - Month preview while swiping
- **Category Organization**: Organize subscriptions by categories (Streaming, Software, Fitness, Gaming, etc.)
- **Home Widgets**: Track subscriptions directly from your home screen
  - Small widget: Monthly total or next renewal
  - Medium widget: Overview with upcoming renewals
  - Large widget: Detailed subscription list

### 🌍 Global Currency Support
SubTrackr supports **120+ currencies** from around the world, including:
- **Major Currencies**: USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY
- **African Currencies**: UGX (Ugandan Shilling), TZS (Tanzanian Shilling), KES (Kenyan Shilling), NGN (Nigerian Naira), ZAR (South African Rand), and many more
- **Asian Currencies**: INR, KRW, THB, MYR, IDR, PHP, VND, and others
- **European Currencies**: SEK, NOK, PLN, CZK, HUF, RON, and more
- **Middle Eastern Currencies**: AED, SAR, QAR, ILS, TRY, and others
- **American Currencies**: BRL, MXN, CLP, ARS, COP, PEN, and others
- **Pacific & Caribbean**: FJD, PGK, BBD, JMD, and others

### ☁️ Cloud Features
- **CloudKit Integration**: Automatic sync across all your Apple devices
- **Offline Support**: Works offline with local data fallback
- **Real-time Updates**: Live sync when changes are made
- **Privacy Focused**: Your data stays in your iCloud account

### 💰 Currency Features
- **Multi-currency Support**: Track subscriptions in different currencies
- **Currency Conversion**: Convert amounts between currencies
- **Exchange Rate Updates**: Automatic exchange rate fetching
- **Localized Formatting**: Proper currency formatting for each region

## Technical Architecture

### Models
- **Subscription**: Core subscription model with CloudKit integration
- **Currency**: Comprehensive currency system with 120+ supported currencies
- **BillingCycle**: Flexible billing cycle management
- **SubscriptionCategory**: Categorization system with color coding

### Services
- **CloudKitService**: Manages CloudKit operations and sync
- **CurrencyExchangeService**: Handles currency conversion and exchange rates with caching
- **CurrencyManager**: App-wide currency management
- **WidgetDataManager**: Manages widget data sharing via App Groups
- **NotificationManager**: Handles subscription reminder notifications

### ViewModels
- **SubscriptionViewModel**: Manages subscription state and operations
- **CalendarViewModel**: Handles calendar view and date calculations

### Widget Extension
- **WidgetShared Framework**: Shared data types between app and widget
- **Provider**: Timeline provider for widget updates
- **Multiple Widget Sizes**: Small, Medium, and Large layouts
- **App Group Integration**: Shares data via `group.com.iden.SubTrackr`

## Setup & Installation

### Prerequisites
- iOS 15.0+
- Xcode 14.0+
- Apple Developer Account (for CloudKit)
- iCloud account (for sync features)

### Configuration

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/kallyas/SubTrackr.git
   cd SubTrackr
   ```

2. **CloudKit Setup**:
   - The app automatically creates the required CloudKit schema on first run
   - Ensure your Apple Developer account has CloudKit enabled
   - Container ID: `iCloud.com.iden.SubTrackr`

3. **App Groups Configuration** (Required for Widgets):
   - Open the project in Xcode
   - Select the **SubTrackr** target → Signing & Capabilities
   - Ensure "App Groups" capability is enabled with `group.com.iden.SubTrackr`
   - Select the **SubTrackrWidget** target → Signing & Capabilities
   - Add "App Groups" capability with the same `group.com.iden.SubTrackr`
   - Verify both targets have `SubTrackr.entitlements` and `SubTrackrWidget.entitlements` files

4. **Entitlements**:
   - CloudKit capability enabled
   - App Groups for widget data sharing
   - Background App Refresh for sync

5. **Currency Exchange**:
   - Exchange rates are fetched automatically from public APIs
   - Robust caching system with 24-hour expiry
   - Falls back gracefully if rates are unavailable

## Usage

### Adding a Subscription
1. Tap the "+" button to add a new subscription
2. Enter subscription details (name, cost, billing cycle)
3. Select currency and category
4. Choose an icon and set the start date
5. Save to sync across devices

### Managing Subscriptions
- **Edit**: Tap any subscription to modify details
- **Delete**: Swipe left or use edit mode
- **Toggle Active**: Enable/disable subscriptions without deleting

### Calendar View
- View all subscriptions on a monthly calendar
- See which subscriptions are due on specific dates
- Tap dates to see subscription details

### Currency Management
- Change app currency in Settings
- View costs in your preferred currency
- Automatic conversion between currencies

### Using Widgets
1. Long press on your home screen
2. Tap the "+" button to add a widget
3. Search for "SubTrackr"
4. Choose your preferred size (Small, Medium, or Large)
5. Tap "Add Widget"
6. Long press the widget to configure display options:
   - **Summary**: Shows monthly total and active subscription count
   - **Upcoming Renewals**: Displays next renewal with date and cost
   - **Total Spending**: Focuses on monthly spending overview

**Note**: Widgets automatically update when you add, edit, or delete subscriptions in the app.

## Architecture Details

### CloudKit Schema
The app uses a custom CloudKit record type `Subscription` with the following fields:
- `name` (String): Subscription name
- `cost` (Double): Subscription cost
- `currencyCode` (String): Currency code (e.g., "USD", "EUR")
- `billingCycle` (String): Billing frequency
- `startDate` (Date): Subscription start date
- `category` (String): Subscription category
- `iconName` (String): Icon identifier
- `isActive` (Bool): Active status

### Error Handling
- Graceful fallback to local data when CloudKit is unavailable
- Automatic retry mechanisms for failed operations
- User-friendly error messages

### Performance
- Efficient data loading with pagination
- Background sync to minimize UI blocking
- Optimized currency conversion caching
- Widget timeline updates every hour
- Haptic feedback for enhanced user experience

## Design System

SubTrackr uses a comprehensive design system for consistency across the app:

### DesignTokens
- **Colors**: Semantic color system with light/dark mode support
- **Typography**: Standardized text styles (title, headline, body, caption)
- **Spacing**: Consistent spacing scale (xs: 4, sm: 8, md: 12, lg: 16, xl: 20, xxl: 24)
- **Corner Radius**: Unified corner radius values (sm: 8, md: 12, lg: 16)
- **Shadows**: Elevation system for depth

### Components
- **EmptyStateView**: Reusable empty state with icon, title, and message
- **SpendingTrendsView**: Visual spending analytics
- **Custom Calendar**: iOS-native calendar design with gesture support

## Recent Improvements

### Version 2.0 - iOS Native Design
- Complete calendar redesign matching Apple Calendar
- Swipe-based month navigation with spring animations
- Widget support with three size options
- Enhanced currency exchange with robust caching
- Comprehensive design system implementation
- Improved error handling and offline support

## Contributing

### Code Style
- Follow Swift naming conventions
- Use SwiftUI for all UI components
- Implement proper error handling
- Add unit tests for new features

### Currency Support
To add a new currency:
1. Add the currency definition in `Currency.swift`
2. Add it to the `supportedCurrencies` array
3. Ensure proper symbol and formatting

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, feature requests, or questions:
- Create an issue on GitHub
- Check existing documentation
- Review CloudKit requirements

## Privacy

SubTrackr prioritizes user privacy:
- Data is stored in your personal iCloud account
- No data is sent to third-party servers
- Exchange rates are fetched from public APIs
- No analytics or tracking