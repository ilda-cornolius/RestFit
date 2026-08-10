import Foundation
import Observation
import OSLog

@Observable public final class WellnessStore {
    var profile: WellnessProfile {
        didSet { save() }
    }

    var sleepEntries: [SleepEntry] {
        didSet { save() }
    }

    var weightEntries: [WeightEntry] {
        didSet { save() }
    }

    var meditationEntries: [MeditationEntry] {
        didSet { save() }
    }

    var fastingStartedAt: Date?
    var meditationStartedAt: Date?
    var activeMeditationPreset: MeditationPreset?
    var isFasting: Bool = false {
        didSet { save() }
    }
    var isMeditating: Bool = false {
        didSet { save() }
    }

    private(set) var now: Date = .now

    init() {
        let loaded = Self.load()
        profile = loaded.profile
        sleepEntries = loaded.sleepEntries
        weightEntries = loaded.weightEntries
        meditationEntries = loaded.meditationEntries
        isFasting = loaded.isFasting
        fastingStartedAt = loaded.fastingStartedAt
        isMeditating = loaded.isMeditating
        meditationStartedAt = loaded.meditationStartedAt
        activeMeditationPreset = loaded.activeMeditationPreset

        if sleepEntries.isEmpty && !loaded.profile.hasCompletedOnboarding {
            seedSampleData()
        }
    }

    func tick() {
        now = .now
    }

    var fastingElapsed: TimeInterval {
        guard isFasting, let start = fastingStartedAt else { return 0 }
        return max(0.0, now.timeIntervalSince(start))
    }

    var fastingTarget: TimeInterval {
        profile.fastingProtocol.targetHours * 3600.0
    }

    var fastingProgress: Double {
        guard fastingTarget > 0 else { return 0 }
        return min(1.0, fastingElapsed / fastingTarget)
    }

    var fastingTimeRemaining: TimeInterval {
        max(0.0, fastingTarget - fastingElapsed)
    }

    var fastingTimerLabel: String {
        formatDuration(fastingElapsed)
    }

    var fastingTargetLabel: String {
        formatDuration(fastingTarget)
    }

    var fastingTargetShortLabel: String {
        String(fastingTargetLabel.prefix(5))
    }

    var nextMealLabel: String {
        formatDuration(fastingTimeRemaining)
    }

    var currentWeightKg: Double {
        weightEntries.sorted { $0.date > $1.date }.first?.kilograms ?? 68.4
    }

    var sleepScore: Int {
        sleepEntries.sorted { $0.date > $1.date }.first?.qualityScore ?? 88
    }

    var weeklySleepScores: [Int] {
        sleepEntries
            .sorted { $0.date < $1.date }
            .suffix(7)
            .map(\.qualityScore)
    }

    var weeklyWeightValues: [Double] {
        weightEntries
            .sorted { $0.date < $1.date }
            .suffix(7)
            .map(\.kilograms)
    }

    var weeklyMeditationMinutes: [Double] {
        let calendar = Calendar.current
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset - 6, to: .now) ?? .now
            let total = meditationEntries
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.durationMinutes }
            return Double(total)
        }
    }

    var totalMeditationMinutesThisWeek: Int {
        Int(weeklyMeditationMinutes.reduce(0.0, +).rounded())
    }

    var meditationElapsed: TimeInterval {
        guard isMeditating, let start = meditationStartedAt else { return 0.0 }
        return max(0.0, now.timeIntervalSince(start))
    }

    var meditationTarget: TimeInterval {
        Double(activeMeditationPreset?.durationMinutes ?? 10) * 60.0
    }

    var meditationProgress: Double {
        guard meditationTarget > 0 else { return 0.0 }
        return min(1.0, meditationElapsed / meditationTarget)
    }

    var meditationTimerLabel: String {
        formatDuration(meditationElapsed)
    }

    var meditationRemainingLabel: String {
        formatDuration(max(0.0, meditationTarget - meditationElapsed))
    }

    var lastMeditationLabel: String {
        guard let latest = meditationEntries.sorted(by: { $0.date > $1.date }).first else {
            return "No sessions yet"
        }
        return "\(latest.durationMinutes) min · \(latest.presetName)"
    }

    var lastSleepLabel: String {
        sleepEntries.sorted { $0.date > $1.date }.first?.durationLabel ?? "—"
    }

    var lastWeightEntryLabel: String {
        guard let latest = weightEntries.sorted(by: { $0.date > $1.date }).first else {
            return "No entries yet"
        }
        let days = Calendar.current.dateComponents([.day], from: latest.date, to: .now).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days) days ago"
    }

    var guidance: [WellnessGuidance] {
        WellnessGuide.tips(
            profile: profile,
            fastingProgress: fastingProgress,
            isFasting: isFasting,
            sleepEntries: sleepEntries,
            weightEntries: weightEntries
        )
    }

    var hasCompletedOnboarding: Bool {
        profile.hasCompletedOnboarding
    }

    var remindersEnabled: Bool {
        profile.remindersEnabled
    }

    func completeOnboarding(
        name: String,
        targetWeight: Double,
        fastingProtocol: FastingProtocol,
        remindersEnabled: Bool
    ) {
        profile.name = name
        profile.targetWeightKg = targetWeight
        profile.fastingProtocol = fastingProtocol
        profile.remindersEnabled = remindersEnabled
        profile.hasCompletedOnboarding = true
        save()
    }

    func setRemindersEnabled(_ enabled: Bool) {
        profile.remindersEnabled = enabled
        save()
    }

    func startFasting() {
        isFasting = true
        fastingStartedAt = .now
        save()
        scheduleReminders()
    }

    func endFasting() {
        isFasting = false
        fastingStartedAt = nil
        save()
        cancelReminders()
    }

    func toggleFasting() {
        if isFasting {
            endFasting()
        } else {
            startFasting()
        }
    }

    func logSleep(hours: Int, minutes: Int, quality: Int) {
        let entry = SleepEntry(
            date: .now,
            durationMinutes: hours * 60 + minutes,
            qualityScore: quality
        )
        sleepEntries.append(entry)
    }

    func logWeight(_ kilograms: Double) {
        weightEntries.append(WeightEntry(date: .now, kilograms: kilograms))
    }

    func startMeditation(_ preset: MeditationPreset) {
        activeMeditationPreset = preset
        isMeditating = true
        meditationStartedAt = .now
        save()
    }

    func endMeditation(completed: Bool = false) {
        if isMeditating, let preset = activeMeditationPreset, let start = meditationStartedAt {
            let elapsedMinutes = max(1, Int(now.timeIntervalSince(start) / 60.0))
            let recordedMinutes = completed ? preset.durationMinutes : min(elapsedMinutes, preset.durationMinutes)
            meditationEntries.append(MeditationEntry(
                date: .now,
                durationMinutes: recordedMinutes,
                presetName: preset.rawValue
            ))
        }
        isMeditating = false
        meditationStartedAt = nil
        activeMeditationPreset = nil
        save()
    }

    func toggleMeditation(_ preset: MeditationPreset) {
        if isMeditating {
            endMeditation(completed: meditationProgress >= 0.95)
        } else {
            startMeditation(preset)
        }
    }

    func updateProfile(name: String, targetWeight: Double, fastingProtocol: FastingProtocol) {
        profile.name = name
        profile.targetWeightKg = targetWeight
        profile.fastingProtocol = fastingProtocol
    }

    func scheduleReminders() {
        guard profile.remindersEnabled else { return }
        let fasting = isFasting
        let startedAt = fastingStartedAt
        let targetHours = profile.fastingProtocol.targetHours
        let remindersEnabled = profile.remindersEnabled
        Task {
            _ = await FastingReminderService.requestAuthorization()
            await FastingReminderService.scheduleFastingReminders(
                isFasting: fasting,
                startedAt: startedAt,
                targetHours: targetHours,
                remindersEnabled: remindersEnabled
            )
        }
    }

    func cancelReminders() {
        let targetHours = profile.fastingProtocol.targetHours
        Task {
            await FastingReminderService.scheduleFastingReminders(
                isFasting: false,
                startedAt: nil,
                targetHours: targetHours,
                remindersEnabled: false
            )
        }
    }

    @MainActor
    func importHealthData() async -> String {
        let authorized = await HealthDataService.requestAuthorization()
        guard authorized else {
            return "Health access was not granted."
        }
        let snapshot = await HealthDataService.fetchRecentSnapshot()
        importHealthSnapshot(snapshot)
        if snapshot.sleepHours == nil && snapshot.weightKg == nil {
            return "No recent sleep or weight data found in Apple Health."
        }
        return "Imported from \(snapshot.sourceLabel)."
    }

    func importHealthSnapshot(_ snapshot: HealthSnapshot) {
        HealthDataService.importIntoStore(self, snapshot: snapshot)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func seedSampleData() {
        let calendar = Calendar.current
        let sleepScores = [72, 78, 74, 81, 86, 80, 88]
        let weights = [72.0, 71.2, 70.5, 69.8, 69.2, 68.8, 68.4]

        sleepEntries = sleepScores.enumerated().map { index, score in
            SleepEntry(
                date: calendar.date(byAdding: .day, value: index - 6, to: .now) ?? .now,
                durationMinutes: 420 + score / 3,
                qualityScore: score
            )
        }

        weightEntries = weights.enumerated().map { index, weight in
            WeightEntry(
                date: calendar.date(byAdding: .day, value: index - 6, to: .now) ?? .now,
                kilograms: weight
            )
        }

        meditationEntries = [
            MeditationEntry(date: calendar.date(byAdding: .day, value: -1, to: .now) ?? .now, durationMinutes: 10, presetName: "Body Scan"),
            MeditationEntry(date: calendar.date(byAdding: .day, value: -2, to: .now) ?? .now, durationMinutes: 5, presetName: "Breath Focus"),
            MeditationEntry(date: calendar.date(byAdding: .day, value: -4, to: .now) ?? .now, durationMinutes: 15, presetName: "Sleep Prep"),
        ]

        isFasting = true
        fastingStartedAt = .now.addingTimeInterval(-14 * 3600 - 20 * 60 - 45)
    }
}

private struct PersistedState: Codable {
    var profile: WellnessProfile
    var sleepEntries: [SleepEntry]
    var weightEntries: [WeightEntry]
    var meditationEntries: [MeditationEntry]
    var isFasting: Bool
    var fastingStartedAt: Date?
    var isMeditating: Bool
    var meditationStartedAt: Date?
    var activeMeditationPreset: MeditationPreset?
}

extension WellnessStore {
    private static let savePath = URL.applicationSupportDirectory.appendingPathComponent("restfit-wellness.json")

    private static func load() -> PersistedState {
        do {
            let data = try Data(contentsOf: savePath)
            return try JSONDecoder().decode(PersistedState.self, from: data)
        } catch {
            logger.info("Using default wellness data: \(error.localizedDescription)")
            return PersistedState(
                profile: .default,
                sleepEntries: [],
                weightEntries: [],
                meditationEntries: [],
                isFasting: false,
                fastingStartedAt: nil,
                isMeditating: false,
                meditationStartedAt: nil,
                activeMeditationPreset: nil
            )
        }
    }

    private func save() {
        let state = PersistedState(
            profile: profile,
            sleepEntries: sleepEntries,
            weightEntries: weightEntries,
            meditationEntries: meditationEntries,
            isFasting: isFasting,
            fastingStartedAt: fastingStartedAt,
            isMeditating: isMeditating,
            meditationStartedAt: meditationStartedAt,
            activeMeditationPreset: activeMeditationPreset
        )
        do {
            let data = try JSONEncoder().encode(state)
            try FileManager.default.createDirectory(at: URL.applicationSupportDirectory, withIntermediateDirectories: true)
            try data.write(to: Self.savePath)
        } catch {
            logger.error("Failed to save wellness data: \(error.localizedDescription)")
        }
    }
}
