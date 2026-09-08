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
    /// When the user first started using the app (set at onboarding).
    var firstAppUseAt: Date?

    static let `default` = WellnessProfile(
        name: "",
        targetWeightKg: 65.0,
        fastingProtocol: .sixteenEight,
        fastingStreakDays: 0,
        hasCompletedOnboarding: false,
        remindersEnabled: true,
        weightUnit: .pounds,
        backgroundAnimationEnabled: true,
        firstAppUseAt: nil
    )

    enum CodingKeys: String, CodingKey {
        case name, targetWeightKg, fastingProtocol, fastingStreakDays
        case hasCompletedOnboarding, remindersEnabled, weightUnit
        case backgroundAnimationEnabled, firstAppUseAt
    }

    init(
        name: String,
        targetWeightKg: Double,
        fastingProtocol: FastingProtocol,
        fastingStreakDays: Int,
        hasCompletedOnboarding: Bool,
        remindersEnabled: Bool,
        weightUnit: WeightUnit?,
        backgroundAnimationEnabled: Bool = true,
        firstAppUseAt: Date? = nil
    ) {
        self.name = name
        self.targetWeightKg = targetWeightKg
        self.fastingProtocol = fastingProtocol
        self.fastingStreakDays = fastingStreakDays
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.remindersEnabled = remindersEnabled
        self.weightUnit = weightUnit
        self.backgroundAnimationEnabled = backgroundAnimationEnabled
        self.firstAppUseAt = firstAppUseAt
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
        firstAppUseAt = try container.decodeIfPresent(Date.self, forKey: .firstAppUseAt)
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
    /// 1 = starter lifts migrated to 3×5.
    var liftSchemeVersion: Int

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
            usesCalendarLayout: false,
            liftSchemeVersion: 1
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
        case usesCalendarLayout, liftSchemeVersion
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
        usesCalendarLayout: Bool = false,
        liftSchemeVersion: Int = 1
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
        self.liftSchemeVersion = liftSchemeVersion
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
        liftSchemeVersion = try container.decodeIfPresent(Int.self, forKey: .liftSchemeVersion) ?? 0
    }
}

struct StrengthExercise: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var weightKg: Double
    var notes: String
    var includeWarmUp: Bool
    /// False for bodyweight moves (pull-ups, dips, push-ups) — log sets × reps only.
    var tracksWeight: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, sets, reps, weightKg, notes, includeWarmUp, tracksWeight
    }

    init(
        id: UUID = UUID(),
        name: String = "New lift",
        sets: Int = 3,
        reps: Int = 5,
        weightKg: Double = 61.2,
        notes: String = "",
        includeWarmUp: Bool = true,
        tracksWeight: Bool = true
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.notes = notes
        self.includeWarmUp = includeWarmUp
        self.tracksWeight = tracksWeight
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Lift"
        sets = try container.decodeIfPresent(Int.self, forKey: .sets) ?? 3
        reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? 5
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg) ?? 0.0
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        includeWarmUp = try container.decodeIfPresent(Bool.self, forKey: .includeWarmUp) ?? true
        tracksWeight = try container.decodeIfPresent(Bool.self, forKey: .tracksWeight) ?? true
    }

    /// Deadlift-family lifts start warm-ups from a light bar (~10 display units), not empty.
    var isDeadliftFamily: Bool {
        let lower = name.lowercased()
        return lower.contains("deadlift")
    }

    /// Raw warm-up ratios before plate rounding. Prefer `WellnessStore.warmUpSets(for:)` for display.
    var warmUpProgression: [(weightKg: Double, reps: Int)] {
        guard includeWarmUp, tracksWeight else { return [] }
        // ~10 lb bar for deadlifts when unit is pounds; store re-rounds in display units.
        let barKg = isDeadliftFamily ? (10.0 / 2.2046226218) : 0.0
        return [
            (barKg,           10),
            (weightKg * 0.50, 5),
            (weightKg * 0.75, 3),
        ]
    }

    /// Total taps needed in a session: warm-up count + working sets.
    var totalSessionTaps: Int {
        warmUpProgression.count + sets
    }

    static func normalizedLiftKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

enum LiftNameSuggestions {
    /// Session-row glyph inferred from the lift name (emoji — reliable on Skip/Android).
    static func sessionIcon(for name: String) -> String {
        let n = StrengthExercise.normalizedLiftKey(name)
        if n.contains("bench") || n.contains("chest") || n.contains("fly") || n.contains("push-up") || n.contains("pushup") || n.contains("dip") {
            return "🏋️"
        }
        if n.contains("squat") || n.contains("leg press") || n.contains("lunge") || n.contains("leg extension") || n.contains("leg curl") || n.contains("calf") {
            return "🦵"
        }
        if n.contains("deadlift") || n.contains("rdl") || n.contains("hip thrust") || n.contains("glute") || n.contains("good morning") {
            return "🦾"
        }
        if n.contains("row") || n.contains("pull-up") || n.contains("pullup") || n.contains("chin-up") || n.contains("chinup") || n.contains("pulldown") || n.contains("lat ") {
            return "💪"
        }
        if n.contains("press") || n.contains("shoulder") || n.contains("overhead") || n.contains("military") || n.contains("lateral raise") || n.contains("front raise") || n.contains("rear delt") || n.contains("face pull") {
            return "🙌"
        }
        if n.contains("curl") || n.contains("bicep") || n.contains("tricep") || n.contains("skull") || n.contains("pushdown") {
            return "💪"
        }
        if n.contains("plank") || n.contains("crunch") || n.contains("core") || n.contains("leg raise") || n.contains("ab") {
            return "🧘"
        }
        if n.contains("clean") || n.contains("snatch") || n.contains("thruster") || n.contains("kettlebell") || n.contains("swing") || n.contains("farmer") || n.contains("carry") {
            return "⚡"
        }
        return "🏅"
    }

    static let catalog: [String] = [
        "Bench press", "Incline bench", "Decline bench", "Dumbbell press",
        "Overhead press", "Push-up", "Dip", "Chest fly", "Cable fly",
        "Tricep pushdown", "Skull crusher", "Close-grip bench",
        "Lateral raise", "Front raise", "Rear delt fly", "Face pull",
        "Barbell row", "Dumbbell row", "Seated row", "T-bar row",
        "Lat pulldown", "Pull-up", "Chin-up", "Straight-arm pulldown",
        "Deadlift", "Romanian deadlift", "Sumo deadlift", "Trap bar deadlift",
        "Bicep curl", "Hammer curl", "Preacher curl", "Cable curl",
        "Back squat", "Front squat", "Goblet squat", "Hack squat",
        "Leg press", "Leg curl", "Leg extension", "Lunge",
        "Bulgarian split squat", "Hip thrust", "Glute bridge", "Calf raise",
        "Plank", "Crunch", "Hanging leg raise", "Farmer carry",
        "Clean", "Power clean", "Thruster", "Kettlebell swing"
    ]

    static let workoutNames: [String] = [
        "Push", "Pull", "Legs", "Upper", "Lower", "Full body",
        "Chest", "Back", "Shoulders", "Arms", "Core"
    ]

    static func matching(_ query: String, in catalog: [String], limit: Int = 8) -> [String] {
        var seen: [String] = []
        var unique: [String] = []
        for name in catalog {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            if seen.contains(key) { continue }
            seen.append(key)
            unique.append(trimmed)
        }

        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            if unique.count > limit {
                return Array(unique.prefix(limit))
            }
            return unique
        }

        var prefixHits: [String] = []
        var otherHits: [String] = []
        for name in unique {
            let lower = name.lowercased()
            if lower.hasPrefix(q) {
                prefixHits.append(name)
            } else if lower.contains(q) {
                otherHits.append(name)
            }
        }
        let combined = prefixHits + otherHits
        if combined.count > limit {
            return Array(combined.prefix(limit))
        }
        return combined
    }
}

/// Effort mark after a working set: ++ could have done more, -- was too heavy.
enum LiftSetEffort: String, Codable, Hashable {
    case plusPlus = "++"
    case minusMinus = "--"
    case none = ""
}

/// Tracks how many sets of a lift were completed during an active strength session.
struct CompletedStrengthSet: Codable, Hashable {
    var exerciseID: UUID
    var completedSets: Int
    /// Per working-set effort (`++` / `--` / empty), indexed 0..<working sets done.
    var workingEfforts: [String]

    enum CodingKeys: String, CodingKey {
        case exerciseID, completedSets, workingEfforts
    }

    init(exerciseID: UUID, completedSets: Int, workingEfforts: [String] = []) {
        self.exerciseID = exerciseID
        self.completedSets = completedSets
        self.workingEfforts = workingEfforts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exerciseID = try container.decode(UUID.self, forKey: .exerciseID)
        completedSets = try container.decode(Int.self, forKey: .completedSets)
        workingEfforts = try container.decodeIfPresent([String].self, forKey: .workingEfforts) ?? []
    }
}

/// F1-style best / last lap times for a lift name (synced across the week by name).
struct LiftLapBest: Codable, Hashable, Identifiable {
    var id: String { nameKey }
    var nameKey: String
    var displayName: String
    var bestSeconds: Int
    var lastSeconds: Int
    var updatedAt: Date

    init(
        nameKey: String,
        displayName: String,
        bestSeconds: Int,
        lastSeconds: Int,
        updatedAt: Date = .now
    ) {
        self.nameKey = nameKey
        self.displayName = displayName
        self.bestSeconds = bestSeconds
        self.lastSeconds = lastSeconds
        self.updatedAt = updatedAt
    }
}

/// One finished lift lap inside the current session (shown like a race timing board).
struct SessionLiftLap: Codable, Hashable, Identifiable {
    var id: UUID
    var exerciseID: UUID
    var name: String
    var elapsedSeconds: Int
    var beatBest: Bool
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

    /// Classic Mon/Wed/Fri push-pull-legs with accessories; Tue/Thu lighter; weekends rest.
    static var sample: StrengthWeekPlan { pushPullLegsTemplate }

    static var pushPullLegsTemplate: StrengthWeekPlan {
        StrengthWeekPlan(days: [
            StrengthDayPlan(
                weekday: .monday,
                focus: "Push",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Bench press", sets: 3, reps: 5, weightKg: 61.2),
                    StrengthExercise(name: "Overhead press", sets: 3, reps: 5, weightKg: 34.0),
                    StrengthExercise(name: "Tricep pushdown", sets: 3, reps: 8, weightKg: 13.6)
                ]
            ),
            StrengthDayPlan(
                weekday: .tuesday,
                focus: "Pull",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Deadlift", sets: 3, reps: 5, weightKg: 61.2),
                    StrengthExercise(name: "Barbell row", sets: 3, reps: 5, weightKg: 43.1),
                    StrengthExercise(name: "Lat pulldown", sets: 3, reps: 8, weightKg: 36.3)
                ]
            ),
            StrengthDayPlan(
                weekday: .wednesday,
                focus: "Legs",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Back squat", sets: 3, reps: 5, weightKg: 83.9),
                    StrengthExercise(name: "Romanian deadlift", sets: 3, reps: 5, weightKg: 61.2),
                    StrengthExercise(name: "Leg press", sets: 3, reps: 8, weightKg: 90.7)
                ]
            ),
            StrengthDayPlan(
                weekday: .thursday,
                focus: "Upper",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Incline bench", sets: 3, reps: 8, weightKg: 52.2),
                    StrengthExercise(name: "Seated row", sets: 3, reps: 8, weightKg: 40.8),
                    StrengthExercise(name: "Lateral raise", sets: 3, reps: 12, weightKg: 6.8)
                ]
            ),
            StrengthDayPlan(
                weekday: .friday,
                focus: "Full body",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Deadlift", sets: 3, reps: 5, weightKg: 61.2),
                    StrengthExercise(name: "Bench press", sets: 3, reps: 5, weightKg: 61.2),
                    StrengthExercise(name: "Back squat", sets: 3, reps: 5, weightKg: 83.9)
                ]
            ),
            StrengthDayPlan(weekday: .saturday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(weekday: .sunday, focus: "Rest", isRestDay: true)
        ])
    }

    static var upperLowerTemplate: StrengthWeekPlan {
        StrengthWeekPlan(days: [
            StrengthDayPlan(
                weekday: .monday,
                focus: "Upper",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Bench press", sets: 3, reps: 5, weightKg: 61.2),
                    StrengthExercise(name: "Barbell row", sets: 3, reps: 5, weightKg: 43.1),
                    StrengthExercise(name: "Overhead press", sets: 3, reps: 8, weightKg: 34.0),
                    StrengthExercise(name: "Lat pulldown", sets: 3, reps: 8, weightKg: 36.3)
                ]
            ),
            StrengthDayPlan(
                weekday: .tuesday,
                focus: "Lower",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Back squat", sets: 3, reps: 5, weightKg: 83.9),
                    StrengthExercise(name: "Deadlift", sets: 3, reps: 5, weightKg: 61.2),
                    StrengthExercise(name: "Leg curl", sets: 3, reps: 10, weightKg: 27.2),
                    StrengthExercise(name: "Calf raise", sets: 3, reps: 12, weightKg: 40.8)
                ]
            ),
            StrengthDayPlan(weekday: .wednesday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(
                weekday: .thursday,
                focus: "Upper",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Incline bench", sets: 3, reps: 8, weightKg: 52.2),
                    StrengthExercise(name: "Seated row", sets: 3, reps: 8, weightKg: 40.8),
                    StrengthExercise(name: "Lateral raise", sets: 3, reps: 12, weightKg: 6.8),
                    StrengthExercise(name: "Bicep curl", sets: 3, reps: 10, weightKg: 11.3)
                ]
            ),
            StrengthDayPlan(
                weekday: .friday,
                focus: "Lower",
                isRestDay: false,
                exercises: [
                    StrengthExercise(name: "Front squat", sets: 3, reps: 5, weightKg: 52.2),
                    StrengthExercise(name: "Romanian deadlift", sets: 3, reps: 8, weightKg: 61.2),
                    StrengthExercise(name: "Leg press", sets: 3, reps: 10, weightKg: 90.7),
                    StrengthExercise(name: "Hip thrust", sets: 3, reps: 10, weightKg: 61.2)
                ]
            ),
            StrengthDayPlan(weekday: .saturday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(weekday: .sunday, focus: "Rest", isRestDay: true)
        ])
    }

    static var fullBodyTemplate: StrengthWeekPlan {
        let lifts = [
            StrengthExercise(name: "Back squat", sets: 3, reps: 5, weightKg: 83.9),
            StrengthExercise(name: "Bench press", sets: 3, reps: 5, weightKg: 61.2),
            StrengthExercise(name: "Deadlift", sets: 3, reps: 5, weightKg: 61.2),
            StrengthExercise(name: "Overhead press", sets: 3, reps: 8, weightKg: 34.0)
        ]
        return StrengthWeekPlan(days: [
            StrengthDayPlan(weekday: .monday, focus: "Full body", isRestDay: false, exercises: lifts.map {
                StrengthExercise(name: $0.name, sets: $0.sets, reps: $0.reps, weightKg: $0.weightKg)
            }),
            StrengthDayPlan(weekday: .tuesday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(weekday: .wednesday, focus: "Full body", isRestDay: false, exercises: lifts.map {
                StrengthExercise(name: $0.name, sets: $0.sets, reps: $0.reps, weightKg: $0.weightKg)
            }),
            StrengthDayPlan(weekday: .thursday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(weekday: .friday, focus: "Full body", isRestDay: false, exercises: lifts.map {
                StrengthExercise(name: $0.name, sets: $0.sets, reps: $0.reps, weightKg: $0.weightKg)
            }),
            StrengthDayPlan(weekday: .saturday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(weekday: .sunday, focus: "Rest", isRestDay: true)
        ])
    }

    /// Starting Strength–style novice linear progression (Phase 2 A/B), Mon/Wed/Fri.
    /// Public program structure (Rippetoe); weights are starter placeholders — add load each session.
    static var startingStrengthTemplate: StrengthWeekPlan {
        let workoutA = [
            StrengthExercise(name: "Back squat", sets: 3, reps: 5, weightKg: 43.1),
            StrengthExercise(name: "Overhead press", sets: 3, reps: 5, weightKg: 20.4),
            StrengthExercise(name: "Deadlift", sets: 1, reps: 5, weightKg: 61.2)
        ]
        let workoutB = [
            StrengthExercise(name: "Back squat", sets: 3, reps: 5, weightKg: 43.1),
            StrengthExercise(name: "Bench press", sets: 3, reps: 5, weightKg: 34.0),
            StrengthExercise(name: "Power clean", sets: 5, reps: 3, weightKg: 34.0)
        ]
        return StrengthWeekPlan(days: [
            StrengthDayPlan(weekday: .monday, focus: "SS A", isRestDay: false, exercises: workoutA.map {
                StrengthExercise(name: $0.name, sets: $0.sets, reps: $0.reps, weightKg: $0.weightKg)
            }),
            StrengthDayPlan(weekday: .tuesday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(weekday: .wednesday, focus: "SS B", isRestDay: false, exercises: workoutB.map {
                StrengthExercise(name: $0.name, sets: $0.sets, reps: $0.reps, weightKg: $0.weightKg)
            }),
            StrengthDayPlan(weekday: .thursday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(weekday: .friday, focus: "SS A", isRestDay: false, exercises: workoutA.map {
                StrengthExercise(name: $0.name, sets: $0.sets, reps: $0.reps, weightKg: $0.weightKg)
            }),
            StrengthDayPlan(weekday: .saturday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(weekday: .sunday, focus: "Rest", isRestDay: true)
        ])
    }

    /// StrongLifts 5×5–style A/B on Mon/Wed/Fri.
    static var strongLiftsTemplate: StrengthWeekPlan {
        let workoutA = [
            StrengthExercise(name: "Back squat", sets: 5, reps: 5, weightKg: 43.1),
            StrengthExercise(name: "Bench press", sets: 5, reps: 5, weightKg: 34.0),
            StrengthExercise(name: "Barbell row", sets: 5, reps: 5, weightKg: 34.0)
        ]
        let workoutB = [
            StrengthExercise(name: "Back squat", sets: 5, reps: 5, weightKg: 43.1),
            StrengthExercise(name: "Overhead press", sets: 5, reps: 5, weightKg: 20.4),
            StrengthExercise(name: "Deadlift", sets: 1, reps: 5, weightKg: 61.2)
        ]
        return StrengthWeekPlan(days: [
            StrengthDayPlan(weekday: .monday, focus: "SL 5x5 A", isRestDay: false, exercises: workoutA.map {
                StrengthExercise(name: $0.name, sets: $0.sets, reps: $0.reps, weightKg: $0.weightKg)
            }),
            StrengthDayPlan(weekday: .tuesday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(weekday: .wednesday, focus: "SL 5x5 B", isRestDay: false, exercises: workoutB.map {
                StrengthExercise(name: $0.name, sets: $0.sets, reps: $0.reps, weightKg: $0.weightKg)
            }),
            StrengthDayPlan(weekday: .thursday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(weekday: .friday, focus: "SL 5x5 A", isRestDay: false, exercises: workoutA.map {
                StrengthExercise(name: $0.name, sets: $0.sets, reps: $0.reps, weightKg: $0.weightKg)
            }),
            StrengthDayPlan(weekday: .saturday, focus: "Rest", isRestDay: true),
            StrengthDayPlan(weekday: .sunday, focus: "Rest", isRestDay: true)
        ])
    }
}

/// Named, curated strength programs users can load onto the week plan.
struct WorkoutProgram: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let schedule: String
    let plan: StrengthWeekPlan
}

enum WorkoutProgramCatalog {
    /// Built-in programs based on well-known public routines (not live web downloads).
    static let all: [WorkoutProgram] = [
        WorkoutProgram(
            id: "starting-strength",
            name: "Starting Strength",
            summary: "Novice barbell linear progression. Alternates Workout A and B. Squat every session; add weight when you hit all reps.",
            schedule: "Mon A · Wed B · Fri A (rest Tue/Thu/weekend)",
            plan: .startingStrengthTemplate
        ),
        WorkoutProgram(
            id: "stronglifts",
            name: "StrongLifts 5×5",
            summary: "Three big lifts per day, 5 sets of 5 (deadlift 1×5). Simple A/B progression for beginners.",
            schedule: "Mon A · Wed B · Fri A",
            plan: .strongLiftsTemplate
        ),
        WorkoutProgram(
            id: "push-pull-legs",
            name: "Push / Pull / Legs",
            summary: "Bro-split style week with dedicated push, pull, legs, plus upper and full-body days.",
            schedule: "Mon–Fri training · weekend rest",
            plan: .pushPullLegsTemplate
        ),
        WorkoutProgram(
            id: "upper-lower",
            name: "Upper / Lower",
            summary: "Four training days alternating upper and lower body.",
            schedule: "Mon Upper · Tue Lower · Thu Upper · Fri Lower",
            plan: .upperLowerTemplate
        ),
        WorkoutProgram(
            id: "full-body",
            name: "Full body (3 days)",
            summary: "Same compound session three times a week with rest days between.",
            schedule: "Mon · Wed · Fri",
            plan: .fullBodyTemplate
        )
    ]
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

/// One day of data for workout-tab activity charts (last 7 days).
struct WorkoutDayChartPoint: Identifiable, Hashable {
    let dayKey: String
    let label: String
    let cardioMinutes: Int
    let workoutMinutes: Int
    let dayType: WorkoutChartDayType

    var id: String { dayKey }

    var isRestDay: Bool { dayType == .rest }

    enum WorkoutChartDayType: String, Hashable {
        case rest
        case cardio
        case workout
        case none
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
    /// Per working-set effort marks (`++` / `--` / empty), copied from the session on finish.
    var workingEfforts: [String]

    init(
        id: UUID = UUID(),
        kind: DailyWorkoutActivityKind = .activity,
        name: String = "",
        sets: Int = 0,
        reps: Int = 0,
        weightKg: Double = 0,
        minutes: Int = 0,
        notes: String = "",
        workingEfforts: [String] = []
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.minutes = minutes
        self.notes = notes
        self.workingEfforts = workingEfforts
    }

    enum CodingKeys: String, CodingKey {
        case id, kind, name, sets, reps, weightKg, minutes, notes, workingEfforts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try container.decodeIfPresent(DailyWorkoutActivityKind.self, forKey: .kind) ?? DailyWorkoutActivityKind.activity
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        sets = try container.decodeIfPresent(Int.self, forKey: .sets) ?? 0
        reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? 0
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg) ?? 0.0
        minutes = try container.decodeIfPresent(Int.self, forKey: .minutes) ?? 0
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        workingEfforts = try container.decodeIfPresent([String].self, forKey: .workingEfforts) ?? []
    }

    static func lift(
        name: String,
        sets: Int,
        reps: Int,
        weightKg: Double,
        workingEfforts: [String] = []
    ) -> DailyWorkoutActivity {
        DailyWorkoutActivity(
            kind: .lift,
            name: name,
            sets: sets,
            reps: reps,
            weightKg: weightKg,
            workingEfforts: workingEfforts
        )
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
