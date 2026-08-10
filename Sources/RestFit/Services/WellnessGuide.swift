import Foundation

enum WellnessGuide {
    static func greeting(for date: Date = .now, name: String) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Good morning, \(name)"
        case 12..<17: return "Good afternoon, \(name)"
        case 17..<22: return "Good evening, \(name)"
        default: return "Good night, \(name)"
        }
    }

    static func rhythmHeadline(sleepScores: [Int], fastingProgress: Double) -> String {
        let avgSleep = sleepScores.isEmpty ? 0 : sleepScores.reduce(0, +) / sleepScores.count
        if avgSleep >= 80 && fastingProgress >= 0.5 {
            return "Your circadian rhythm\nis looking balanced."
        }
        if avgSleep < 70 {
            return "Your sleep needs\na little attention."
        }
        if fastingProgress < 0.3 {
            return "You're early in today's fast.\nStay hydrated."
        }
        return "You're making steady\nwellness progress."
    }

    static func tips(
        profile: WellnessProfile,
        fastingProgress: Double,
        isFasting: Bool,
        sleepEntries: [SleepEntry],
        weightEntries: [WeightEntry]
    ) -> [WellnessGuidance] {
        var tips: [WellnessGuidance] = []

        if isFasting {
            if fastingProgress >= 0.85 {
                tips.append(WellnessGuidance(
                    title: "Almost there",
                    message: "You're in the fat-burning zone. Plan a balanced first meal with protein and fiber.",
                    priority: 1,
                    icon: "flame.fill"
                ))
            } else if fastingProgress < 0.25 {
                tips.append(WellnessGuidance(
                    title: "Hydration check",
                    message: "Drink water or herbal tea. Black coffee is fine during your fast.",
                    priority: 2,
                    icon: "drop.fill"
                ))
            }
        } else {
            tips.append(WellnessGuidance(
                title: "Eating window",
                message: "Focus on whole foods and stop eating 2–3 hours before bed for better sleep.",
                priority: 2,
                icon: "fork.knife"
            ))
        }

        let recentSleep = sleepEntries.sorted { $0.date > $1.date }.prefix(7)
        if let last = recentSleep.first {
            if last.durationMinutes < 420 {
                tips.append(WellnessGuidance(
                    title: "Sleep recovery",
                    message: "You logged \(last.durationLabel) last night. Aim for 7–9 hours tonight.",
                    priority: 1,
                    icon: "moon.fill"
                ))
            } else if last.qualityScore >= 85 {
                tips.append(WellnessGuidance(
                    title: "Great sleep",
                    message: "Your sleep quality is strong. Keep a consistent bedtime tonight.",
                    priority: 3,
                    icon: "sparkles"
                ))
            }
        }

        if let latest = weightEntries.sorted(by: { $0.date > $1.date }).first {
            let delta = latest.kilograms - profile.targetWeightKg
            if delta > 0 {
                tips.append(WellnessGuidance(
                    title: "Weight journey",
                    message: String(format: "%.1f kg to your target. Consistency beats speed.", delta),
                    priority: 2,
                    icon: "scalemass.fill"
                ))
            } else {
                tips.append(WellnessGuidance(
                    title: "Target reached",
                    message: "You're at or below your goal weight. Focus on maintenance habits.",
                    priority: 3,
                    icon: "checkmark.circle.fill"
                ))
            }
        }

        return tips.sorted { $0.priority < $1.priority }
    }

    static func sleepTrendPercent(scores: [Int]) -> String {
        guard scores.count >= 2 else { return "+0%" }
        let recent = Double(scores.suffix(3).reduce(0, +)) / Double(min(3, scores.count))
        let prior = Double(scores.dropLast(3).suffix(3).reduce(0, +)) / Double(max(1, min(3, scores.count - 3)))
        guard prior > 0 else { return "+0%" }
        let change = ((recent - prior) / prior) * 100
        return String(format: "%+.1f%%", change)
    }

    static func weightDelta(entries: [WeightEntry]) -> String {
        guard entries.count >= 2 else { return "0 kg" }
        let sorted = entries.sorted { $0.date < $1.date }
        let delta = sorted.last!.kilograms - sorted.first!.kilograms
        return String(format: "%+.1f kg", delta)
    }

    static let meditationTip = WellnessGuidance(
        title: "Daily stillness",
        message: "Even 5 minutes of breath focus can lower cortisol and improve sleep quality tonight.",
        priority: 2,
        icon: "leaf.fill"
    )
}
