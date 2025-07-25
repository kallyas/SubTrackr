# Testing Guide for SubTrackr

This document describes the comprehensive testing setup implemented for the SubTrackr iOS application.

## Overview

SubTrackr uses a multi-layered testing approach that includes:
- **Unit Tests**: Testing individual components and business logic
- **Integration Tests**: Testing component interactions
- **UI Tests**: Testing user interface and user flows
- **Performance Tests**: Testing app performance characteristics
- **CI/CD Pipeline**: Automated testing on every commit and pull request

## Test Structure

### Unit Tests (`SubTrackrTests/`)

#### Core Model Tests
- **SubscriptionModelTests**: Tests the `Subscription` struct including initialization, cost calculations, and date handling
- **BillingCycleTests**: Tests billing cycle enums and their conversion factors
- **SubscriptionCategoryTests**: Tests subscription categories and their properties
- **CurrencyTests**: Tests currency handling, formatting, and lookups

#### Service Layer Tests
- **CurrencyExchangeServiceTests**: Tests currency conversion functionality
- **CurrencyManagerTests**: Tests the currency management singleton
- **WidgetDataManagerTests**: Tests widget data persistence and retrieval

#### View Model Tests
- **SubscriptionViewModelTests**: Tests the main view model logic including filtering and calculations

#### Widget Tests
- **WidgetSubscriptionTests**: Tests widget-specific data structures
- **WidgetDataTests**: Tests widget data aggregation and formatting

### Integration Tests (`SubTrackrTests/IntegrationTests.swift`)

Tests how different components work together:
- Subscription to Widget data flow
- Currency conversion integration
- View model integration with services
- Data serialization/deserialization

### Performance Tests

- **Currency formatting performance**: Ensures formatting operations are fast
- **Subscription calculations**: Tests bulk calculation performance

### UI Tests (`SubTrackrUITests/`)

- **App launch tests**: Verifies the app starts correctly
- **Navigation flow tests**: Tests basic navigation
- **Performance metrics**: Memory and launch time measurements

## Running Tests

### Local Development

#### Run all tests:
```bash
xcodebuild -project SubTrackr.xcodeproj -scheme SubTrackr -destination 'platform=iOS Simulator,name=iPhone 16' test
```

#### Run only unit tests:
```bash
xcodebuild -project SubTrackr.xcodeproj -scheme SubTrackr -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:SubTrackrTests
```

#### Run only UI tests:
```bash
xcodebuild -project SubTrackr.xcodeproj -scheme SubTrackr -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:SubTrackrUITests
```

#### Generate code coverage:
```bash
xcodebuild -project SubTrackr.xcodeproj -scheme SubTrackr -destination 'platform=iOS Simulator,name=iPhone 16' -enableCodeCoverage YES test
```

### Using Xcode

1. Open `SubTrackr.xcodeproj` in Xcode
2. Press `Cmd+U` to run all tests
3. Use the Test Navigator to run specific test suites or individual tests
4. View code coverage in the Report Navigator after running tests with coverage enabled

## Continuous Integration

### GitHub Actions Workflows

#### 1. Main CI Pipeline (`.github/workflows/ci.yml`)
- Triggers on pushes to `main` and `develop` branches
- Runs full test suite with code coverage
- Builds archive for main branch
- Uploads test results and coverage reports

#### 2. Pull Request Checks (`.github/workflows/pr-checks.yml`)
- Triggers on all pull requests
- Runs SwiftLint for code quality
- Runs unit tests and UI tests separately
- Posts test results as PR comments

#### 3. Release Pipeline (`.github/workflows/release.yml`)
- Triggers on version tags (v*.*.*)
- Runs full test suite before release
- Creates GitHub releases with changelog
- Archives build artifacts

### Code Quality

#### SwiftLint Configuration (`.swiftlint.yml`)
- Enforces Swift coding standards
- Custom rules for print statements and force unwrapping
- Configured for the project structure
- Integrated into CI pipeline

## Test Coverage Goals

- **Unit Tests**: Aim for >90% code coverage on models and services
- **Integration Tests**: Cover all major component interactions
- **UI Tests**: Cover critical user flows and edge cases
- **Performance Tests**: Establish baseline performance metrics

## Adding New Tests

### For New Models
1. Create test struct in `SubTrackrTests.swift`
2. Test initialization, computed properties, and methods
3. Include edge cases and error conditions

### For New Services
1. Create separate test file (e.g., `NewServiceTests.swift`)
2. Test public interface and error handling
3. Mock dependencies where appropriate
4. Add integration tests for service interactions

### For New UI Features
1. Add UI tests for new screens/flows
2. Test accessibility and error states
3. Include performance tests for complex views

## Best Practices

### Unit Tests
- Use descriptive test names that explain what is being tested
- Follow Arrange-Act-Assert pattern
- Test both success and failure cases
- Keep tests independent and isolated

### Integration Tests
- Focus on component boundaries
- Test realistic scenarios
- Verify data flow between layers

### UI Tests
- Test from user's perspective
- Use accessibility identifiers for reliable element selection
- Test on different device sizes when relevant
- Keep UI tests focused and fast

### Performance Tests
- Set realistic performance expectations
- Test with representative data sizes
- Monitor performance trends over time

## Troubleshooting

### Common Issues

#### Simulator Not Found
- Update simulator names in test commands to match available devices
- Use `xcrun simctl list devices` to see available simulators

#### Tests Timing Out
- Increase timeout values for async operations
- Check for infinite loops or deadlocks
- Ensure proper cleanup in test teardown

#### Flaky Tests
- Add proper wait conditions for async operations
- Avoid hardcoded delays
- Check for race conditions

#### Coverage Issues
- Ensure test targets have access to source files
- Verify code coverage is enabled in scheme settings
- Check for untestable code that should be refactored

## Metrics and Reporting

The CI pipeline automatically:
- Generates code coverage reports
- Uploads test results to Codecov
- Creates test artifacts for debugging failures
- Posts coverage and test status to pull requests

Coverage reports can be viewed at:
- Xcode: Report Navigator after running tests
- GitHub: PR status checks and comments
- Codecov: Detailed coverage analysis and trends