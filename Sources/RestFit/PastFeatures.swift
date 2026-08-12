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
enum PastFeatures {
    static let note = "Meditation, Journal, Pomodoro, and To-Do were previous RestFit features. Source remains in the project for a future restore."
}
