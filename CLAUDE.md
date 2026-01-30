# BabyActivity - Codebase Documentation

## Overview

BabyActivity is an iOS app built with SwiftUI and SwiftData to help parents track their baby's daily activities. The app allows logging and visualizing sleep, feeding, diaper changes, solid food, tummy time, bath time, medicine, growth measurements, and developmental milestones.

## Project Structure

```
BabyActivity/
├── BabyActivity/
│   ├── BabyActivityApp.swift         # App entry point, ModelContainer setup with CloudKit
│   ├── Activity.swift                # Core activity model and ActivityKind enum
│   ├── Baby.swift                    # Baby profile model with family sharing support
│   ├── Growth.swift                  # Growth measurement model (weight, height, head)
│   ├── Milestone.swift               # Milestone model with photo attachment support
│   ├── CloudKitService.swift         # iCloud and CloudKit operations service
│   ├── DataController.swift          # Preview data, utilities, chart helpers, trends & analytics
│   ├── MainView.swift                # Tab-based navigation container
│   ├── DashboardView.swift           # iOS Health-style dashboard with trends and highlights
│   ├── ContentView.swift             # Activity list with quick-add buttons
│   ├── ActivityListItemView.swift    # List item display component (with contributor info)
│   ├── EditActivityView.swift        # Activity detail editor with forms
│   ├── SummaryView.swift             # Summary navigation hub
│   ├── BabyProfileView.swift         # Baby profile management view
│   ├── FamilySharingView.swift       # Family sharing and permissions management
│   ├── SleepSummaryView.swift        # Sleep analytics with chart
│   ├── MilkSummaryView.swift         # Milk/feeding analytics with charts
│   ├── DiaperSummaryView.swift       # Diaper analytics with charts
│   ├── TummyTimeSummaryView.swift    # Tummy time duration tracking and goals
│   ├── SolidFoodSummaryView.swift    # Solid food tracking with allergen monitoring
│   ├── MedicineSummaryView.swift     # Medicine tracking with dosage history
│   ├── GrowthSummaryView.swift       # Growth measurements with charts
│   ├── MilestoneSummaryView.swift    # Developmental milestones with photos
│   └── BabyActivity.entitlements     # App entitlements (iCloud, CloudKit)
├── BabyActivityTests/                # Unit tests
└── BabyActivityUITests/              # UI tests
```

## Architecture

- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData (iOS 17+) with CloudKit sync
- **Cloud Sync**: CloudKit for iCloud sync and family sharing
- **Charts**: Apple Charts framework
- **Pattern**: MVVM-like with SwiftUI's declarative approach
- **External Dependencies**: None (100% native Apple frameworks)

## Data Model

### Activity (`Activity.swift`)

The core model using SwiftData's `@Model` macro:

```swift
@Model
final class Activity {
    var timestamp: Date           // Start time of activity
    var kind: ActivityKind        // Type of activity
    var endTimestamp: Date?       // End time (for sleep/milk/tummyTime)
    var amount: Int?              // Amount in ml (for milk)
    var foodType: String?         // Food type (for solidFood)
    var reactions: String?        // Allergen reactions (for solidFood)
    var medicineName: String?     // Medicine name (for medicine)
    var dosage: String?           // Dosage (for medicine)
    var notes: String?            // General notes

    // iCloud sync and family sharing fields
    var contributorId: String?    // iCloud user identifier who logged this
    var contributorName: String?  // Display name of contributor
    var lastModified: Date?       // For sync conflict resolution
    var baby: Baby?               // Relationship to Baby profile
}
```

### ActivityKind (`Activity.swift:11-20`)

```swift
public enum ActivityKind: String, Equatable, Sendable, Codable, CaseIterable {
    case sleep
    case milk
    case wetDiaper
    case dirtyDiaper
    case solidFood      // Solid food/meals with allergen tracking
    case tummyTime      // Tummy time with duration
    case bathTime       // Simple timestamp logging
    case medicine       // Medicine/vitamins with dosage
}
```

### GrowthMeasurement (`Growth.swift`)

```swift
@Model
final class GrowthMeasurement {
    var timestamp: Date
    var measurementType: GrowthMeasurementType  // .weight, .height, .headCircumference
    var value: Double      // Weight in kg, height/head in cm
    var notes: String?
}
```

### Milestone (`Milestone.swift`)

```swift
@Model
final class Milestone {
    var timestamp: Date
    var milestoneType: MilestoneType  // .firstSmile, .rollOver, .crawl, etc.
    var customTitle: String?          // For custom milestones
    var notes: String?
    var photoData: Data?              // Photo attachment

    // iCloud sync and family sharing fields
    var contributorId: String?        // iCloud user identifier who logged this
    var contributorName: String?      // Display name of contributor
    var lastModified: Date?           // For sync conflict resolution
    var baby: Baby?                   // Relationship to Baby profile
}
```

### Baby (`Baby.swift`)

Baby profile model with family sharing support:

```swift
@Model
final class Baby {
    var id: UUID
    var name: String
    var birthDate: Date
    var photoData: Data?
    var createdDate: Date
    var lastModified: Date
    var ownerCloudKitID: String?      // iCloud ID of the profile creator

    var sharedWith: [FamilyMember]    // Family members with access
    var activities: [Activity]         // Related activities
    var growthMeasurements: [GrowthMeasurement]
    var milestones: [Milestone]
}
```

### FamilyMember (`Baby.swift`)

Represents a family member with access to a baby's data:

```swift
@Model
final class FamilyMember {
    var id: UUID
    var cloudKitUserID: String        // iCloud user identifier
    var displayName: String
    var permission: PermissionLevel   // admin, caregiver, or viewer
    var addedDate: Date
    var lastSyncDate: Date?
    var baby: Baby?                   // Inverse relationship
}
```

### PermissionLevel (`Baby.swift`)

```swift
public enum PermissionLevel: String, Codable, CaseIterable {
    case admin       // Full access, manage members
    case caregiver   // Add/edit activities
    case viewer      // Read-only access
}
```

## Current Features

### Implemented

1. **Activity Logging** - Quick-add buttons for all 8 activity types (sleep, milk, diapers, solid food, tummy time, bath, medicine)
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
16. **Solid Food Tracking** - Food type logging, allergen reaction tracking, foods introduced list
17. **Tummy Time Tracking** - Duration tracking with daily goals (30 min target), session counts
18. **Bath Time Logging** - Simple timestamp-based bath time logging
19. **Medicine Tracking** - Medicine name, dosage tracking, dose history
20. **Growth Measurements** - Weight (kg), height (cm), head circumference tracking with charts
21. **Milestone Tracking** - 16 common milestones with expected age ranges, photo attachment support
22. **iCloud Sync** - CloudKit-backed data store for automatic sync across devices
23. **Baby Profiles** - Create and manage multiple baby profiles with age display
24. **Family Sharing** - Share baby data with family members via iCloud
25. **Permission Levels** - Admin, Caregiver, and Viewer access levels for family members
26. **Contributor Attribution** - Track who logged each activity with contributor name display

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
| `ContentView` | Activity list | Quick-add buttons (2 rows), list with navigation |
| `ActivityListItemView` | List item | Icon, description, relative timestamp, contributor name |
| `EditActivityView` | Detail editor | Dynamic forms based on ActivityKind |
| `SummaryView` | Analytics hub | Organized sections: Profile, Core Activities, Development, Health |
| `BabyProfileView` | Profile management | Create/edit baby profiles, photo upload, family sharing access |
| `FamilySharingView` | Family sharing | Invite members, manage permissions, view iCloud status |
| `SleepSummaryView` | Sleep analytics | Bar chart, day/night breakdown, longest stretch, quality badges |
| `MilkSummaryView` | Milk analytics | Daily intake chart, feeding frequency, interval analysis |
| `DiaperSummaryView` | Diaper analytics | Stacked bar chart (wet/dirty), hourly pattern distribution |
| `TummyTimeSummaryView` | Tummy time | Daily goal progress (30 min), duration chart, session count |
| `SolidFoodSummaryView` | Food tracking | Foods introduced grid, reaction alerts, daily meals chart |
| `MedicineSummaryView` | Medicine tracking | Active medicines list, daily doses chart, dose history |
| `GrowthSummaryView` | Growth charts | Weight/height/head charts, add measurement sheet |
| `MilestoneSummaryView` | Milestones | Achievement timeline, photo cards, add milestone sheet |

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
- Solid Food: `fork.knife`
- Tummy Time: `figure.child`
- Bath Time: `bathtub.fill`
- Medicine: `cross.case.fill`
- Weight: `scalemass.fill`
- Height: `ruler.fill`
- Head Circumference: `circle.dashed`

## SwiftData Configuration

### Production (`BabyActivityApp.swift:13-24`)

```swift
// CloudKit-backed store for iCloud sync
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .automatic
)
```

### Preview (`DataController.swift:13-26`)

```swift
let config = ModelConfiguration(isStoredInMemoryOnly: true)
```

## CloudKit & iCloud Setup

### Entitlements (`BabyActivity.entitlements`)

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.$(CFBundleIdentifier)</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

### CloudKitService (`CloudKitService.swift`)

Singleton service for iCloud operations:

| Function | Purpose |
|----------|---------|
| `checkAccountStatus()` | Verifies iCloud sign-in status |
| `fetchCurrentUserInfo()` | Gets current user's ID and name |
| `createShare()` | Creates CKShare for baby profile sharing |
| `discoverUsers()` | Looks up users by email for invitations |
| `monitorSyncStatus()` | Monitors account changes |

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
| `ActivityKindTests` | Description, raw values, all 8 activity types |
| `MilkAnalyticsTests` | `milkDataByDay`, `averageMilkPerFeeding`, `feedingIntervals`, etc. |
| `DiaperAnalyticsTests` | `diaperDataByDay`, `diaperDataByHour`, `averageDiapersPerDay` |
| `EnhancedSleepAnalyticsTests` | `longestSleepStretch`, `dayNightSleepBreakdown`, `sleepTrendData` |
| `DashboardTrendsTests` | `calculateTrend`, trend directions, `activityHeatMapData`, `dailyActivitySummaries`, `todaySummary`, `generateHighlights` |
| `HeatMapDataTests` | `HourlyActivityData` ID uniqueness and format |
| `TrendComparisonTests` | `TrendComparison` structure values |
| `DailyActivitySummaryTests` | `DailyActivitySummary` structure values and ID |
| `ExtendedActivityTypesTests` | Solid food, tummy time, bath time, medicine initialization and display |
| `TummyTimeAnalyticsTests` | `tummyTimeDataByDay`, `averageTummyTimePerDay` |
| `SolidFoodAnalyticsTests` | `solidFoodDataByDay`, `uniqueFoodsIntroduced`, `foodsWithReactions` |
| `MedicineAnalyticsTests` | `medicineDataByDay`, `uniqueMedicines` |
| `GrowthMeasurementTests` | Initialization, display, validation for all measurement types |
| `MilestoneTests` | Initialization, title, icons, age calculations, expected range |
| `PermissionLevelTests` | Description, icon, raw values for all permission levels |
| `FamilyMemberTests` | Initialization, canEdit, canManageMembers for each permission |
| `BabyModelTests` | Initialization, age calculations, validation, family sharing methods |
| `ActivityContributorTests` | Contributor fields initialization and defaults |
| `GrowthMeasurementContributorTests` | Contributor fields initialization and defaults |
| `MilestoneContributorTests` | Contributor fields initialization and defaults |

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

- Push notifications / reminders
- AI-based predictions
- Data export/import
- Widget support
- Apple Watch companion

## Code Conventions

- SwiftUI views use `@Environment(\.modelContext)` for data access
- Preview data generated via `DataController.simulatedActivities`
- Relative timestamps preferred in list views
- Dynamic forms adapt UI based on `ActivityKind`
