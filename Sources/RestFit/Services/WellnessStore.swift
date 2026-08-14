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

    var journalEntries: [JournalEntry] {
        didSet { save() }
    }

    var alarms: [AlarmItem] {
        didSet { save() }
    }

    var todoItems: [TodoItem] {
        didSet { save() }
    }

    var workoutEntries: [WorkoutEntry] {
        didSet { save() }
    }

    var strengthPlan: StrengthWeekPlan {
        didSet { save() }
    }

    var workoutSettings: WorkoutSettings {
        didSet { save() }
    }

    var completedStrengthIDs: [UUID] {
        didSet { save() }
    }

    var pomodoroSessions: [PomodoroSession] {
        didSet { save() }
    }

    var pomodoroSettings: PomodoroSettings {
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

    var sleepStartedAt: Date?
    var isSleeping: Bool = false {
        didSet { save() }
    }

    var workoutStartedAt: Date?
    var activeWorkoutKind: WorkoutKind?
    var isWorkingOut: Bool = false {
        didSet { save() }
    }

    var authUser: AuthUser? {
        didSet { save() }
    }

    var isSignedIn: Bool { authUser != nil }

    var pomodoroPhase: PomodoroPhase = .focus
    var pomodoroStartedAt: Date?
    var pomodoroAccumulated: TimeInterval = 0.0
    var isPomodoroRunning: Bool = false
    var completedFocusRounds: Int = 0

    private(set) var now: Date = .now

    init() {
        let loaded = Self.load()
        profile = loaded.profile
        sleepEntries = loaded.sleepEntries
        weightEntries = loaded.weightEntries
        meditationEntries = loaded.meditationEntries
        journalEntries = loaded.journalEntries ?? []
        alarms = loaded.alarms ?? []
        todoItems = loaded.todoItems ?? []
        workoutEntries = loaded.workoutEntries ?? []
        strengthPlan = loaded.strengthPlan ?? .sample
        workoutSettings = loaded.workoutSettings ?? .default
        completedStrengthIDs = loaded.completedStrengthIDs ?? []
        pomodoroSessions = loaded.pomodoroSessions ?? []
        pomodoroSettings = loaded.pomodoroSettings ?? .default
        isFasting = loaded.isFasting
        fastingStartedAt = loaded.fastingStartedAt
        isMeditating = loaded.isMeditating
        meditationStartedAt = loaded.meditationStartedAt
        activeMeditationPreset = loaded.activeMeditationPreset
        isSleeping = loaded.isSleeping ?? false
        sleepStartedAt = loaded.sleepStartedAt
        isWorkingOut = loaded.isWorkingOut ?? false
        workoutStartedAt = loaded.workoutStartedAt
        activeWorkoutKind = loaded.activeWorkoutKind
        authUser = loaded.authUser

        if sleepEntries.isEmpty && !loaded.profile.hasCompletedOnboarding {
            seedSampleData()
        }

        refreshAlarms()
        refreshWorkoutNudges()
    }

    func signIn(_ user: AuthUser) {
        authUser = user
        if profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || profile.name == WellnessProfile.default.name {
            profile.name = user.displayName
        }
    }

    func signOut() {
        FirebaseAuthService.signOut()
        authUser = nil
    }

    /// Clears fasting/sleep/weight/workout logs and resets profile defaults, but keeps the signed-in account.
    func clearOnDeviceDataKeepingAccount() {
        let signedIn = authUser
        resetWellnessDataToDefaults(
            name: signedIn?.displayName ?? "",
            completedOnboarding: true
        )
        authUser = signedIn
        cancelReminders()
    }

    /// Deletes Firebase account (if any), signs out, and clears all on-device RestFit data.
    @MainActor
    func deleteAccountAndLocalData() async throws {
        try await FirebaseAuthService.deleteAccount()
        FirebaseAuthService.signOut()
        authUser = nil
        resetWellnessDataToDefaults(name: "", completedOnboarding: false)
        cancelReminders()
    }

    private func resetWellnessDataToDefaults(name: String, completedOnboarding: Bool) {
        profile = WellnessProfile(
            name: name.isEmpty ? WellnessProfile.default.name : name,
            targetWeightKg: 65.0,
            fastingProtocol: .sixteenEight,
            fastingStreakDays: 0,
            hasCompletedOnboarding: completedOnboarding,
            remindersEnabled: true,
            weightUnit: profile.weightUnit ?? .pounds
        )
        sleepEntries = []
        weightEntries = []
        meditationEntries = []
        journalEntries = []
        alarms = []
        todoItems = []
        workoutEntries = []
        strengthPlan = .sample
        workoutSettings = .default
        completedStrengthIDs = []
        pomodoroSessions = []
        pomodoroSettings = .default
        isFasting = false
        fastingStartedAt = nil
        isMeditating = false
        meditationStartedAt = nil
        activeMeditationPreset = nil
        isSleeping = false
        sleepStartedAt = nil
        isWorkingOut = false
        workoutStartedAt = nil
        activeWorkoutKind = nil
        resetPomodoro()
        save()
    }

    func tick() {
        now = .now
        if isPomodoroRunning && pomodoroProgress >= 1.0 {
            completePomodoroPhase()
        }
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

    var weightUnit: WeightUnit {
        profile.weightUnit ?? .pounds
    }

    var usesPounds: Bool {
        weightUnit == .pounds
    }

    var weightUnitLabel: String {
        weightUnit.label
    }

    var currentWeightDisplay: Double {
        displayWeight(currentWeightKg)
    }

    var targetWeightDisplay: Double {
        displayWeight(profile.targetWeightKg)
    }

    var weeklyWeightDisplayValues: [Double] {
        weeklyWeightValues.map { displayWeight($0) }
    }

    func displayWeight(_ kilograms: Double) -> Double {
        usesPounds ? kilograms * 2.2046226218 : kilograms
    }

    func kilogramsFromDisplay(_ value: Double) -> Double {
        usesPounds ? value / 2.2046226218 : value
    }

    func setUsesPounds(_ usesPounds: Bool) {
        profile.weightUnit = usesPounds ? .pounds : .kilograms
    }

    var weightDeltaLabel: String {
        WellnessGuide.weightDelta(entries: weightEntries, usesPounds: usesPounds)
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

    var pomodoroElapsed: TimeInterval {
        var live = 0.0
        if isPomodoroRunning, let start = pomodoroStartedAt {
            live = now.timeIntervalSince(start)
        }
        return max(0.0, pomodoroAccumulated + live)
    }

    var pomodoroTarget: TimeInterval {
        Double(pomodoroSettings.minutes(for: pomodoroPhase)) * 60.0
    }

    var pomodoroProgress: Double {
        guard pomodoroTarget > 0 else { return 0.0 }
        return min(1.0, pomodoroElapsed / pomodoroTarget)
    }

    var pomodoroRemainingLabel: String {
        formatMinutesSeconds(max(0.0, pomodoroTarget - pomodoroElapsed))
    }

    var pomodoroElapsedLabel: String {
        formatMinutesSeconds(pomodoroElapsed)
    }

    var todayFocusCount: Int {
        let calendar = Calendar.current
        return pomodoroSessions.filter {
            $0.completed && $0.phase == .focus && calendar.isDate($0.date, inSameDayAs: .now)
        }.count
    }

    var lastJournalLabel: String {
        guard let latest = journalEntries.sorted(by: { $0.date > $1.date }).first else {
            return "No entries yet"
        }
        if latest.title.isEmpty {
            return latest.mood.rawValue
        }
        return latest.title
    }

    var openTodoCount: Int {
        todoItems.filter { !$0.isDone }.count
    }

    var todoSummaryLabel: String {
        if todoItems.isEmpty {
            return "No tasks yet"
        }
        if openTodoCount == 0 {
            return "All caught up"
        }
        if openTodoCount == 1 {
            return "1 open task"
        }
        return "\(openTodoCount) open tasks"
    }

    var nextAlarmLabel: String {
        let enabled = alarms.filter { $0.isEnabled }
        guard !enabled.isEmpty else { return "No alarms set" }

        var soonestLabel = enabled[0].timeLabel
        var soonestDate = FastingReminderService.nextAlarmDate(hour: enabled[0].hour, minute: enabled[0].minute)

        for alarm in enabled {
            guard let date = FastingReminderService.nextAlarmDate(hour: alarm.hour, minute: alarm.minute) else {
                continue
            }
            if let current = soonestDate, date < current {
                soonestDate = date
                soonestLabel = alarm.timeLabel
            } else if soonestDate == nil {
                soonestDate = date
                soonestLabel = alarm.timeLabel
            }
        }

        return soonestLabel
    }

    var lastSleepLabel: String {
        sleepEntries.sorted { $0.date > $1.date }.first?.durationLabel ?? "—"
    }

    var latestSleepEntry: SleepEntry? {
        sleepEntries.sorted { $0.date > $1.date }.first
    }

    var sleepElapsed: TimeInterval {
        guard isSleeping, let start = sleepStartedAt else { return 0.0 }
        return max(0.0, now.timeIntervalSince(start))
    }

    var sleepElapsedLabel: String {
        formatDuration(sleepElapsed)
    }

    var sleepStartedLabel: String {
        guard let start = sleepStartedAt else { return "" }
        return start.formatted(date: .omitted, time: .shortened)
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
        let base = WellnessGuide.tips(
            profile: profile,
            fastingProgress: fastingProgress,
            isFasting: isFasting,
            sleepEntries: sleepEntries,
            weightEntries: weightEntries,
            usesPounds: usesPounds
        )
        let hour = Calendar.current.component(.hour, from: now)
        let workoutTip = WellnessGuide.workoutEncouragement(for: todayStrengthDay, hour: hour)
        let tips: [WellnessGuidance]
        if hour >= 5 && hour < 12 {
            tips = [workoutTip] + base
        } else if !todayStrengthDay.isOffDay || todayStrengthDay.isCardioDay {
            tips = base + [workoutTip]
        } else {
            tips = base
        }
        return tips.sorted { $0.priority < $1.priority }
    }

    var morningWorkoutPrompt: WellnessGuidance {
        WellnessGuide.workoutEncouragement(for: todayStrengthDay)
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

    func startSleep() {
        guard !isSleeping else { return }
        isSleeping = true
        sleepStartedAt = .now
        save()
    }

    func wakeUp() {
        guard isSleeping, let start = sleepStartedAt else { return }
        let minutes = max(1, Int(sleepElapsed / 60.0))
        sleepEntries.append(SleepEntry(
            date: .now,
            durationMinutes: minutes,
            qualityScore: Self.qualityScore(forMinutes: minutes),
            bedTime: start,
            wakeTime: now
        ))
        isSleeping = false
        sleepStartedAt = nil
        save()
        if workoutSettings.morningNudgeEnabled {
            let tip = WellnessGuide.workoutEncouragement(for: todayStrengthDay)
            Task {
                await FastingReminderService.scheduleWakeUpWorkoutNudge(
                    title: tip.title,
                    body: tip.message
                )
            }
        }
        refreshWorkoutNudges()
    }

    func cancelSleep() {
        isSleeping = false
        sleepStartedAt = nil
        save()
    }

    func toggleSleepSession() {
        if isSleeping {
            wakeUp()
        } else {
            startSleep()
        }
    }

    func adjustLatestSleep(byMinutes delta: Int) {
        guard let latest = latestSleepEntry else { return }
        let updatedMinutes = max(30, latest.durationMinutes + delta)
        sleepEntries = sleepEntries.map { entry in
            guard entry.id == latest.id else { return entry }
            var updated = entry
            updated.durationMinutes = updatedMinutes
            updated.qualityScore = Self.qualityScore(forMinutes: updatedMinutes)
            if let bed = updated.bedTime {
                updated.bedTime = bed.addingTimeInterval(Double(-delta) * 60.0)
            }
            return updated
        }
    }

    private static func qualityScore(forMinutes minutes: Int) -> Int {
        if minutes >= 420 && minutes <= 540 {
            return 88
        }
        if minutes >= 360 && minutes < 420 {
            return 75
        }
        if minutes > 540 && minutes <= 600 {
            return 80
        }
        if minutes < 360 {
            return 60
        }
        return 70
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

    func startPomodoro() {
        if pomodoroProgress >= 1.0 {
            pomodoroAccumulated = 0.0
        }
        isPomodoroRunning = true
        pomodoroStartedAt = .now
        save()
        schedulePomodoroNotification()
    }

    func pausePomodoro() {
        if isPomodoroRunning, let start = pomodoroStartedAt {
            pomodoroAccumulated += now.timeIntervalSince(start)
        }
        isPomodoroRunning = false
        pomodoroStartedAt = nil
        save()
        cancelPomodoroNotification()
    }

    func resetPomodoro() {
        isPomodoroRunning = false
        pomodoroStartedAt = nil
        pomodoroAccumulated = 0.0
        save()
        cancelPomodoroNotification()
    }

    func skipPomodoroPhase() {
        completePomodoroPhase(markComplete: false)
    }

    func completePomodoroPhase(markComplete: Bool = true) {
        let minutes = max(1, Int(pomodoroElapsed / 60.0))
        if markComplete {
            pomodoroSessions.append(PomodoroSession(
                phase: pomodoroPhase,
                durationMinutes: minutes,
                completed: true
            ))
        }

        if pomodoroPhase == .focus {
            completedFocusRounds += 1
            if completedFocusRounds % max(1, pomodoroSettings.sessionsUntilLongBreak) == 0 {
                pomodoroPhase = .longBreak
            } else {
                pomodoroPhase = .shortBreak
            }
        } else {
            pomodoroPhase = .focus
        }

        isPomodoroRunning = false
        pomodoroStartedAt = nil
        pomodoroAccumulated = 0.0
        save()
        cancelPomodoroNotification()
    }

    func applyPomodoroPreset(focus: Int, shortBreak: Int, longBreak: Int) {
        pomodoroSettings.focusMinutes = focus
        pomodoroSettings.shortBreakMinutes = shortBreak
        pomodoroSettings.longBreakMinutes = longBreak
        resetPomodoro()
    }

    func addJournalEntry(title: String, body: String, mood: JournalMood) {
        journalEntries.insert(
            JournalEntry(title: title, body: body, mood: mood),
            at: 0
        )
    }

    func updateJournalEntry(_ entry: JournalEntry) {
        journalEntries = journalEntries.map { item in
            item.id == entry.id ? entry : item
        }
    }

    func deleteJournalEntry(_ entry: JournalEntry) {
        journalEntries.removeAll { $0.id == entry.id }
    }

    func addTodo(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        todoItems.insert(TodoItem(title: trimmed), at: 0)
    }

    func toggleTodo(_ item: TodoItem) {
        todoItems = todoItems.map { current in
            if current.id == item.id {
                var updated = current
                updated.isDone.toggle()
                return updated
            }
            return current
        }
    }

    func deleteTodo(_ item: TodoItem) {
        todoItems.removeAll { $0.id == item.id }
    }

    func clearCompletedTodos() {
        todoItems.removeAll { $0.isDone }
    }

    func addAlarm(label: String, hour: Int, minute: Int, repeatsDaily: Bool) {
        alarms.append(AlarmItem(label: label, hour: hour, minute: minute, repeatsDaily: repeatsDaily))
        refreshAlarms()
    }

    func updateAlarm(_ alarm: AlarmItem) {
        alarms = alarms.map { item in
            item.id == alarm.id ? alarm : item
        }
        refreshAlarms()
    }

    func deleteAlarm(_ alarm: AlarmItem) {
        let notificationID = alarm.notificationID
        alarms.removeAll { $0.id == alarm.id }
        Task {
            await FastingReminderService.cancelAlarm(id: notificationID)
        }
        refreshAlarms()
    }

    func toggleAlarm(_ alarm: AlarmItem) {
        var updated = alarm
        updated.isEnabled.toggle()
        updateAlarm(updated)
    }

    var workoutElapsed: TimeInterval {
        guard isWorkingOut, let start = workoutStartedAt else { return 0 }
        return max(0.0, now.timeIntervalSince(start))
    }

    var workoutTimerLabel: String {
        formatDuration(workoutElapsed)
    }

    var recentWorkouts: [WorkoutEntry] {
        Array(workoutEntries.sorted { $0.date > $1.date }.prefix(8))
    }

    var weeklyWorkoutMinutes: Int {
        let start = currentWeekStart
        return workoutEntries
            .filter { $0.date >= start }
            .reduce(0) { $0 + $1.minutes }
    }

    var weeklyWorkoutLabel: String {
        "\(weeklyWorkoutMinutes) min · \(workoutSettings.weekRangeLabel)"
    }

    var weekDayOrder: [Weekday] {
        Weekday.ordered(startingAt: workoutSettings.weekStartsOn)
    }

    var currentWeekStart: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let todayWeekday = calendar.component(.weekday, from: today)
        let startRaw = workoutSettings.weekStartsOn.rawValue
        var delta = todayWeekday - startRaw
        if delta < 0 { delta += 7 }
        return calendar.date(byAdding: .day, value: -delta, to: today) ?? today
    }

    var currentWeekEnd: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
    }

    var isWeekEndToday: Bool {
        todayWeekday == workoutSettings.weekEndsOn
    }

    func updateWorkoutSettings(
        weekStartsOn: Weekday,
        trainingNotes: String,
        morningNudgeEnabled: Bool,
        morningNudgeHour: Int,
        morningNudgeMinute: Int,
        followWakeAlarm: Bool
    ) {
        workoutSettings.weekStartsOn = weekStartsOn
        workoutSettings.trainingNotes = trainingNotes
        workoutSettings.morningNudgeEnabled = morningNudgeEnabled
        workoutSettings.morningNudgeHour = morningNudgeHour
        workoutSettings.morningNudgeMinute = morningNudgeMinute
        workoutSettings.followWakeAlarm = followWakeAlarm
        refreshWorkoutNudges()
    }

    var resolvedMorningNudgeHour: Int {
        if workoutSettings.followWakeAlarm, let wake = wakeAlarm {
            let total = wake.hour * 60 + wake.minute + 30
            return (total / 60) % 24
        }
        return workoutSettings.morningNudgeHour
    }

    var resolvedMorningNudgeMinute: Int {
        if workoutSettings.followWakeAlarm, let wake = wakeAlarm {
            let total = wake.hour * 60 + wake.minute + 30
            return total % 60
        }
        return workoutSettings.morningNudgeMinute
    }

    private var wakeAlarm: AlarmItem? {
        alarms.first { alarm in
            alarm.isEnabled && alarm.label.lowercased().contains("wake")
        }
    }

    var morningNudgeTimeLabel: String {
        let hour = resolvedMorningNudgeHour
        let minute = resolvedMorningNudgeMinute
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour12, minute, period)
    }

    func refreshWorkoutNudges() {
        let enabled = workoutSettings.morningNudgeEnabled
        let hour = resolvedMorningNudgeHour
        let minute = resolvedMorningNudgeMinute
        let tip = WellnessGuide.workoutEncouragement(for: todayStrengthDay)
        Task {
            _ = await FastingReminderService.requestAuthorization()
            await FastingReminderService.scheduleMorningWorkoutNudge(
                enabled: enabled,
                hour: hour,
                minute: minute,
                title: tip.title,
                body: tip.message
            )
        }
    }

    func startWorkout(_ kind: WorkoutKind) {
        activeWorkoutKind = kind
        workoutStartedAt = .now
        isWorkingOut = true
        if kind == .strength {
            completedStrengthIDs = []
        }
    }

    func finishWorkout() {
        let minutes = max(1, Int(workoutElapsed / 60.0))
        let kind = activeWorkoutKind ?? .strength
        workoutEntries.append(WorkoutEntry(date: .now, kind: kind, minutes: minutes))
        cancelWorkout()
    }

    func cancelWorkout() {
        isWorkingOut = false
        workoutStartedAt = nil
        activeWorkoutKind = nil
        completedStrengthIDs = []
    }

    var todayWeekday: Weekday {
        Weekday(rawValue: Calendar.current.component(.weekday, from: now)) ?? .monday
    }

    var todayStrengthDay: StrengthDayPlan {
        strengthDay(for: todayWeekday)
    }

    func strengthDay(for weekday: Weekday) -> StrengthDayPlan {
        if let day = strengthPlan.days.first(where: { $0.weekday == weekday }) {
            return day
        }
        return StrengthDayPlan(weekday: weekday)
    }

    func upsertStrengthDay(_ day: StrengthDayPlan) {
        var plan = strengthPlan
        if let index = plan.days.firstIndex(where: { $0.weekday == day.weekday }) {
            plan.days[index] = day
        } else {
            plan.days.append(day)
        }
        strengthPlan = plan
    }

    func setStrengthFocus(_ weekday: Weekday, focus: String, isRestDay: Bool) {
        var day = strengthDay(for: weekday)
        day.focus = focus
        day.isRestDay = isRestDay || focus.lowercased() == "rest" || focus.lowercased() == "cardio"
        upsertStrengthDay(day)
        refreshWorkoutNudges()
    }

    func addStrengthExercise(_ weekday: Weekday, exercise: StrengthExercise) {
        var day = strengthDay(for: weekday)
        day.exercises.append(exercise)
        day.isRestDay = false
        if day.focus == "Rest" {
            day.focus = "Workout"
        }
        upsertStrengthDay(day)
    }

    func updateStrengthExercise(_ weekday: Weekday, exercise: StrengthExercise) {
        var day = strengthDay(for: weekday)
        day.exercises = day.exercises.map { item in
            item.id == exercise.id ? exercise : item
        }
        upsertStrengthDay(day)
    }

    func deleteStrengthExercise(_ weekday: Weekday, id: UUID) {
        var day = strengthDay(for: weekday)
        day.exercises.removeAll { $0.id == id }
        upsertStrengthDay(day)
    }

    func adjustStrengthWeight(_ weekday: Weekday, id: UUID, deltaDisplay: Double) {
        var day = strengthDay(for: weekday)
        day.exercises = day.exercises.map { item in
            guard item.id == id else { return item }
            var updated = item
            let next = max(0.0, displayWeight(item.weightKg) + deltaDisplay)
            updated.weightKg = kilogramsFromDisplay(next)
            return updated
        }
        upsertStrengthDay(day)
    }

    func toggleStrengthExerciseDone(_ id: UUID) {
        if completedStrengthIDs.contains(id) {
            completedStrengthIDs.removeAll { $0 == id }
        } else {
            completedStrengthIDs.append(id)
        }
    }

    func isStrengthExerciseDone(_ id: UUID) -> Bool {
        completedStrengthIDs.contains(id)
    }

    var liftWeightStep: Double {
        usesPounds ? 5.0 : 2.0
    }

    func liftWeightLabel(_ kilograms: Double) -> String {
        let value = displayWeight(kilograms)
        if usesPounds {
            return "\(Int(value.rounded())) \(weightUnitLabel)"
        }
        return String(format: "%.1f", value) + " " + weightUnitLabel
    }

    func liftPrescription(_ exercise: StrengthExercise) -> String {
        "\(exercise.sets)×\(exercise.reps) @ \(liftWeightLabel(exercise.weightKg))"
    }

    func logWorkout(kind: WorkoutKind, minutes: Int, notes: String = "") {
        let safeMinutes = max(1, minutes)
        workoutEntries.append(WorkoutEntry(date: .now, kind: kind, minutes: safeMinutes, notes: notes))
    }

    func deleteWorkout(_ entry: WorkoutEntry) {
        workoutEntries.removeAll { $0.id == entry.id }
    }

    func refreshAlarms() {
        let snapshot = alarms
        Task {
            _ = await FastingReminderService.requestAuthorization()
            await FastingReminderService.rescheduleAlarms(snapshot)
        }
        refreshWorkoutNudges()
    }

    private func schedulePomodoroNotification() {
        let remaining = max(0.0, pomodoroTarget - pomodoroElapsed)
        let phase = pomodoroPhase
        Task {
            await FastingReminderService.schedulePomodoroCompletion(
                phase: phase,
                remainingSeconds: remaining
            )
        }
    }

    private func cancelPomodoroNotification() {
        Task {
            await FastingReminderService.cancelPomodoroCompletion()
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

    private func formatMinutesSeconds(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
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

        journalEntries = [
            JournalEntry(
                date: calendar.date(byAdding: .day, value: -1, to: .now) ?? .now,
                title: "Steady morning",
                body: "Woke up hydrated and kept the fast. Sleep felt deeper than usual.",
                mood: .good
            )
        ]

        alarms = [
            AlarmItem(label: "Wake up", hour: 7, minute: 0, isEnabled: true, repeatsDaily: true),
            AlarmItem(label: "Wind down", hour: 22, minute: 30, isEnabled: true, repeatsDaily: true)
        ]

        todoItems = [
            TodoItem(title: "Drink a glass of water", isDone: false),
            TodoItem(title: "Log last night's sleep", isDone: false),
            TodoItem(title: "Prep a protein-forward first meal", isDone: true)
        ]

        workoutEntries = [
            WorkoutEntry(
                date: calendar.date(byAdding: .day, value: -1, to: .now) ?? .now,
                kind: .walk,
                minutes: 32
            ),
            WorkoutEntry(
                date: calendar.date(byAdding: .day, value: -3, to: .now) ?? .now,
                kind: .strength,
                minutes: 45
            )
        ]

        strengthPlan = .sample

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
    var journalEntries: [JournalEntry]?
    var alarms: [AlarmItem]?
    var pomodoroSessions: [PomodoroSession]?
    var pomodoroSettings: PomodoroSettings?
    var todoItems: [TodoItem]?
    var workoutEntries: [WorkoutEntry]?
    var strengthPlan: StrengthWeekPlan?
    var workoutSettings: WorkoutSettings?
    var completedStrengthIDs: [UUID]?
    var isSleeping: Bool?
    var sleepStartedAt: Date?
    var isWorkingOut: Bool?
    var workoutStartedAt: Date?
    var activeWorkoutKind: WorkoutKind?
    var authUser: AuthUser?
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
                activeMeditationPreset: nil,
                journalEntries: [],
                alarms: [],
                pomodoroSessions: [],
                pomodoroSettings: .default,
                todoItems: [],
                workoutEntries: [],
                strengthPlan: .sample,
                workoutSettings: .default,
                completedStrengthIDs: [],
                isSleeping: false,
                sleepStartedAt: nil,
                isWorkingOut: false,
                workoutStartedAt: nil,
                activeWorkoutKind: nil,
                authUser: nil
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
            activeMeditationPreset: activeMeditationPreset,
            journalEntries: journalEntries,
            alarms: alarms,
            pomodoroSessions: pomodoroSessions,
            pomodoroSettings: pomodoroSettings,
            todoItems: todoItems,
            workoutEntries: workoutEntries,
            strengthPlan: strengthPlan,
            workoutSettings: workoutSettings,
            completedStrengthIDs: completedStrengthIDs,
            isSleeping: isSleeping,
            sleepStartedAt: sleepStartedAt,
            isWorkingOut: isWorkingOut,
            workoutStartedAt: workoutStartedAt,
            activeWorkoutKind: activeWorkoutKind,
            authUser: authUser
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
