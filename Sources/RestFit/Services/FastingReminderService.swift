import Foundation
import UserNotifications

enum FastingReminderService {
    static let fastCompleteID = "restfit.fast.complete"
    static let mealWindowID = "restfit.meal.window"
    static let hydrationID = "restfit.hydration"

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            logger.error("Notification authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    static func scheduleFastingReminders(
        isFasting: Bool,
        startedAt: Date?,
        targetHours: Double,
        remindersEnabled: Bool
    ) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(withIdentifiers: [
            fastCompleteID, mealWindowID, hydrationID
        ])

        guard remindersEnabled, isFasting, let startedAt else { return }

        let targetSeconds = targetHours * 3600
        let completeDate = startedAt.addingTimeInterval(targetSeconds)
        let hydrationDate = startedAt.addingTimeInterval(2 * 3600)

        await schedule(
            id: hydrationID,
            title: "Stay hydrated",
            body: "You're 2 hours into your fast. Water and herbal tea are your friends.",
            date: hydrationDate
        )

        await schedule(
            id: fastCompleteID,
            title: "Fast complete!",
            body: "You've reached your fasting goal. Time to break your fast mindfully.",
            date: completeDate
        )

        await schedule(
            id: mealWindowID,
            title: "Eating window open",
            body: "Your fast is done. Log your meal and plan tonight's sleep.",
            date: completeDate.addingTimeInterval(60)
        )
    }

    private static func schedule(id: String, title: String, body: String, date: Date) async {
        guard date > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            logger.error("Failed to schedule \(id): \(error.localizedDescription)")
        }
    }

    static func schedulePomodoroCompletion(phase: PomodoroPhase, remainingSeconds: TimeInterval) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(withIdentifiers: ["restfit.pomodoro.complete"])
        guard remainingSeconds > 1 else { return }

        let title: String
        let body: String
        switch phase {
        case .focus:
            title = "Focus complete"
            body = "Nice work. Take a short break and stretch."
        case .shortBreak:
            title = "Break over"
            body = "Ready for another focus block?"
        case .longBreak:
            title = "Long break over"
            body = "You earned that rest. Start a fresh cycle when you're ready."
        }

        await schedule(
            id: "restfit.pomodoro.complete",
            title: title,
            body: body,
            date: Date().addingTimeInterval(remainingSeconds)
        )
    }

    static func cancelPomodoroCompletion() async {
        await UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["restfit.pomodoro.complete"])
    }

    static func cancelAlarm(id: String) async {
        await UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id])
    }

    static let morningWorkoutID = "restfit.workout.morning"
    static let wakeWorkoutID = "restfit.workout.wakeup"

    static func scheduleMorningWorkoutNudge(
        enabled: Bool,
        hour: Int,
        minute: Int,
        title: String,
        body: String
    ) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(withIdentifiers: [morningWorkoutID])
        guard enabled else { return }
        guard let fireDate = nextAlarmDate(hour: hour, minute: minute) else { return }
        await schedule(
            id: morningWorkoutID,
            title: title,
            body: body,
            date: fireDate
        )
    }

    static func scheduleWakeUpWorkoutNudge(title: String, body: String, delaySeconds: TimeInterval = 120) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(withIdentifiers: [wakeWorkoutID])
        await schedule(
            id: wakeWorkoutID,
            title: title,
            body: body,
            date: Date().addingTimeInterval(delaySeconds)
        )
    }

    static func rescheduleAlarms(_ alarms: [AlarmItem]) async {
        for alarm in alarms {
            await cancelAlarm(id: alarm.notificationID)
            guard alarm.isEnabled else { continue }
            guard let fireDate = nextAlarmDate(hour: alarm.hour, minute: alarm.minute) else { continue }
            let suffix = alarm.repeatsDaily ? "Repeats daily" : "One time"
            await schedule(
                id: alarm.notificationID,
                title: alarm.label,
                body: "\(alarm.timeLabel) · \(suffix)",
                date: fireDate
            )
        }
    }

    static func nextAlarmDate(hour: Int, minute: Int, from date: Date = .now) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        guard let today = Calendar.current.date(from: components) else { return nil }
        if today > date {
            return today
        }
        return Calendar.current.date(byAdding: .day, value: 1, to: today)
    }
}
