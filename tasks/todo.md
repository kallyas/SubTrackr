# Shared Subscription Redesign

## Plan

- [x] Audit the current shared subscription experience, data model, and persistence boundaries.
- [x] Define the target UX for shared subscriptions:
  - Clarify primary jobs to be done.
  - Decide single-subscription and multi-subscription states.
  - Decide what cost-sharing information is actionable.
- [x] Design a minimal data-model improvement that supports the redesigned UX without breaking existing stored subscriptions.
- [x] Implement the redesigned shared subscription screen and supporting UI components.
- [x] Implement any required model and persistence updates for shared subscription metadata.
- [x] Verify behavior:
  - Build the app and widget targets if touched.
  - Review the diff for scope and regressions.
  - Confirm existing stored `sharedWith` data remains decodable.
  - Confirm the redesigned screen handles empty, unshared, and already-shared states.

## Review

- Repositioned the feature from misleading "sharing" language toward honest local planning: people tracking plus split handling.
- Added `SharingBillingMode` and stored it on `Subscription` with a default fallback so existing CloudKit records continue to load as `splitEqually`.
- Rebuilt the screen around overview metrics, a local-only note, setup flow for unshared subscriptions, richer shared-subscription cards, editable people, and explicit billing-mode controls.
- Verified with `xcodebuild build -project SubTrackr.xcodeproj -scheme SubTrackr -configuration Debug -destination generic/platform=iOS`.
- Reviewed scope with `git diff --stat` and kept the change set focused to the shared-subscription screen plus the minimal supporting model updates.
