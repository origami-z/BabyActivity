# BabyActivity - Codebase Documentation

## Overview

BabyActivity is an iOS app built with SwiftUI and SwiftData to help parents track their baby's daily activities. The app allows logging and visualizing sleep, feeding, and diaper changes.

## Project Structure

```
BabyActivity/
├── BabyActivity/
│   ├── BabyActivityApp.swift      # App entry point, ModelContainer setup
│   ├── Activity.swift             # Core data model and ActivityKind enum
│   ├── DataController.swift       # Preview data, utilities, chart helpers, trends & dashboard analytics
│   ├── MainView.swift             # Tab-based navigation container
│   ├── DashboardView.swift        # iOS Health-style dashboard with trends and highlights
│   ├── ContentView.swift          # Activity list with quick-add buttons
│   ├── ActivityListItemView.swift # List item display component
│   ├── EditActivityView.swift     # Activity detail editor with forms
│   ├── SummaryView.swift          # Summary navigation hub
│   ├── SleepSummaryView.swift     # Sleep analytics with chart
│   ├── MilkSummaryView.swift      # Milk/feeding analytics with charts
│   ├── DiaperSummaryView.swift    # Diaper analytics with charts
│   └── BabyActivity.entitlements  # App entitlements
├── BabyActivityTests/             # Unit tests
└── BabyActivityUITests/           # UI tests
```

## Architecture

- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData (iOS 17+)
- **Charts**: Apple Charts framework
- **Pattern**: MVVM-like with SwiftUI's declarative approach
- **External Dependencies**: None (100% native Apple frameworks)

## Data Model

### Activity (`Activity.swift:32-62`)

The core model using SwiftData's `@Model` macro:

```swift
@Model
final class Activity {
    var timestamp: Date           // Start time of activity
    var kind: ActivityKind        // Type of activity
    var endTimestamp: Date?       // End time (for sleep/milk)
    var amount: Int?              // Amount in ml (for milk)
}
```

### ActivityKind (`Activity.swift:11-16`)

```swift
public enum ActivityKind: String, Equatable, Sendable, Codable {
    case sleep
    case milk
    case wetDiaper
    case dirtyDiaper
}
```

## Current Features

### Implemented

1. **Activity Logging** - Quick-add buttons for all 4 activity types
2. **Activity List** - Chronological list with swipe-to-delete
3. **Activity Editing** - Full CRUD with dynamic forms per activity type
4. **Tab Navigation** - Dashboard, Activities, and Summary tabs
5. **Sleep Analytics** - Bar chart visualization, day/night breakdown, longest stretch, quality indicators
6. **Milk Analytics** - Daily intake charts, average per feeding, feeding intervals
7. **Diaper Analytics** - Daily counts (wet vs dirty stacked bar), time-of-day patterns
8. **Average Calculations** - Average durations and counts per day
9. **Sample Data** - Pre-populated demo data for testing
10. **iOS Health-Style Dashboard** - Today's summary with trend indicators, interactive charts, heat map, highlights
11. **Trend Analysis** - Week-over-week comparison for sleep, milk, and diapers with percentage change
12. **Interactive Line Charts** - Tap to select data points, smooth animations, Catmull-Rom interpolation
13. **Activity Heat Map** - Visual pattern display by hour and day of week
14. **Smart Highlights** - Automatic detection of notable patterns (long sleep, consistent feeding, good hydration)
15. **Accessibility Support** - VoiceOver labels, Dynamic Type, accessibility hints

### Known Issues

None currently.

## Key Components

### DynamicQuery (`SleepSummaryView.swift:43-58`)

Custom wrapper for SwiftData's `@Query` that supports dynamic fetch descriptors:

```swift
struct DynamicQuery<Element: PersistentModel, Content: View>: View {
    let descriptor: FetchDescriptor<Element>
    let content: ([Element]) -> Content
    @Query var items: [Element]
}
```

### PlotDuration (`DataController.swift:104-108`)

Helper struct for chart visualization:

```swift
struct PlotDuration: Identifiable {
    var start: Date
    var end: Date
    var id: UUID
}
```

### Cross-Midnight Handling (`DataController.swift:72-88`)

`sliceDataToPlot()` splits activities that span midnight into separate entries for accurate daily visualization.

### Dashboard & Trends Data Structures (`DataController.swift`)

```swift
/// Week-over-week trend comparison
struct TrendComparison {
    var currentValue: Double
    var previousValue: Double
    var percentageChange: Double
    var trend: TrendDirection  // .up, .down, .stable
}

/// Notable patterns detected automatically
struct ActivityHighlight: Identifiable {
    var title: String
    var description: String
    var icon: String
    var color: Color
    var priority: Int
}

/// Activity data by hour/day for heat map
struct HourlyActivityData: Identifiable {
    var hour: Int
    var dayOfWeek: Int  // 1-7
    var count: Int
    var kind: ActivityKind?
}

/// Daily totals for dashboard
struct DailyActivitySummary: Identifiable {
    var date: Date
    var sleepMinutes: Double
    var milkAmount: Int
    var feedingCount: Int
    var diaperCount: Int
}
```

### Dashboard Helper Functions

| Function | Purpose |
|----------|---------|
| `calculateTrend()` | Compares current vs previous values, returns trend direction |
| `sleepTrend()` | Week-over-week sleep comparison |
| `milkTrend()` | Week-over-week milk intake comparison |
| `diaperTrend()` | Week-over-week diaper count comparison |
| `generateHighlights()` | Detects notable patterns (long sleep, consistency, hydration) |
| `activityHeatMapData()` | Groups activities by hour and day of week |
| `dailyActivitySummaries()` | Aggregates all activity types by day |
| `todaySummary()` | Returns today's aggregated summary |

## UI Components

| View | Purpose | Key Features |
|------|---------|--------------|
| `MainView` | Tab container | Dashboard, Activities, Summary tabs |
| `DashboardView` | Health-style dashboard | Today's summary, trend charts, heat map, highlights |
| `ContentView` | Activity list | Quick-add buttons, list with navigation |
| `ActivityListItemView` | List item | Icon, description, relative timestamp |
| `EditActivityView` | Detail editor | Dynamic forms based on ActivityKind |
| `SummaryView` | Analytics hub | Navigation to detailed summaries |
| `SleepSummaryView` | Sleep analytics | Bar chart, day/night breakdown, longest stretch, quality badges |
| `MilkSummaryView` | Milk analytics | Daily intake chart, feeding frequency, interval analysis |
| `DiaperSummaryView` | Diaper analytics | Stacked bar chart (wet/dirty), hourly pattern distribution |

### Dashboard Components (`DashboardView.swift`)

| Component | Purpose |
|-----------|---------|
| `TrendStatCard` | Stat card with trend indicator (up/down/stable) |
| `TrendIndicator` | Visual trend badge with percentage |
| `InteractiveLineChart` | Line chart with tap-to-select and animations |
| `CombinedActivityChart` | Bar chart showing feedings and diapers side-by-side |
| `ActivityHeatMap` | Grid visualization of activity patterns by hour/day |
| `HighlightCard` | Card displaying notable pattern highlights |
| `QuickStatRow` | Compact stat row for weekly summaries |

## SF Symbols Used

- Sleep: `zzz`
- Milk: `cup.and.saucer.fill`
- Wet Diaper: `toilet`
- Dirty Diaper: `tornado`

## SwiftData Configuration

### Production (`BabyActivityApp.swift:13-24`)

```swift
let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
```

### Preview (`DataController.swift:13-26`)

```swift
let config = ModelConfiguration(isStoredInMemoryOnly: true)
```

## Date/Time Utilities

- `RelativeDateTimeFormatter` - For "2h ago" style timestamps
- `DateComponentsFormatter` - For duration display ("1h 30m")
- `Duration` formatting - For average time display

## Testing

- Unit tests in `BabyActivityTests/`
- UI tests in `BabyActivityUITests/`
- Uses Swift Testing framework with `@Test` attribute
- DataController methods require `@MainActor` annotation in tests

### Test Coverage

| Test Suite | Coverage |
|------------|----------|
| `DataControllerTests` | `sliceDataToPlot`, `averageDurationPerDay`, `mean` |
| `ActivityModelTests` | Initialization, validation, display, images |
| `ActivityKindTests` | Description, raw values |
| `MilkAnalyticsTests` | `milkDataByDay`, `averageMilkPerFeeding`, `feedingIntervals`, etc. |
| `DiaperAnalyticsTests` | `diaperDataByDay`, `diaperDataByHour`, `averageDiapersPerDay` |
| `EnhancedSleepAnalyticsTests` | `longestSleepStretch`, `dayNightSleepBreakdown`, `sleepTrendData` |
| `DashboardTrendsTests` | `calculateTrend`, trend directions, `activityHeatMapData`, `dailyActivitySummaries`, `todaySummary`, `generateHighlights` |
| `HeatMapDataTests` | `HourlyActivityData` ID uniqueness and format |
| `TrendComparisonTests` | `TrendComparison` structure values |
| `DailyActivitySummaryTests` | `DailyActivitySummary` structure values and ID |

### Testing Requirements

**IMPORTANT: All new features MUST include corresponding unit tests.**

When adding new functionality:
1. Add unit tests for any new `DataController` helper functions
2. Test edge cases: empty input, single item, multiple items, boundary conditions
3. Test filtering logic when functions filter by `ActivityKind`
4. Use `@MainActor` annotation for test structs that call `DataController` methods
5. Follow existing test naming convention: `functionName_scenario_expectedBehavior`

Example test structure:
```swift
@MainActor
struct NewFeatureTests {
    @Test func newFunction_emptyInput_returnsEmpty() {
        let result = DataController.newFunction([])
        #expect(result.isEmpty)
    }

    @Test func newFunction_validInput_calculatesCorrectly() {
        // Test with valid data
    }
}
```

## Input Validation

The Activity model includes validation for:
- **Time range validation**: `endTimestamp` must be after `timestamp` for activities with duration
- **Milk amount validation**: Amount must be between 0 and 500ml
- Validation errors are displayed in the EditActivityView

## Deployment

- **Minimum iOS**: 18.0 (upgraded for latest Swift features)
- **Minimum macOS**: 15.0
- **Platforms**: iPhone and iPad
- **Orientations**: Portrait and Landscape supported

## Not Yet Implemented

- iCloud sync / CloudKit integration
- Data sharing between family members
- Push notifications / reminders
- AI-based predictions
- Data export/import
- Multiple baby profiles
- Widget support
- Apple Watch companion

## Code Conventions

- SwiftUI views use `@Environment(\.modelContext)` for data access
- Preview data generated via `DataController.simulatedActivities`
- Relative timestamps preferred in list views
- Dynamic forms adapt UI based on `ActivityKind`
