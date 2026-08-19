/// Past features that were built, then taken out of the UI.
///
/// Keep this note so they can be wired back later without starting from scratch.
///
/// ## Meditation (Calm tab)
/// Guided sessions with a live timer, weekly minutes chart, and session history.
///
/// Files still in the project:
/// - `Views/Meditation/MeditationView.swift`
/// - Models: `MeditationPreset`, `MeditationEntry`
/// - Store: `meditationEntries`, `startMeditation`, `endMeditation`
///
/// To restore: add a `meditate` case back to `AppTab` and show `MeditationView()` in `ContentView`.
///
/// ## Journal
/// Mood + title + note entries, with add/edit/delete.
///
/// Files still in the project:
/// - `Views/Tools/JournalView.swift`
/// - Models: `JournalMood`, `JournalEntry`
/// - Store: `journalEntries`, `addJournalEntry`, `updateJournalEntry`, `deleteJournalEntry`
///
/// To restore: add a dedicated tab or a row on the Workout/Alarm screens.
///
/// ## Pomodoro
/// Focus/break timer with 25/5, 50/10, and 15/3 presets, plus session history.
///
/// Files still in the project:
/// - `Views/Tools/PomodoroView.swift`
/// - Models: `PomodoroPhase`, `PomodoroSettings`, `PomodoroSession`
/// - Store: `startPomodoro`, `pausePomodoro`, `resetPomodoro`
///
/// To restore: add a dedicated tab or a row on the Workout/Alarm screens.
///
/// ## To-Do
/// Add, complete, delete, and clear daily tasks.
///
/// Files still in the project:
/// - `Views/Tools/TodoListView.swift`
/// - Models: `TodoItem`
/// - Store: `todoItems`, `addTodo`, `toggleTodo`, `deleteTodo`
///
/// To restore: add a dedicated tab or a row on the Workout/Alarm screens.
///
/// ## Today I'm doing (daily workout log)
/// Pick Rest / Cardio / a named workout for today, log lifts with weights or walks,
/// and see “What you did this week.” Last pick auto-finalizes at night (~10 PM) or
/// when the calendar day rolls over; opening the app the next day starts a fresh pick.
/// Data stays on-device with the signed-in user (`dailyWorkoutLogs`, `todayWorkoutPick`
/// in `PersistedState` / wellness JSON).
///
/// Files still in the project:
/// - `Views/Workout/TodayWorkoutCard.swift` (`TodayWorkoutCard`, `WeightCheckInSheet`)
/// - Models: `DailyWorkoutActivity`, `DailyWorkoutActivityKind`, `DailyWorkoutLog`, `TodayWorkoutPick`
/// - Store: `pickTodayWorkout`, `addTodayLift`, `addTodayWalk`, `addTodayActivity`,
///   `removeTodayWorkoutActivity`, `dailyWorkoutLog(for:)`, `recentDailyWorkoutLogs`,
///   `normalizeTodayWorkoutPick`, `checkDailyWorkoutOnTick`, `finalizeWorkoutDay`
///
/// To restore in `StrengthPlanView` (when not in a live workout session):
/// ```swift
/// TodayWorkoutCard()
///     .padding(.horizontal, 24)
/// // …
/// DailyWorkoutHistoryCard()
///     .padding(.horizontal, 24)
/// ```
/// Desired behavior when restoring: each day’s last pick saves to the user’s
/// associated on-device store; next calendar day resets the active pick.
enum PastFeatures {
    static let note = "Meditation, Journal, Pomodoro, To-Do, and Today I'm doing were previous Stella Fit features. Source remains in the project for a future restore."
}
