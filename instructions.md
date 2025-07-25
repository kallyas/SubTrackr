Prompt for Creating SubTrackr iOS App
App Overview
Create an iOS app named SubTrackr, designed to help users manage and visualize their recurring subscriptions. The app uses a calendar interface to display active subscriptions for each day, with interactive features like tooltips, detailed panes, and a monthly spending overview. The app follows the Model-View-ViewModel (MVVM) architecture and uses iCloud for data storage and synchronization. It also includes a search functionality to find subscriptions easily.
Core Features

Calendar View:

Display a monthly calendar grid.
For each day, show icons representing active subscriptions (e.g., small logos or initials for services like Netflix, Spotify).
Use subtle animations for icons to indicate active status (e.g., slight pulse effect).
Support swipe gestures to navigate between months.


Tooltip on Hover:

On hover (or long press for touch), display a tooltip with brief subscription details (e.g., service name, amount, billing cycle).
Ensure tooltips are concise and visually distinct (e.g., semi-transparent background, rounded corners).


Details Pane on Click:

On tapping a day, show a detailed pane listing all subscriptions active on that day of the month.
Include details: service name, cost, billing cycle (e.g., monthly, yearly), start date, and next billing date.
Display the total cost for subscriptions on that day.
Provide an "Unsubscribe" button to remove a subscription (with confirmation dialog).
Allow editing subscription details (e.g., cost, billing cycle).


Monthly Overview:

Include a separate view (accessible via a tab or button) showing a monthly breakdown of subscription spending.
Display a list of all subscriptions, their costs, and a total monthly cost.
Visualize spending with a simple chart (e.g., pie chart or bar graph) to show cost distribution across subscriptions.
Allow filtering by month/year.


Search Functionality:

Add a search bar to find subscriptions by name or category (e.g., streaming, software, fitness).
Display search results in a list with key details (name, cost, next billing date).
Allow tapping a search result to jump to the corresponding day in the calendar or view full details.


iCloud Integration:

Store subscription data in iCloud to enable synchronization across the user’s devices.
Support CRUD operations (Create, Read, Update, Delete) for subscriptions in iCloud.
Ensure data is encrypted and complies with Apple’s iCloud security guidelines.
Handle offline scenarios with local caching and sync when online.



Technical Requirements

Platform: iOS (Swift, SwiftUI preferred for modern UI).
Architecture: Use MVVM pattern:
Model: Represent subscription data (e.g., Subscription struct with properties like id, name, cost, billingCycle, startDate).
View: SwiftUI views for calendar, tooltips, details pane, monthly overview, and search.
ViewModel: Manage business logic, data fetching, and iCloud interactions (e.g., CalendarViewModel, SubscriptionViewModel).


iCloud: Use CloudKit for storing and syncing subscription data.
UI/UX:
Follow iOS Human Interface Guidelines for intuitive design.
Use a clean, modern aesthetic with a focus on readability (e.g., San Francisco font, adaptive colors for light/dark mode).
Ensure accessibility (e.g., VoiceOver support, sufficient contrast).


Performance:
Optimize calendar rendering for smooth scrolling and loading.
Cache subscription data locally to reduce iCloud queries.


Error Handling:
Gracefully handle iCloud sync failures, network issues, and invalid user input.
Provide user-friendly error messages (e.g., “Failed to sync with iCloud. Please check your connection.”).



Additional Considerations

Onboarding: Include a brief tutorial or setup screen to guide users on adding their first subscription.
Categories: Allow users to categorize subscriptions (e.g., streaming, utilities) for better organization.
Notifications: Optionally, support reminders for upcoming subscription renewals (configurable by user).
Testing: Ensure unit tests for ViewModels and integration tests for iCloud syncing.

Example Workflow

User opens SubTrackr and sees the current month’s calendar.
Icons on each day indicate active subscriptions (e.g., Netflix on the 5th, Spotify on the 15th).
User long-presses the 5th, sees a tooltip with “Netflix: $13.99/month”.
User taps the 5th, opens a pane showing all subscriptions for that day, with a total cost and an option to unsubscribe.
User navigates to the monthly overview, sees a pie chart of spending (e.g., 40% streaming, 30% software).
User searches for “Netflix”, finds it, and jumps to the calendar day or edits its details.
Data syncs to iCloud, ensuring consistency across devices.

Deliverables

Full source code in Swift/SwiftUI, structured with MVVM.
Documentation for setup, architecture, and iCloud integration.
Sample subscription data for testing.
UI mockups or screenshots (optional but encouraged).

