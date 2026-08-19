import SwiftUI

struct StrengthPlanView: View {
    @Environment(WellnessStore.self) private var store
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }
    var onProfile: () -> Void = {}
    @State private var selectedDay: Weekday = .monday
    @State private var showComposer = false
    @State private var showSettings = false
    @State private var editingExercise: StrengthExercise?
    @State private var customFocus = ""
    @State private var visibleMonth = Date()
    @State private var selectedDate = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppHeader(section: "Workout", onProfile: onProfile)

                HStack {
                    Spacer()
                    Text(store.weeklyWorkoutLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RestFitTheme.mint)
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.body)
                            .foregroundStyle(RestFitTheme.mint)
                            .padding(8)
                            .background(RestFitTheme.mint.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                if !store.isWorkingOut {
                    layoutToggle
                        .padding(.horizontal, 24)
                }

                if store.isWorkingOut {
                    sessionCard
                        .padding(.horizontal, 24)
                    if store.activeWorkoutKind == .strength {
                        todayLiftsCard
                            .padding(.horizontal, 24)
                    }
                } else {
                    if store.usesWorkoutCalendar {
                        AeroWorkoutCalendar(
                            selectedDay: $selectedDay,
                            visibleMonth: $visibleMonth,
                            onSelect: selectCalendarDay
                        )
                        .padding(.horizontal, 24)
                    } else {
                        weekCard
                            .padding(.horizontal, 24)
                    }
                    if isViewingToday && store.hasFinishedTodaySession {
                        editTodaySessionLink
                            .padding(.horizontal, 24)
                        finishedForDayCard
                            .padding(.horizontal, 24)
                    } else {
                        dayCard
                            .padding(.horizontal, 24)
                        startCard
                            .padding(.horizontal, 24)
                    }
                    // PastFeatures: TodayWorkoutCard + dailyWorkoutHistoryCard — see PastFeatures.swift
                    workoutActivityChartsCard
                        .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, keyboard.isPresented ? 360.0 : AppLayout.scrollTailPadding)
        }
        .onAppear {
            selectedDay = store.todayWeekday
            selectedDate = Date()
            visibleMonth = Date()
            customFocus = store.strengthDay(for: selectedDay).focus
        }
        .sheet(isPresented: $showComposer) {
            StrengthExerciseSheet(
                weekday: selectedDay,
                exercise: editingExercise
            )
            .environment(store)
        }
        .sheet(isPresented: $showSettings) {
            WorkoutSettingsView()
                .environment(store)
        }
    }

    private var selectedPlan: StrengthDayPlan {
        store.strengthDay(for: selectedDay)
    }

    private var isViewingToday: Bool {
        selectedPlan.weekday == store.todayWeekday
    }

    private var layoutToggle: some View {
        HStack(spacing: 0) {
            layoutChip("Compact", calendar: false)
            layoutChip("Calendar", calendar: true)
        }
        .padding(3)
        .background(Color.white.opacity(0.08))
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), RestFitTheme.mint.opacity(0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        )
        .clipShape(Capsule())
    }

    private func layoutChip(_ title: String, calendar: Bool) -> some View {
        let selected = store.usesWorkoutCalendar == calendar
        return Button {
            store.setUsesWorkoutCalendar(calendar)
        } label: {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(selected ? RestFitTheme.canvas : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected ? RestFitTheme.mint : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func selectCalendarDay(_ day: WorkoutMonthDay) {
        selectedDay = day.weekday
        selectedDate = day.date
        customFocus = store.strengthDay(for: day.weekday).focus
    }

    private var weekCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This week")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(WorkoutCalendar.compactDateTimeTitle(store.now))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RestFitTheme.mint)
                    }
                    Spacer()
                    Text(store.workoutSettings.weekRangeLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RestFitTheme.muted)
                }
                Text(store.workoutSettings.trainingNotes.isEmpty
                     ? "Set each day as Rest, Cardio, or Workout."
                     : store.workoutSettings.trainingNotes)
                    .font(.caption)
                    .foregroundStyle(RestFitTheme.muted)

                HStack(spacing: 6) {
                    ForEach(store.weekDayOrder) { day in
                        dayChip(day)
                    }
                }
            }
        }
    }

    private var dayCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedPlan.weekday.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(store.usesWorkoutCalendar
                             ? WorkoutCalendar.dayTitle(selectedDate)
                             : selectedPlan.dayTypeLabel)
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.mint)
                    }
                    Spacer()
                    if selectedPlan.weekday == store.todayWeekday {
                        Text("TODAY")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(RestFitTheme.canvas)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RestFitTheme.mint)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }

                if store.usesWorkoutCalendar {
                    Text("Sets every \(selectedPlan.weekday.title) in \(WorkoutCalendar.monthTitle(visibleMonth)).")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                }

                Text("Day type")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RestFitTheme.muted)

                HStack(spacing: 8) {
                    dayTypeChip("Rest")
                    dayTypeChip("Cardio")
                    dayTypeChip("Workout")
                }

                if selectedPlan.isOffDay {
                    Text(selectedPlan.isCardioDay
                         ? "Cardio day. Start a session when you're ready, or switch to Rest."
                         : "Full rest day. Switch to Cardio if you want active recovery.")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                } else {
                    HStack(alignment: .bottom, spacing: 10) {
                        AeroTextField(
                            title: "Workout name",
                            text: $customFocus,
                            mode: AeroKeyboardMode.text,
                            placeholder: "Push, Pull, Legs...",
                            minHeight: 48.0
                        )
                        Button("Save") {
                            let name = customFocus.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty else { return }
                            let lower = name.lowercased()
                            store.setStrengthFocus(
                                selectedDay,
                                focus: name,
                                isRestDay: lower == "rest" || lower == "cardio"
                            )
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RestFitTheme.mint)
                        .padding(.bottom, 14)
                    }

                    if selectedPlan.exercises.isEmpty {
                        Text("No lifts yet. Add the movements and working weights for this day.")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(selectedPlan.exercises) { exercise in
                                exerciseEditorRow(exercise)
                            }
                        }
                    }

                    Button {
                        editingExercise = nil
                        showComposer = true
                    } label: {
                        Text("Add lift")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(RestFitTheme.canvas)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RestFitTheme.mint)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var startCard: some View {
        let day = selectedPlan
        return SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(day.weekday == store.todayWeekday ? "Today's session" : "\(day.weekday.title) session")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                if day.isCardioDay {
                    Text("\(day.weekday.title) is a cardio day. Go for a run, bike, or walk.")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                    Button {
                        store.startWorkout(.cardio)
                    } label: {
                        Text("Start Cardio")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(RestFitTheme.canvas)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RestFitTheme.mint)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    if isViewingToday {
                        finishForDayButton
                    }
                } else if day.isOffDay {
                    Text("\(day.weekday.title) is a rest day. Recover, or switch to Cardio for active recovery.")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                    if isViewingToday {
                        finishForDayButton
                    }
                } else {
                    Text("\(day.focus) · \(day.exercises.count) lifts")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                    Button {
                        store.startWorkout(.strength)
                    } label: {
                        Text("Start Workout")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(RestFitTheme.canvas)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RestFitTheme.mint)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    if isViewingToday {
                        finishForDayButton
                    }
                }
            }
        }
    }

    private var editTodaySessionLink: some View {
        HStack {
            Button {
                store.reopenTodaySessionForEditing()
            } label: {
                Text("Edit today's workout")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RestFitTheme.mint)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var finishedForDayCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's session")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                Text(store.todayFinishedSessionLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RestFitTheme.mint)
                Text("Come back tomorrow for your next workout!")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var finishForDayButton: some View {
        Button {
            store.finishTodaySession()
        } label: {
            Text("Finished for the day")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RestFitTheme.line)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private var sessionCard: some View {
        let isStrength = store.activeWorkoutKind == .strength
        return SurfaceCard {
            VStack(spacing: 16) {
                Text(isStrength ? store.todayStrengthDay.focus : (store.activeWorkoutKind?.title ?? "Workout"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RestFitTheme.mint)
                Text(store.workoutTimerLabel)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(isStrength ? "Follow the weights you set for today" : "Session in progress")
                    .font(.caption)
                    .foregroundStyle(RestFitTheme.muted)

                HStack(spacing: 12) {
                    Button {
                        store.cancelWorkout()
                    } label: {
                        Text("Cancel")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RestFitTheme.line)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.finishWorkout()
                    } label: {
                        Text("Finish")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(RestFitTheme.canvas)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RestFitTheme.mint)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var workoutActivityChartsCard: some View {
        let points = store.workoutWeekChartPoints
        let labels = points.map(\.label)
        let hasData = points.contains { point in
            point.cardioMinutes > 0 || point.workoutMinutes > 0 || point.dayType != .none
        }

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly activity")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Last 7 days")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                }

                if !hasData {
                    Text("Finish a session or mark your day done to start filling in these charts.")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What you did each day")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RestFitTheme.muted)
                    DailyTypeStripChart(points: points)
                        .frame(height: 88)
                    chartLegend
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Cardio")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RestFitTheme.muted)
                        Spacer()
                        Text("\(points.reduce(0) { $0 + $1.cardioMinutes }) min total")
                            .font(.caption2)
                            .foregroundStyle(RestFitTheme.faint)
                    }
                    BarTrendChart(
                        values: points.map { Double($0.cardioMinutes) },
                        labels: labels,
                        color: RestFitTheme.coral
                    )
                    .frame(height: 100)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Workouts")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RestFitTheme.muted)
                        Spacer()
                        Text("\(points.reduce(0) { $0 + $1.workoutMinutes }) min total")
                            .font(.caption2)
                            .foregroundStyle(RestFitTheme.faint)
                    }
                    BarTrendChart(
                        values: points.map { Double($0.workoutMinutes) },
                        labels: labels,
                        color: RestFitTheme.mint
                    )
                    .frame(height: 100)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rest days")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RestFitTheme.muted)
                    BarTrendChart(
                        values: points.map { $0.isRestDay ? 1.0 : 0.0 },
                        labels: labels,
                        color: RestFitTheme.faint
                    )
                    .frame(height: 88)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("All activity")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RestFitTheme.muted)
                    StackedMinutesChart(
                        cardioValues: points.map { Double($0.cardioMinutes) },
                        workoutValues: points.map { Double($0.workoutMinutes) },
                        labels: labels
                    )
                    .frame(height: 100)
                    HStack(spacing: 16) {
                        chartLegendItem(color: RestFitTheme.coral, title: "Cardio min")
                        chartLegendItem(color: RestFitTheme.mint, title: "Workout min")
                    }
                }
            }
        }
    }

    private var chartLegend: some View {
        HStack(spacing: 16) {
            chartLegendItem(color: RestFitTheme.faint, title: "Rest")
            chartLegendItem(color: RestFitTheme.coral, title: "Cardio")
            chartLegendItem(color: RestFitTheme.mint, title: "Workout")
        }
    }

    private func chartLegendItem(color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .font(.caption2)
                .foregroundStyle(RestFitTheme.faint)
        }
    }

    private var todayLiftsCard: some View {
        let today = store.todayStrengthDay
        return SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's lifts")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)

                if today.exercises.isEmpty {
                    Text("No lifts planned. Add them on this day's plan.")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                } else {
                    ForEach(today.exercises) { exercise in
                        sessionLiftRow(exercise)
                    }
                }
            }
        }
    }

    private func dayChip(_ day: Weekday) -> some View {
        let plan = store.strengthDay(for: day)
        let selected = selectedDay == day
        let dotColor: Color = {
            if plan.isCardioDay { return RestFitTheme.coral }
            if plan.isOffDay { return RestFitTheme.faint }
            return RestFitTheme.mint
        }()
        return Button {
            selectedDay = day
            customFocus = plan.focus
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
                customFocus = "Rest"
                store.setStrengthFocus(selectedDay, focus: "Rest", isRestDay: true)
            case "Cardio":
                customFocus = "Cardio"
                store.setStrengthFocus(selectedDay, focus: "Cardio", isRestDay: true)
            default:
                let name = customFocus.trimmingCharacters(in: .whitespacesAndNewlines)
                let focus = (name.isEmpty || name.lowercased() == "rest" || name.lowercased() == "cardio")
                    ? "Workout"
                    : name
                customFocus = focus
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

    private func exerciseEditorRow(_ exercise: StrengthExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    editingExercise = exercise
                    showComposer = true
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("\(exercise.sets)×\(exercise.reps)")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Button {
                    store.deleteStrengthExercise(selectedDay, id: exercise.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.faint)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text("Weight")
                    .font(.caption)
                    .foregroundStyle(RestFitTheme.muted)
                Spacer()
                Button {
                    store.adjustStrengthWeight(selectedDay, id: exercise.id, deltaDisplay: -store.liftWeightStep)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(RestFitTheme.mint)
                }
                .buttonStyle(.plain)

                Text(store.liftWeightLabel(exercise.weightKg))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 72)

                Button {
                    store.adjustStrengthWeight(selectedDay, id: exercise.id, deltaDisplay: store.liftWeightStep)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(RestFitTheme.mint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sessionLiftRow(_ exercise: StrengthExercise) -> some View {
        let done = store.isStrengthExerciseDone(exercise.id)
        return Button {
            store.toggleStrengthExerciseDone(exercise.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(done ? RestFitTheme.mint : RestFitTheme.faint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(done ? RestFitTheme.muted : .white)
                    Text(store.liftPrescription(exercise))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RestFitTheme.mint)
                }

                Spacer()
            }
            .padding(12)
            .background(RestFitTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct StrengthExerciseSheet: View {
    @Environment(WellnessStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let weekday: Weekday
    var exercise: StrengthExercise?
    @State private var name = "New lift"
    @State private var sets = 3
    @State private var reps = 8
    @State private var weightText = "45"

    var body: some View {
        NavigationStack {
            Form {
                TextField("Lift name", text: $name)
                HStack {
                    Text("Sets")
                    Spacer()
                    Button {
                        sets = max(1, sets - 1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(RestFitTheme.mint)
                    }
                    .buttonStyle(.plain)
                    Text("\(sets)")
                        .frame(minWidth: 28)
                    Button {
                        sets = min(10, sets + 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(RestFitTheme.mint)
                    }
                    .buttonStyle(.plain)
                }
                HStack {
                    Text("Reps")
                    Spacer()
                    Button {
                        reps = max(1, reps - 1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(RestFitTheme.mint)
                    }
                    .buttonStyle(.plain)
                    Text("\(reps)")
                        .frame(minWidth: 28)
                    Button {
                        reps = min(30, reps + 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(RestFitTheme.mint)
                    }
                    .buttonStyle(.plain)
                }
                TextField("Weight in \(store.weightUnitLabel)", text: $weightText)
            }
            .navigationTitle(exercise == nil ? "Add lift" : "Edit lift")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
        .onAppear {
            if let exercise {
                name = exercise.name
                sets = exercise.sets
                reps = exercise.reps
                weightText = store.usesPounds
                    ? String(format: "%.0f", store.displayWeight(exercise.weightKg))
                    : String(format: "%.1f", store.displayWeight(exercise.weightKg))
            } else {
                weightText = store.usesPounds ? "45" : "20"
            }
        }
    }

    private func save() {
        let parsed = Double(weightText) ?? (store.usesPounds ? 45.0 : 20.0)
        let weightKg = store.kilogramsFromDisplay(max(0.0, parsed))
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if var existing = exercise {
            existing.name = trimmed.isEmpty ? "Lift" : trimmed
            existing.sets = sets
            existing.reps = reps
            existing.weightKg = weightKg
            store.updateStrengthExercise(weekday, exercise: existing)
        } else {
            store.addStrengthExercise(
                weekday,
                exercise: StrengthExercise(
                    name: trimmed.isEmpty ? "Lift" : trimmed,
                    sets: sets,
                    reps: reps,
                    weightKg: weightKg
                )
            )
        }
        dismiss()
    }
}
