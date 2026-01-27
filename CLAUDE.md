# BabyActivity - Codebase Documentation

## Overview

BabyActivity is an iOS app built with SwiftUI and SwiftData to help parents track their baby's daily activities. The app allows logging and visualizing sleep, feeding, and diaper changes.

## Project Structure

```
BabyActivity/
├── BabyActivity/
│   ├── BabyActivityApp.swift      # App entry point, ModelContainer setup
│   ├── Activity.swift             # Core data model and ActivityKind enum
│   ├── DataController.swift       # Preview data, utilities, and chart helpers
│   ├── MainView.swift             # Tab-based navigation container
│   ├── ContentView.swift          # Activity list with quick-add buttons
│   ├── ActivityListItemView.swift # List item display component
│   ├── EditActivityView.swift     # Activity detail editor with forms
│   ├── SummaryView.swift          # Summary navigation hub
│   ├── SleepSummaryView.swift     # Sleep analytics with chart
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
4. **Tab Navigation** - Activities and Summary tabs
5. **Sleep Charts** - Bar chart visualization with day/week/month views
6. **Average Calculations** - Average sleep duration per day
7. **Sample Data** - Pre-populated demo data for testing

### Partially Implemented

- Milk summary view (placeholder)
- Diaper summary view (placeholder)

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

## UI Components

| View | Purpose | Key Features |
|------|---------|--------------|
| `MainView` | Tab container | Activities, Summary tabs |
| `ContentView` | Activity list | Quick-add buttons, list with navigation |
| `ActivityListItemView` | List item | Icon, description, relative timestamp |
| `EditActivityView` | Detail editor | Dynamic forms based on ActivityKind |
| `SummaryView` | Analytics hub | Navigation to detailed summaries |
| `SleepSummaryView` | Sleep analytics | Bar chart, time range picker, averages |

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
- Uses Swift Testing framework
- Comprehensive tests for:
  - DataController utilities (`sliceDataToPlot`, `averageDurationPerDay`, `mean`)
  - Activity model validation
  - ActivityKind enum

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
