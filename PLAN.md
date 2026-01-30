# BabyActivity - Development Plan

## Executive Summary

This document outlines the roadmap for improving BabyActivity from its current MVP state to a full-featured baby tracking app with iOS Health-style charts, iCloud family sharing, and AI-powered reminders.

---

## Phase 1: Code Quality & Bug Fixes

**Priority: High | Effort: Low**

### 1.1 Fix Known Bugs

- [ ] **Fix average calculation bug** (`SleepSummaryView.swift:94`)
  - Issue: Average "day" calculation incorrectly includes activities spanning 2 days
  - Solution: Use `sliceDataToPlot()` result's grouped days for accurate counting

- [ ] **Fix milk icon** (`Activity.swift:75`)
  - Current: `backpack.circle` (not intuitive)
  - Suggested: `cup.and.saucer.fill` or custom bottle icon

### 1.2 Code Improvements

- [ ] **Extract reusable chart components**
  - Create `ActivityChartView` protocol for consistent chart styling
  - Reuse date range picker across summary views

- [ ] **Improve error handling**
  - Add proper error states for data loading
  - Handle edge cases (no data, corrupted data)

- [ ] **Add input validation**
  - Ensure `endTimestamp` > `timestamp` for sleep/milk
  - Validate milk amount range (0-500ml reasonable range)

### 1.3 Testing

- [ ] Add unit tests for `DataController` utilities
- [ ] Add unit tests for `Activity` model
- [ ] Add UI tests for critical user flows

---

## Phase 2: Complete Activity Analytics

**Priority: High | Effort: Medium**

### 2.1 Milk Summary View

- [ ] Create `MilkSummaryView.swift`
  - Daily total intake chart (bar chart)
  - Average intake per feeding
  - Feeding frequency trends
  - Time between feedings analysis

### 2.2 Diaper Summary View

- [ ] Create `DiaperSummaryView.swift`
  - Daily count chart (wet vs dirty stacked bar)
  - Pattern recognition (time of day distribution)
  - Weekly/monthly trends

### 2.3 Enhanced Sleep Analytics

- [ ] Add sleep quality indicators
- [ ] Show longest stretch of sleep
- [ ] Day vs night sleep breakdown
- [ ] Sleep regression detection

---

## Phase 3: iOS Health-Style Charts ✅ COMPLETED

**Priority: High | Effort: Medium**

### 3.1 Chart Improvements

- [x] **Implement interactive charts**
  - Tap to show detailed data point
  - Pinch to zoom on time range
  - Scroll through historical data

- [x] **Add chart types**
  - Line charts for trends over time
  - Pie charts for daily activity breakdown
  - Heat maps for activity patterns by hour/day

### 3.2 Dashboard View

- [x] Create unified dashboard similar to iOS Health app
  - Today's summary cards
  - Quick stats (total sleep, feedings, diapers)
  - Trends indicators (up/down arrows)
  - "Highlights" section for notable patterns

### 3.3 Visual Design

- [x] Match iOS Health app aesthetics
  - Consistent color palette per activity type
  - Smooth animations and transitions
  - Accessibility support (Dynamic Type, VoiceOver)

---

## Phase 4: Extended Activity Types ✅ COMPLETED

**Priority: Medium | Effort: Medium**

### 4.1 New Activity Types

- [x] **Solid Food/Meals**
  - Track food type and reactions
  - Allergen tracking with foods with reactions list
  - Daily meals chart and foods introduced grid

- [x] **Tummy Time**
  - Duration tracking with daily goals (30 min target)
  - Session counts per day with charts

- [x] **Bath Time**
  - Simple timestamp logging with notes

- [x] **Medicine/Vitamins**
  - Dosage tracking with medicine name, dosage fields
  - Active medicines list and dose history

- [x] **Growth Measurements**
  - Weight (kg), height (cm), head circumference (cm)
  - Line charts showing progress over time
  - Change indicators from previous measurement

- [x] **Milestones**
  - 16 predefined milestones with expected age ranges
  - Photo attachment support via PhotosPicker
  - Custom milestone support

### 4.2 Activity Customization

- [ ] Allow users to create custom activity types (future)
- [ ] Custom icons and colors (future)
- [ ] Custom fields per activity type (future)

---

## Phase 5: iCloud & Family Sharing ✅ COMPLETED

**Priority: High | Effort: High**

### 5.1 iCloud Sync Setup

- [x] **Enable CloudKit**
  - Added iCloud capability to entitlements
  - Configured CloudKit container
  - Migrated SwiftData to use CloudKit-backed store

```swift
// CloudKit-backed configuration
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .automatic
)
```

### 5.2 Multi-Device Sync

- [x] Automatic sync across user's devices via CloudKit
- [x] Conflict resolution via `lastModified` timestamp on all models
- [x] Offline support with automatic sync when connected (CloudKit handles this)

### 5.3 Family Sharing

- [x] **Created FamilyMember model and sharing views**
  - BabyProfileView for managing baby profiles
  - FamilySharingView for inviting family members
  - CloudSyncStatusView for displaying iCloud status

- [x] **Permission levels (PermissionLevel enum)**
  - Admin: Full access, manage members
  - Caregiver: Add/edit activities
  - Viewer: Read-only access

- [x] **Activity attribution**
  - All models have contributorId and contributorName fields
  - ActivityListItemView shows contributor names
  - CloudKitService provides current user info

### 5.4 Data Model Updates

```swift
@Model
final class Activity {
    // Existing fields...
    var contributorId: String?      // iCloud user identifier
    var contributorName: String?    // Display name
    var lastModified: Date?         // For sync conflict resolution
    var baby: Baby?                 // Relationship to Baby profile
}

@Model
final class Baby {
    var id: UUID
    var name: String
    var birthDate: Date
    var photoData: Data?
    var ownerCloudKitID: String?    // Creator's iCloud ID
    var sharedWith: [FamilyMember]  // Family members with access
    var activities: [Activity]
    var growthMeasurements: [GrowthMeasurement]
    var milestones: [Milestone]
}

@Model
final class FamilyMember {
    var id: UUID
    var cloudKitUserID: String
    var displayName: String
    var permission: PermissionLevel
    var addedDate: Date
    var lastSyncDate: Date?
}

enum PermissionLevel: String, Codable, CaseIterable {
    case admin       // Full access, manage members
    case caregiver   // Add/edit activities
    case viewer      // Read-only access
}
```

---

## Phase 6: AI-Powered Smart Reminders

**Priority: Medium | Effort: High**

### 6.1 Pattern Learning

- [ ] **Analyze historical data**
  - Learn typical feeding intervals
  - Learn sleep patterns (nap times, bedtime)
  - Learn diaper change frequency

- [ ] **On-device ML with Core ML**
  - Create simple regression model for predictions
  - Train on user's historical data
  - Update model periodically

### 6.2 Smart Notifications

- [ ] **Predictive reminders**
  - "Baby usually feeds around this time"
  - "It's been X hours since last feeding"
  - "Nap time approaching based on wake window"

- [ ] **Configurable alerts**
  - Enable/disable per activity type
  - Adjust sensitivity (aggressive vs conservative)
  - Quiet hours setting

### 6.3 Implementation Approach

```swift
// Pattern analysis structure
struct ActivityPattern {
    var activityKind: ActivityKind
    var typicalIntervalMinutes: Double
    var confidenceScore: Double
    var timeOfDayDistribution: [Int: Double] // Hour -> Probability
}

// Prediction engine
class ActivityPredictor {
    func predictNextActivity(for kind: ActivityKind) -> Date?
    func getRecommendedReminders() -> [ScheduledReminder]
}
```

### 6.4 Notification Implementation

- [ ] Request notification permissions
- [ ] Schedule local notifications
- [ ] Handle notification actions (log activity from notification)
- [ ] Support notification categories and actions

---

## Phase 7: Additional Features

**Priority: Low-Medium | Effort: Varies**

### 7.1 Multiple Baby Profiles ✅ COMPLETED (in Phase 5)

- [x] Create `Baby` model
- [x] Profile switcher in UI (BabyProfileView)
- [x] Separate data storage per baby
- [ ] Combined family view (future)

### 7.2 Data Export/Import

- [ ] Export to CSV/JSON
- [ ] PDF reports with charts
- [ ] Share with pediatrician
- [ ] Import from other apps

### 7.3 Widgets

- [ ] Today summary widget (small/medium)
- [ ] Quick-add widget (medium/large)
- [ ] Last activity widget
- [ ] Lock screen widget

### 7.4 Apple Watch App

- [ ] Companion app for quick logging
- [ ] Complications for last activity
- [ ] Haptic reminders

### 7.5 Siri Shortcuts

- [ ] "Log a feeding"
- [ ] "Baby just woke up"
- [ ] "How much did baby sleep today?"

### 7.6 CarPlay Support

- [ ] Voice-activated logging while driving

---

## Technical Debt & Maintenance

### Ongoing Tasks

- [ ] Keep dependencies updated
- [ ] Monitor iOS deprecations
- [ ] Performance optimization
- [ ] Memory usage profiling
- [ ] Accessibility audit

### Documentation

- [ ] Update CLAUDE.md as features are added
- [ ] API documentation for shared code
- [ ] User guide / help screens

---

## Implementation Priority Matrix

| Feature | Impact | Effort | Priority | Status |
|---------|--------|--------|----------|--------|
| Bug fixes | High | Low | P0 | ✅ |
| Milk/Diaper summaries | High | Medium | P1 | ✅ |
| iCloud sync | High | High | P1 | ✅ |
| Family sharing | High | High | P1 | ✅ |
| Health-style charts | Medium | Medium | P2 | ✅ |
| AI reminders | Medium | High | P2 | Pending |
| New activity types | Medium | Medium | P3 | ✅ |
| Widgets | Low | Medium | P3 | Pending |
| Watch app | Low | High | P4 | Pending |
| CarPlay | Low | Medium | P4 | Pending |

---

## Suggested Implementation Order

### Sprint 1 (Foundation)
1. Fix existing bugs
2. Add missing tests
3. Complete Milk summary view

### Sprint 2 (Analytics)
1. Complete Diaper summary view
2. Enhance Sleep analytics
3. Create dashboard view

### Sprint 3 (Cloud)
1. Enable CloudKit
2. Implement multi-device sync
3. Handle offline/conflict scenarios

### Sprint 4 (Sharing)
1. Family sharing setup
2. Permission management
3. Activity attribution

### Sprint 5 (Intelligence)
1. Pattern analysis implementation
2. Prediction engine
3. Smart notification system

### Sprint 6 (Polish)
1. New activity types
2. Widgets
3. Data export

---

## Success Metrics

- **Reliability**: 0 data loss incidents
- **Sync**: < 5 second sync latency
- **Prediction Accuracy**: > 80% for reminder timing
- **User Satisfaction**: Reduce manual logging friction
- **Family Adoption**: Multi-user households using sharing

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Data loss | CloudKit backup, local fallback |
| Sync conflicts | Last-write-wins with merge UI |
| Privacy concerns | On-device ML, no external data sharing |
| Battery drain | Efficient background processing |
| Notification fatigue | Smart throttling, learning from dismissals |
