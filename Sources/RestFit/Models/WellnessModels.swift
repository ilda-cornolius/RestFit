import Foundation

enum FastingProtocol: String, Codable, CaseIterable, Identifiable {
    case sixteenEight = "16:8"
    case eighteenSix = "18:6"
    case twentyFour = "20:4"
    case custom = "Custom"

    var id: String { rawValue }

    var targetHours: Double {
        switch self {
        case .sixteenEight: 16.0
        case .eighteenSix: 18.0
        case .twentyFour: 20.0
        case .custom: 16.0
        }
    }

    var displayName: String {
        switch self {
        case .sixteenEight: "Intermittent 16:8"
        case .eighteenSix: "Intermittent 18:6"
        case .twentyFour: "Intermittent 20:4"
        case .custom: "Custom Fast"
        }
    }
}

struct SleepEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var durationMinutes: Int
    var qualityScore: Int
    var bedTime: Date?
    var wakeTime: Date?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        durationMinutes: Int = 465,
        qualityScore: Int = 80,
        bedTime: Date? = nil,
        wakeTime: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.durationMinutes = durationMinutes
        self.qualityScore = qualityScore
        self.bedTime = bedTime
        self.wakeTime = wakeTime
    }

    var durationLabel: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}

struct FastingEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var startedAt: Date
    var durationSeconds: TimeInterval
    var targetHours: Double
    var fastingProtocol: FastingProtocol

    init(
        id: UUID = UUID(),
        date: Date = .now,
        startedAt: Date,
        durationSeconds: TimeInterval,
        targetHours: Double,
        fastingProtocol: FastingProtocol
    ) {
        self.id = id
        self.date = date
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.targetHours = targetHours
        self.fastingProtocol = fastingProtocol
    }

    var durationLabel: String {
        let total = max(0, Int(durationSeconds))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    var reachedGoal: Bool {
        durationSeconds >= targetHours * 3600.0
    }
}

struct WeightEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var kilograms: Double

    init(id: UUID = UUID(), date: Date = .now, kilograms: Double = 68.4) {
        self.id = id
        self.date = date
        self.kilograms = kilograms
    }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case pounds = "lb"
    case kilograms = "kg"

    var id: String { rawValue }

    var label: String { rawValue }

    var displayName: String {
        switch self {
        case .pounds: "Pounds (lb)"
        case .kilograms: "Kilograms (kg)"
        }
    }
}

struct WellnessProfile: Codable {
    var name: String
    var targetWeightKg: Double
    var fastingProtocol: FastingProtocol
    var fastingStreakDays: Int
    var hasCompletedOnboarding: Bool
    var remindersEnabled: Bool
    var weightUnit: WeightUnit?
    var backgroundAnimationEnabled: Bool

    static let `default` = WellnessProfile(
        name: "",
        targetWeightKg: 65.0,
        fastingProtocol: .sixteenEight,
        fastingStreakDays: 0,
        hasCompletedOnboarding: false,
        remindersEnabled: true,
        weightUnit: .pounds,
        backgroundAnimationEnabled: true
    )

    enum CodingKeys: String, CodingKey {
        case name, targetWeightKg, fastingProtocol, fastingStreakDays
        case hasCompletedOnboarding, remindersEnabled, weightUnit
        case backgroundAnimationEnabled
    }

    init(
        name: String,
        targetWeightKg: Double,
        fastingProtocol: FastingProtocol,
        fastingStreakDays: Int,
        hasCompletedOnboarding: Bool,
        remindersEnabled: Bool,
        weightUnit: WeightUnit?,
        backgroundAnimationEnabled: Bool = true
    ) {
        self.name = name
        self.targetWeightKg = targetWeightKg
        self.fastingProtocol = fastingProtocol
        self.fastingStreakDays = fastingStreakDays
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.remindersEnabled = remindersEnabled
        self.weightUnit = weightUnit
        self.backgroundAnimationEnabled = backgroundAnimationEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        targetWeightKg = try container.decodeIfPresent(Double.self, forKey: .targetWeightKg) ?? 65.0
        fastingProtocol = try container.decodeIfPresent(FastingProtocol.self, forKey: .fastingProtocol) ?? FastingProtocol.sixteenEight
        fastingStreakDays = try container.decodeIfPresent(Int.self, forKey: .fastingStreakDays) ?? 0
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        remindersEnabled = try container.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? true
        weightUnit = try container.decodeIfPresent(WeightUnit.self, forKey: .weightUnit)
        backgroundAnimationEnabled = try container.decodeIfPresent(Bool.self, forKey: .backgroundAnimationEnabled) ?? true
    }
}

struct WellnessGuidance: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let message: String
    let priority: Int
    let icon: String
}

/// Past feature. Meditation UI is hidden; models stay for a future restore. See `PastFeatures`.
enum MeditationPreset: String, Codable, CaseIterable, Identifiable {
    case breath = "Breath Focus"
    case bodyScan = "Body Scan"
    case sleepPrep = "Sleep Prep"
    case deepCalm = "Deep Calm"

    var id: String { rawValue }

    var durationMinutes: Int {
        switch self {
        case .breath: 5
        case .bodyScan: 10
        case .sleepPrep: 15
        case .deepCalm: 20
        }
    }

    var subtitle: String {
        switch self {
        case .breath: "Box breathing to settle your nervous system"
        case .bodyScan: "Progressive relaxation from head to toe"
        case .sleepPrep: "Wind down before bed"
        case .deepCalm: "Extended stillness for deep recovery"
        }
    }

    var icon: String {
        switch self {
        case .breath: "wind"
        case .bodyScan: "figure.mind.and.body"
        case .sleepPrep: "moon.zzz.fill"
        case .deepCalm: "leaf.fill"
        }
    }
}

struct MeditationEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var durationMinutes: Int
    var presetName: String

    init(id: UUID = UUID(), date: Date = .now, durationMinutes: Int = 10, presetName: String = "Breath Focus") {
        self.id = id
        self.date = date
        self.durationMinutes = durationMinutes
        self.presetName = presetName
    }
}

/// Past feature. Pomodoro UI is hidden; models stay for a future restore. See `PastFeatures`.
enum PomodoroPhase: String, Codable, CaseIterable, Identifiable {
    case focus = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .focus: "timer"
        case .shortBreak: "cup.and.saucer.fill"
        case .longBreak: "leaf.fill"
        }
    }
}

struct PomodoroSettings: Codable, Hashable {
    var focusMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var sessionsUntilLongBreak: Int

    static let `default` = PomodoroSettings(
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        sessionsUntilLongBreak: 4
    )

    func minutes(for phase: PomodoroPhase) -> Int {
        switch phase {
        case .focus: focusMinutes
        case .shortBreak: shortBreakMinutes
        case .longBreak: longBreakMinutes
        }
    }
}

struct PomodoroSession: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var phase: PomodoroPhase
    var durationMinutes: Int
    var completed: Bool

    init(
        id: UUID = UUID(),
        date: Date = .now,
        phase: PomodoroPhase = .focus,
        durationMinutes: Int = 25,
        completed: Bool = true
    ) {
        self.id = id
        self.date = date
        self.phase = phase
        self.durationMinutes = durationMinutes
        self.completed = completed
    }
}

/// Past feature. Journal UI is hidden; models stay for a future restore. See `PastFeatures`.
enum JournalMood: String, Codable, CaseIterable, Identifiable {
    case great = "Great"
    case good = "Good"
    case okay = "Okay"
    case low = "Low"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .great: "sun.max.fill"
        case .good: "cloud.sun.fill"
        case .okay: "cloud.fill"
        case .low: "cloud.rain.fill"
        }
    }
}

struct JournalEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var title: String
    var body: String
    var mood: JournalMood

    init(
        id: UUID = UUID(),
        date: Date = .now,
        title: String = "",
        body: String = "",
        mood: JournalMood = .good
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.body = body
        self.mood = mood
    }

    var preview: String {
        if body.isEmpty { return "No note yet" }
        return String(body.prefix(80))
    }
}

struct AlarmItem: Identifiable, Codable, Hashable {
    let id: UUID
    var label: String
    var hour: Int
    var minute: Int
    var isEnabled: Bool
    var repeatsDaily: Bool

    init(
        id: UUID = UUID(),
        label: String = "Wake up",
        hour: Int = 7,
        minute: Int = 0,
        isEnabled: Bool = true,
        repeatsDaily: Bool = true
    ) {
        self.id = id
        self.label = label
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
        self.repeatsDaily = repeatsDaily
    }

    var timeLabel: String {
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour12, minute, period)
    }

    var notificationID: String {
        "restfit.alarm.\(id.uuidString)"
    }
}

/// Past feature. To-Do UI is hidden; models stay for a future restore. See `PastFeatures`.
struct TodoItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isDone: Bool
    var createdAt: Date

    init(id: UUID = UUID(), title: String = "", isDone: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
    }
}

enum WorkoutKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case strength
    case cardio
    case walk
    case yoga
    case stretch
    case sports

    var id: String { rawValue }

    var title: String {
        switch self {
        case .strength: "Strength"
        case .cardio: "Cardio"
        case .walk: "Walk"
        case .yoga: "Yoga"
        case .stretch: "Stretch"
        case .sports: "Sports"
        }
    }

    var icon: String {
        switch self {
        case .strength: "flame.fill"
        case .cardio: "heart.fill"
        case .walk: "figure.walk"
        case .yoga: "leaf.fill"
        case .stretch: "arrow.up.left.and.arrow.down.right"
        case .sports: "sportscourt.fill"
        }
    }
}

enum Weekday: Int, Codable, CaseIterable, Identifiable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    static let trainingOrder: [Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]

    var shortTitle: String {
        switch self {
        case .sunday: "Sun"
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        }
    }

    var title: String {
        switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        }
    }

    var previous: Weekday {
        Weekday(rawValue: rawValue == 1 ? 7 : rawValue - 1) ?? .saturday
    }

    static func ordered(startingAt start: Weekday) -> [Weekday] {
        let all = Weekday.allCases.sorted { $0.rawValue < $1.rawValue }
        guard let index = all.firstIndex(of: start) else { return trainingOrder }
        return Array(all[index...]) + Array(all[..<index])
    }
}

struct WorkoutSettings: Codable, Hashable {
    var weekStartsOn: Weekday
    var trainingNotes: String
    var lastDaySplashAt: Date?
    var lastWeekEndSplashKey: String?
    var morningNudgeEnabled: Bool
    var morningNudgeHour: Int
    var morningNudgeMinute: Int
    var followWakeAlarm: Bool
    var usesCalendarLayout: Bool

    static var `default`: WorkoutSettings {
        WorkoutSettings(
            weekStartsOn: .monday,
            trainingNotes: "Strength lifts with cardio on off days",
            lastDaySplashAt: nil,
            lastWeekEndSplashKey: nil,
            morningNudgeEnabled: true,
            morningNudgeHour: 7,
            morningNudgeMinute: 30,
            followWakeAlarm: true,
            usesCalendarLayout: false
        )
    }

    var weekEndsOn: Weekday {
        weekStartsOn.previous
    }

    var weekRangeLabel: String {
        "\(weekStartsOn.shortTitle) → \(weekEndsOn.shortTitle)"
    }

    var morningNudgeTimeLabel: String {
        let hour12 = morningNudgeHour % 12 == 0 ? 12 : morningNudgeHour % 12
        let period = morningNudgeHour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour12, morningNudgeMinute, period)
    }

    enum CodingKeys: String, CodingKey {
        case weekStartsOn, trainingNotes, lastDaySplashAt, lastWeekEndSplashKey
        case morningNudgeEnabled, morningNudgeHour, morningNudgeMinute, followWakeAlarm
        case usesCalendarLayout
    }

    init(
        weekStartsOn: Weekday,
        trainingNotes: String,
        lastDaySplashAt: Date?,
        lastWeekEndSplashKey: String?,
        morningNudgeEnabled: Bool,
        morningNudgeHour: Int,
        morningNudgeMinute: Int,
        followWakeAlarm: Bool,
        usesCalendarLayout: Bool = false
    ) {
        self.weekStartsOn = weekStartsOn
        self.trainingNotes = trainingNotes
        self.lastDaySplashAt = lastDaySplashAt
        self.lastWeekEndSplashKey = lastWeekEndSplashKey
        self.morningNudgeEnabled = morningNudgeEnabled
        self.morningNudgeHour = morningNudgeHour
        self.morningNudgeMinute = morningNudgeMinute
        self.followWakeAlarm = followWakeAlarm
        self.usesCalendarLayout = usesCalendarLayout
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        weekStartsOn = try container.decodeIfPresent(Weekday.self, forKey: .weekStartsOn) ?? Weekday.monday
        trainingNotes = try container.decodeIfPresent(String.self, forKey: .trainingNotes) ?? ""
        lastDaySplashAt = try container.decodeIfPresent(Date.self, forKey: .lastDaySplashAt)
        lastWeekEndSplashKey = try container.decodeIfPresent(String.self, forKey: .lastWeekEndSplashKey)
        morningNudgeEnabled = try container.decodeIfPresent(Bool.self, forKey: .morningNudgeEnabled) ?? true
        morningNudgeHour = try container.decodeIfPresent(Int.self, forKey: .morningNudgeHour) ?? 7
        morningNudgeMinute = try container.decodeIfPresent(Int.self, forKey: .morningNudgeMinute) ?? 30
        followWakeAlarm = try container.decodeIfPresent(Bool.self, forKey: .followWakeAlarm) ?? true
        usesCalendarLayout = try container.decodeIfPresent(Bool.self, forKey: .usesCalendarLayout) ?? false
    }
}

struct StrengthExercise: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var weightKg: Double
    var notes: String

    init(
        id: UUID = UUID(),
        name: String = "New lift",
        sets: Int = 3,
        reps: Int = 8,
        weightKg: Double = 61.2,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.notes = notes
    }
}

struct StrengthDayPlan: Identifiable, Codable, Hashable {
    let id: UUID
    var weekday: Weekday
    var focus: String
    var isRestDay: Bool
    var exercises: [StrengthExercise]

    init(
        id: UUID = UUID(),
        weekday: Weekday,
        focus: String = "Rest",
        isRestDay: Bool = true,
        exercises: [StrengthExercise] = []
    ) {
        self.id = id
        self.weekday = weekday
        self.focus = focus
        self.isRestDay = isRestDay
        self.exercises = exercises
    }

    var isCardioDay: Bool {
        focus.lowercased() == "cardio"
    }

    var isWorkoutDay: Bool {
        !isOffDay
    }

    var isOffDay: Bool {
        isRestDay || isCardioDay || focus.lowercased() == "rest"
    }

    var dayTypeLabel: String {
        if isCardioDay { return "Cardio day" }
        if isOffDay { return "Rest day" }
        return "Workout day"
    }

    var offDayLabel: String {
        if isCardioDay { return "Cardio" }
        return "Rest"
    }
}

struct StrengthWeekPlan: Codable, Hashable {
    var days: [StrengthDayPlan]

    static var empty: StrengthWeekPlan {
        StrengthWeekPlan(
            days: Weekday.allCases.map { weekday in
                StrengthDayPlan(weekday: weekday)
            }
        )
    }

    static var sample: StrengthWeekPlan {
        StrengthWeekPlan(days: [
            StrengthDayPlan(
                weekday: .monday,
                focus: "Workout",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Bench press", sets: 3, reps: 8, weightKg: 61.2),
                    StrengthExercise(name: "Overhead press", sets: 3, reps: 8, weightKg: 34.0),
                    StrengthExercise(name: "Tricep pushdown", sets: 3, reps: 12, weightKg: 13.6)
                ]
            ),
            StrengthDayPlan(
                weekday: .tuesday,
                focus: "Workout",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Barbell row", sets: 3, reps: 8, weightKg: 43.1),
                    StrengthExercise(name: "Lat pulldown", sets: 3, reps: 10, weightKg: 36.3),
                    StrengthExercise(name: "Dumbbell curl", sets: 3, reps: 12, weightKg: 11.3)
                ]
            ),
            StrengthDayPlan(weekday: .wednesday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(
                weekday: .thursday,
                focus: "Workout",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Back squat", sets: 3, reps: 6, weightKg: 83.9),
                    StrengthExercise(name: "Romanian deadlift", sets: 3, reps: 8, weightKg: 61.2),
                    StrengthExercise(name: "Leg press", sets: 3, reps: 10, weightKg: 90.7)
                ]
            ),
            StrengthDayPlan(
                weekday: .friday,
                focus: "Workout",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Incline bench", sets: 3, reps: 8, weightKg: 52.2),
                    StrengthExercise(name: "Seated row", sets: 3, reps: 10, weightKg: 40.8),
                    StrengthExercise(name: "Lateral raise", sets: 3, reps: 12, weightKg: 6.8)
                ]
            ),
            StrengthDayPlan(weekday: .saturday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(weekday: .sunday, focus: "Rest", isRestDay: true)
        ])
    }
}

struct WorkoutEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var kind: WorkoutKind
    var minutes: Int
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date = .now,
        kind: WorkoutKind = .strength,
        minutes: Int = 45,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.kind = kind
        self.minutes = minutes
        self.notes = notes
    }

    var durationLabel: String {
        if minutes >= 60 {
            let hours = minutes / 60
            let remainder = minutes % 60
            return remainder == 0 ? "\(hours)h" : "\(hours)h \(remainder)m"
        }
        return "\(minutes) min"
    }
}

/// A single thing you did today — a lift with weight, a walk, or any activity.
struct DailyWorkoutActivity: Identifiable, Codable, Hashable {
    let id: UUID
    var kind: DailyWorkoutActivityKind
    var name: String
    var sets: Int
    var reps: Int
    var weightKg: Double
    var minutes: Int
    var notes: String

    init(
        id: UUID = UUID(),
        kind: DailyWorkoutActivityKind = .activity,
        name: String = "",
        sets: Int = 0,
        reps: Int = 0,
        weightKg: Double = 0,
        minutes: Int = 0,
        notes: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.minutes = minutes
        self.notes = notes
    }

    static func lift(name: String, sets: Int, reps: Int, weightKg: Double) -> DailyWorkoutActivity {
        DailyWorkoutActivity(kind: .lift, name: name, sets: sets, reps: reps, weightKg: weightKg)
    }

    static func walk(minutes: Int = 30) -> DailyWorkoutActivity {
        DailyWorkoutActivity(kind: .walk, name: "Walk", minutes: max(1, minutes))
    }

    static func activity(name: String, minutes: Int = 0) -> DailyWorkoutActivity {
        DailyWorkoutActivity(kind: .activity, name: name, minutes: minutes)
    }
}

enum DailyWorkoutActivityKind: String, Codable, CaseIterable {
    case lift
    case walk
    case activity
}

/// What the user actually did on a calendar day (active pick or passive end-of-day log).
struct DailyWorkoutLog: Identifiable, Codable, Hashable {
    let id: UUID
    var day: Date
    var focus: String
    var isRestDay: Bool
    var loggedAt: Date
    var wasPassive: Bool
    var finishedExplicitly: Bool
    var activities: [DailyWorkoutActivity]

    init(
        id: UUID = UUID(),
        day: Date = .now,
        focus: String = "Rest",
        isRestDay: Bool = true,
        loggedAt: Date = .now,
        wasPassive: Bool = false,
        finishedExplicitly: Bool = false,
        activities: [DailyWorkoutActivity] = []
    ) {
        self.id = id
        self.day = day
        self.focus = focus
        self.isRestDay = isRestDay
        self.loggedAt = loggedAt
        self.wasPassive = wasPassive
        self.finishedExplicitly = finishedExplicitly
        self.activities = activities
    }

    enum CodingKeys: String, CodingKey {
        case id, day, focus, isRestDay, loggedAt, wasPassive, finishedExplicitly, activities
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        day = try container.decodeIfPresent(Date.self, forKey: .day) ?? .now
        focus = try container.decodeIfPresent(String.self, forKey: .focus) ?? "Rest"
        isRestDay = try container.decodeIfPresent(Bool.self, forKey: .isRestDay) ?? true
        loggedAt = try container.decodeIfPresent(Date.self, forKey: .loggedAt) ?? .now
        wasPassive = try container.decodeIfPresent(Bool.self, forKey: .wasPassive) ?? false
        finishedExplicitly = try container.decodeIfPresent(Bool.self, forKey: .finishedExplicitly) ?? false
        activities = try container.decodeIfPresent([DailyWorkoutActivity].self, forKey: .activities) ?? []
    }

    var isCardioDay: Bool {
        focus.lowercased() == "cardio"
    }

    var isOffDay: Bool {
        isRestDay || isCardioDay || focus.lowercased() == "rest"
    }

    var dayTypeLabel: String {
        if isCardioDay { return "Cardio" }
        if isOffDay { return "Rest" }
        return focus
    }
}

/// In-progress pick for today; last selection wins and is saved passively at day end.
struct TodayWorkoutPick: Codable, Hashable {
    var dayKey: String
    var focus: String
    var isRestDay: Bool
    var pickedAt: Date
    var activities: [DailyWorkoutActivity]

    init(
        dayKey: String,
        focus: String,
        isRestDay: Bool,
        pickedAt: Date = .now,
        activities: [DailyWorkoutActivity] = []
    ) {
        self.dayKey = dayKey
        self.focus = focus
        self.isRestDay = isRestDay
        self.pickedAt = pickedAt
        self.activities = activities
    }

    enum CodingKeys: String, CodingKey {
        case dayKey, focus, isRestDay, pickedAt, activities
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dayKey = try container.decode(String.self, forKey: .dayKey)
        focus = try container.decodeIfPresent(String.self, forKey: .focus) ?? "Rest"
        isRestDay = try container.decodeIfPresent(Bool.self, forKey: .isRestDay) ?? true
        pickedAt = try container.decodeIfPresent(Date.self, forKey: .pickedAt) ?? .now
        activities = try container.decodeIfPresent([DailyWorkoutActivity].self, forKey: .activities) ?? []
    }

    var isCardioDay: Bool {
        focus.lowercased() == "cardio"
    }

    var isOffDay: Bool {
        isRestDay || isCardioDay || focus.lowercased() == "rest"
    }
}
