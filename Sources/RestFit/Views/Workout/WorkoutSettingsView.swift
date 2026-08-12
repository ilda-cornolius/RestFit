import SwiftUI

struct WorkoutSettingsView: View {
    @Environment(WellnessStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var weekStartsOn: Weekday = .monday
    @State private var selectedDay: Weekday = .monday
    @State private var trainingNotes = ""
    @State private var morningNudgeEnabled = true
    @State private var followWakeAlarm = true
    @State private var nudgeHour = 7
    @State private var nudgeMinute = 30

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Set each day as Rest, Cardio, or Workout. Then choose when your week starts.")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Weekly schedule")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("Tap a day, then choose what kind of day it is.")
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.muted)

                            HStack(spacing: 6) {
                                ForEach(orderedWeekDays) { day in
                                    scheduleDayChip(day)
                                }
                            }

                            HStack {
                                Text(selectedDay.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(store.strengthDay(for: selectedDay).dayTypeLabel)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RestFitTheme.mint)
                            }

                            HStack(spacing: 8) {
                                dayTypeChip("Rest")
                                dayTypeChip("Cardio")
                                dayTypeChip("Workout")
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Week starts on")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("This only sets the start of your training week — not the day type.")
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.muted)

                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    startChip(.sunday)
                                    startChip(.monday)
                                    startChip(.tuesday)
                                    startChip(.wednesday)
                                }
                                HStack(spacing: 8) {
                                    startChip(.thursday)
                                    startChip(.friday)
                                    startChip(.saturday)
                                }
                            }

                            HStack {
                                Text("Week ends on")
                                    .font(.caption)
                                    .foregroundStyle(RestFitTheme.muted)
                                Spacer()
                                Text(weekStartsOn.previous.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RestFitTheme.mint)
                            }

                            Text("\(weekStartsOn.shortTitle) → \(weekStartsOn.previous.shortTitle)")
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.faint)
                        }
                    }
                    .padding(.horizontal, 24)

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What you do")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("A short note for your training style. Shown on the workout page.")
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.muted)
                            TextField("Rest, cardio, and workout mix…", text: $trainingNotes)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 24)

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Morning encouragement")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("Nudge yourself after waking so today's Rest, Cardio, or Workout plan stays top of mind.")
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.muted)

                            Toggle(isOn: $morningNudgeEnabled) {
                                Text("Daily workout reminder")
                                    .foregroundStyle(.white)
                            }
                            .tint(RestFitTheme.mint)

                            if morningNudgeEnabled {
                                Toggle(isOn: $followWakeAlarm) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Follow wake-up alarm")
                                            .foregroundStyle(.white)
                                        Text("Sends about 30 minutes after your Wake up alarm")
                                            .font(.caption)
                                            .foregroundStyle(RestFitTheme.muted)
                                    }
                                }
                                .tint(RestFitTheme.mint)

                                if !followWakeAlarm {
                                    HStack {
                                        Text("Reminder time")
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Button {
                                            nudgeMinute -= 15
                                            if nudgeMinute < 0 {
                                                nudgeMinute = 45
                                                nudgeHour = (nudgeHour + 23) % 24
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(RestFitTheme.mint)
                                        }
                                        .buttonStyle(.plain)

                                        Text(nudgeTimeLabel)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(.white)
                                            .frame(minWidth: 72)

                                        Button {
                                            nudgeMinute += 15
                                            if nudgeMinute >= 60 {
                                                nudgeMinute = 0
                                                nudgeHour = (nudgeHour + 1) % 24
                                            }
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(RestFitTheme.mint)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Button {
                        store.updateWorkoutSettings(
                            weekStartsOn: weekStartsOn,
                            trainingNotes: trainingNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                            morningNudgeEnabled: morningNudgeEnabled,
                            morningNudgeHour: nudgeHour,
                            morningNudgeMinute: nudgeMinute,
                            followWakeAlarm: followWakeAlarm
                        )
                        dismiss()
                    } label: {
                        Text("Save settings")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(RestFitTheme.canvas)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RestFitTheme.mint)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .background(RestFitTheme.canvas.ignoresSafeArea())
            .navigationTitle("Workout settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            weekStartsOn = store.workoutSettings.weekStartsOn
            selectedDay = store.todayWeekday
            trainingNotes = store.workoutSettings.trainingNotes
            morningNudgeEnabled = store.workoutSettings.morningNudgeEnabled
            followWakeAlarm = store.workoutSettings.followWakeAlarm
            nudgeHour = store.workoutSettings.morningNudgeHour
            nudgeMinute = store.workoutSettings.morningNudgeMinute
        }
        .preferredColorScheme(.dark)
    }

    private var orderedWeekDays: [Weekday] {
        Weekday.ordered(startingAt: weekStartsOn)
    }

    private var selectedPlan: StrengthDayPlan {
        store.strengthDay(for: selectedDay)
    }

    private var nudgeTimeLabel: String {
        let hour12 = nudgeHour % 12 == 0 ? 12 : nudgeHour % 12
        let period = nudgeHour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour12, nudgeMinute, period)
    }

    private func scheduleDayChip(_ day: Weekday) -> some View {
        let selected = selectedDay == day
        let plan = store.strengthDay(for: day)
        let dotColor: Color = {
            if plan.isCardioDay { return RestFitTheme.coral }
            if plan.isOffDay { return RestFitTheme.faint }
            return RestFitTheme.mint
        }()
        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 4) {
                Text(day.shortTitle)
                    .font(.caption2.weight(.bold))
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
            }
            .foregroundStyle(selected ? RestFitTheme.canvas : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? RestFitTheme.mint : RestFitTheme.line.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func dayTypeChip(_ title: String) -> some View {
        let selected: Bool = {
            switch title {
            case "Rest": return selectedPlan.offDayLabel == "Rest" && selectedPlan.isOffDay && !selectedPlan.isCardioDay
            case "Cardio": return selectedPlan.isCardioDay
            default: return selectedPlan.isWorkoutDay
            }
        }()
        return Button {
            switch title {
            case "Rest":
                store.setStrengthFocus(selectedDay, focus: "Rest", isRestDay: true)
            case "Cardio":
                store.setStrengthFocus(selectedDay, focus: "Cardio", isRestDay: true)
            default:
                let current = selectedPlan.focus
                let focus = (selectedPlan.isOffDay || current.lowercased() == "rest" || current.lowercased() == "cardio")
                    ? "Workout"
                    : current
                store.setStrengthFocus(selectedDay, focus: focus, isRestDay: false)
            }
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? RestFitTheme.canvas : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? RestFitTheme.mint : RestFitTheme.line.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func startChip(_ day: Weekday) -> some View {
        let selected = weekStartsOn == day
        return Button {
            weekStartsOn = day
        } label: {
            Text(day.shortTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? RestFitTheme.canvas : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? RestFitTheme.mint : RestFitTheme.line.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}