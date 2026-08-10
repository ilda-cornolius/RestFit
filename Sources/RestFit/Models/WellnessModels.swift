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

    init(id: UUID = UUID(), date: Date = .now, durationMinutes: Int = 465, qualityScore: Int = 80) {
        self.id = id
        self.date = date
        self.durationMinutes = durationMinutes
        self.qualityScore = qualityScore
    }

    var durationLabel: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        return "\(hours)h \(minutes)m"
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

struct WellnessProfile: Codable {
    var name: String
    var targetWeightKg: Double
    var fastingProtocol: FastingProtocol
    var fastingStreakDays: Int
    var hasCompletedOnboarding: Bool
    var remindersEnabled: Bool

    static let `default` = WellnessProfile(
        name: "Maria",
        targetWeightKg: 65.0,
        fastingProtocol: .sixteenEight,
        fastingStreakDays: 14,
        hasCompletedOnboarding: false,
        remindersEnabled: true
    )
}

struct WellnessGuidance: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let message: String
    let priority: Int
    let icon: String
}

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
