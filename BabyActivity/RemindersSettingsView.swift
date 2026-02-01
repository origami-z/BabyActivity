//
//  RemindersSettingsView.swift
//  BabyActivity
//
//  Settings view for configuring smart reminders
//

import SwiftUI
import SwiftData

struct RemindersSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [Activity]

    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var predictor = ActivityPredictor()

    @AppStorage("reminderSettings") private var settingsData: Data = Data()

    @State private var settings = ReminderSettings()
    @State private var showTestNotification = false
    @State private var isAnalyzing = false

    var body: some View {
        List {
            // Authorization Section
            authorizationSection

            // Enable/Disable Section
            if notificationService.isAuthorized {
                mainToggleSection
            }

            // Settings Sections (only show if enabled)
            if settings.isEnabled && notificationService.isAuthorized {
                activityTypesSection
                sensitivitySection
                quietHoursSection
            }

            // Pattern Analysis Section
            if notificationService.isAuthorized {
                patternAnalysisSection
            }

            // Upcoming Reminders Section
            if notificationService.isAuthorized && settings.isEnabled && predictor.hasLearnedPatterns {
                upcomingRemindersSection
            }

            // Debug Section
            #if DEBUG
            debugSection
            #endif
        }
        .navigationTitle("Smart Reminders")
        .onAppear {
            loadSettings()
            analyzePatterns()
        }
        .onChange(of: settings) { _, newSettings in
            saveSettings()
            updateReminders()
        }
    }

    // MARK: - Authorization Section

    private var authorizationSection: some View {
        Section {
            HStack {
                Image(systemName: notificationService.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                    .foregroundStyle(notificationService.isAuthorized ? .green : .red)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Permission")
                        .font(.headline)
                    Text(notificationService.isAuthorized ? "Notifications are enabled" : "Notifications are disabled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !notificationService.isAuthorized {
                    Button("Enable") {
                        Task {
                            let granted = await notificationService.requestAuthorization()
                            if !granted {
                                notificationService.openSettings()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.vertical, 4)
        } footer: {
            if !notificationService.isAuthorized {
                Text("Enable notifications to receive smart reminders based on your baby's schedule.")
            }
        }
    }

    // MARK: - Main Toggle Section

    private var mainToggleSection: some View {
        Section {
            Toggle(isOn: $settings.isEnabled) {
                Label("Smart Reminders", systemImage: "brain.head.profile")
            }
        } footer: {
            Text("The app learns your baby's patterns and sends reminders at the right time.")
        }
    }

    // MARK: - Activity Types Section

    private var activityTypesSection: some View {
        Section("Reminder Types") {
            ForEach(ActivityKind.allCases, id: \.self) { kind in
                Toggle(isOn: Binding(
                    get: { settings.enabledActivityKinds.contains(kind) },
                    set: { enabled in
                        if enabled {
                            settings.enabledActivityKinds.insert(kind)
                        } else {
                            settings.enabledActivityKinds.remove(kind)
                        }
                    }
                )) {
                    Label(kind.description.capitalized, systemImage: iconForKind(kind))
                }
            }
        }
    }

    // MARK: - Sensitivity Section

    private var sensitivitySection: some View {
        Section("Reminder Frequency") {
            Picker("Sensitivity", selection: $settings.sensitivity) {
                ForEach(ReminderSettings.Sensitivity.allCases, id: \.self) { sensitivity in
                    Text(sensitivity.description).tag(sensitivity)
                }
            }
            .pickerStyle(.segmented)

            Text(settings.sensitivity.detailedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Quiet Hours Section

    private var quietHoursSection: some View {
        Section("Quiet Hours") {
            Toggle(isOn: $settings.quietHoursEnabled) {
                Label("Enable Quiet Hours", systemImage: "moon.fill")
            }

            if settings.quietHoursEnabled {
                HStack {
                    Text("From")
                    Spacer()
                    Picker("Start", selection: $settings.quietHoursStart) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                }

                HStack {
                    Text("To")
                    Spacer()
                    Picker("End", selection: $settings.quietHoursEnd) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                }
            }
        } footer: {
            if settings.quietHoursEnabled {
                Text("No reminders will be sent during quiet hours.")
            }
        }
    }

    // MARK: - Pattern Analysis Section

    private var patternAnalysisSection: some View {
        Section("Learned Patterns") {
            if isAnalyzing {
                HStack {
                    ProgressView()
                    Text("Analyzing patterns...")
                        .foregroundStyle(.secondary)
                }
            } else if predictor.hasLearnedPatterns {
                ForEach(Array(predictor.patterns.values).sorted(by: { $0.activityKind.rawValue < $1.activityKind.rawValue }), id: \.id) { pattern in
                    PatternRow(pattern: pattern)
                }

                if let lastAnalysis = predictor.lastAnalysisDate {
                    Text("Last analyzed: \(lastAnalysis.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label("No patterns learned yet", systemImage: "questionmark.circle")
                        .foregroundStyle(.secondary)

                    Text("Keep logging activities for at least a few days to help the app learn your baby's schedule.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Button {
                analyzePatterns()
            } label: {
                Label("Re-analyze Patterns", systemImage: "arrow.clockwise")
            }
        }
    }

    // MARK: - Upcoming Reminders Section

    private var upcomingRemindersSection: some View {
        Section("Upcoming Reminders") {
            if predictor.predictions.isEmpty {
                Text("No upcoming reminders")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(predictor.predictions.prefix(5)) { prediction in
                    PredictionRow(prediction: prediction)
                }
            }
        }
    }

    // MARK: - Debug Section

    #if DEBUG
    private var debugSection: some View {
        Section("Debug") {
            Button("Send Test Notification") {
                Task {
                    try? await notificationService.sendTestNotification()
                    showTestNotification = true
                }
            }

            Button("Cancel All Reminders") {
                Task {
                    await notificationService.cancelAllReminders()
                }
            }

            Text("Scheduled: \(notificationService.scheduledNotifications.count) notifications")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    #endif

    // MARK: - Helper Methods

    private func iconForKind(_ kind: ActivityKind) -> String {
        switch kind {
        case .sleep: return Activity.sleepImage
        case .milk: return Activity.milkImage
        case .wetDiaper: return Activity.wetDiaperImage
        case .dirtyDiaper: return Activity.dirtyDiaperImage
        case .solidFood: return Activity.solidFoodImage
        case .tummyTime: return Activity.tummyTimeImage
        case .bathTime: return Activity.bathTimeImage
        case .medicine: return Activity.medicineImage
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    private func loadSettings() {
        if let decoded = try? JSONDecoder().decode(ReminderSettings.self, from: settingsData) {
            settings = decoded
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            settingsData = encoded
        }
    }

    private func analyzePatterns() {
        isAnalyzing = true
        predictor.analyzePatterns(from: activities)
        _ = predictor.generatePredictions(from: activities, settings: settings)
        isAnalyzing = false
    }

    private func updateReminders() {
        guard settings.isEnabled else { return }
        let reminders = predictor.getScheduledReminders(settings: settings)
        Task {
            await notificationService.scheduleReminders(reminders)
        }
    }
}

// MARK: - Pattern Row

struct PatternRow: View {
    let pattern: ActivityPattern

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.activityKind.description.capitalized)
                    .font(.headline)

                HStack {
                    Text("Every ~\(pattern.intervalDescription)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    ConfidenceBadge(confidence: pattern.confidenceScore)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Prediction Row

struct PredictionRow: View {
    let prediction: ActivityPrediction

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(prediction.activityKind.description.capitalized)
                    .font(.headline)

                Text(prediction.timeUntilDescription)
                    .font(.subheadline)
                    .foregroundStyle(prediction.isOverdue ? .red : .secondary)
            }

            Spacer()

            Text(prediction.predictedTime.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        Text(confidenceText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(confidenceColor.opacity(0.2))
            .foregroundStyle(confidenceColor)
            .clipShape(Capsule())
    }

    private var confidenceText: String {
        switch confidence {
        case 0.8...1.0: return "High"
        case 0.5..<0.8: return "Medium"
        default: return "Low"
        }
    }

    private var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RemindersSettingsView()
    }
    .modelContainer(DataController.previewContainer)
}
