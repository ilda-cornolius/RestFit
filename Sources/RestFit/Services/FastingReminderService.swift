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
}
