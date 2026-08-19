import SwiftUI

private enum WorkoutActivityChartMode: String, CaseIterable {
    case overview = "Overview"
    case cardio = "Cardio"
    case workouts = "Workouts"
    case combined = "All"
}

private struct MintStepperButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(RestFitTheme.mint)
                    .frame(width: 30, height: 30)
                Text(symbol)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RestFitTheme.canvas)
            }
        }
        .buttonStyle(.plain)
    }
}

struct StrengthPlanView: View {
    @Environment(WellnessStore.self) private var store
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }
    var onProfile: () -> Void = {}
    @State private var selectedDay: Weekday = .monday
    @State private var showSettings = false
    @State private var customFocus = ""
    @State private var visibleMonth = Date()
    @State private var selectedDate = Date()
    @State private var activityChartMode: WorkoutActivityChartMode = .overview
    @State private var activeWorkoutDay: Weekday?
    @State private var sessionDetailsVisible = false
    @State private var draftLiftName = ""
    @State private var draftLiftSets = 3
    @State private var draftLiftReps = 8
    @State private var draftLiftWeight = ""

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

                ZStack {
                    if store.isWorkingOut {
                        workoutSessionContent
                            .transition(AppLayout.workoutSessionTransition)
                    } else {
                        workoutPlanningContent
                            .transition(AppLayout.workoutSessionTransition)
                    }
                }
                .animation(AppLayout.workoutSessionAnimation, value: store.isWorkingOut)
            }
            .padding(.bottom, keyboard.isPresented ? 360.0 : AppLayout.scrollTailPadding)
            .animation(AppLayout.keyboardAnimation, value: keyboard.isPresented)
        }
        .onAppear {
            selectedDay = store.todayWeekday
            selectedDate = Date()
            visibleMonth = Date()
            customFocus = store.strengthDay(for: selectedDay).focus
            resetDraftLift()
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

    private var workoutPlanningContent: some View {
        VStack(spacing: 20) {
            layoutToggle
                .padding(.horizontal, 24)

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

    private var workoutSessionContent: some View {
        activeWorkoutSessionCard
            .padding(.horizontal, 24)
    }

    private var activeSessionPlan: StrengthDayPlan {
        store.strengthDay(for: activeWorkoutDay ?? selectedDay)
    }

    private func startWorkoutAnimated(_ kind: WorkoutKind) {
        activeWorkoutDay = selectedDay
        sessionDetailsVisible = false
        withAnimation(AppLayout.workoutSessionAnimation) {
            store.startWorkout(kind, weekday: selectedDay)
        }
        withAnimation(AppLayout.workoutSessionAnimation.delay(0.12)) {
            sessionDetailsVisible = true
        }
    }

    private func cancelWorkoutAnimated() {
        withAnimation(AppLayout.workoutSessionAnimation) {
            store.cancelWorkout()
            sessionDetailsVisible = false
            activeWorkoutDay = nil
        }
    }

    private func finishWorkoutAnimated() {
        withAnimation(AppLayout.workoutSessionAnimation) {
            store.finishWorkout()
            sessionDetailsVisible = false
            activeWorkoutDay = nil
        }
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
                            minHeight: 48.0,
                            trailingLabel: "Edit"
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
                        Text("No lifts yet. Add your first movement below.")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(selectedPlan.exercises) { exercise in
                                exerciseEditorRow(exercise)
                            }
                        }
                    }

                    inlineAddLiftSection
                }
            }
        }
    }

    private var inlineAddLiftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add lift")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RestFitTheme.muted)

            AeroTextField(
                title: "Lift name",
                text: $draftLiftName,
                mode: AeroKeyboardMode.text,
                placeholder: "Bench press, Squat, Row...",
                minHeight: 48.0,
                trailingLabel: "Edit"
            )

            HStack(spacing: 10) {
                inlineLiftStepper(title: "Sets", value: draftLiftSets) {
                    draftLiftSets = max(1, draftLiftSets - 1)
                } onIncrement: {
                    draftLiftSets = min(10, draftLiftSets + 1)
                }

                inlineLiftStepper(title: "Reps", value: draftLiftReps) {
                    draftLiftReps = max(1, draftLiftReps - 1)
                } onIncrement: {
                    draftLiftReps = min(30, draftLiftReps + 1)
                }
            }

            AeroTextField(
                title: "Weight in \(store.weightUnitLabel)",
                text: $draftLiftWeight,
                mode: AeroKeyboardMode.decimal,
                placeholder: store.usesPounds ? "45" : "20",
                minHeight: 48.0
            )

            Button {
                addDraftLift()
            } label: {
                Text("Add to plan")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(RestFitTheme.canvas)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RestFitTheme.mint)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RestFitTheme.line, lineWidth: 1)
        )
    }

    private func inlineLiftStepper(
        title: String,
        value: Int,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RestFitTheme.faint)
            HStack {
                MintStepperButton(symbol: "−", action: onDecrement)
                Text("\(value)")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                MintStepperButton(symbol: "+", action: onIncrement)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(RestFitTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func resetDraftLift() {
        draftLiftName = ""
        draftLiftSets = 3
        draftLiftReps = 8
        draftLiftWeight = store.usesPounds ? "45" : "20"
    }

    private func addDraftLift() {
        keyboard.dismiss(force: true)
        let parsed = Double(draftLiftWeight) ?? (store.usesPounds ? 45.0 : 20.0)
        let weightKg = store.kilogramsFromDisplay(max(0.0, parsed))
        let trimmed = draftLiftName.trimmingCharacters(in: .whitespacesAndNewlines)
        store.addStrengthExercise(
            selectedDay,
            exercise: StrengthExercise(
                name: trimmed.isEmpty ? "Lift" : trimmed,
                sets: draftLiftSets,
                reps: draftLiftReps,
                weightKg: weightKg,
                includeWarmUp: true
            )
        )
        resetDraftLift()
    }

    private func updateExercise(_ exercise: StrengthExercise) {
        store.updateStrengthExercise(selectedDay, exercise: exercise)
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
                        startWorkoutAnimated(.cardio)
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

                    if !day.exercises.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(day.exercises) { exercise in
                                HStack(spacing: 10) {
                                    Text(exercise.name)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Spacer(minLength: 8)
                                    Text(store.liftPrescription(exercise))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RestFitTheme.mint)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(RestFitTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }

                    Button {
                        startWorkoutAnimated(.strength)
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

    private var activeWorkoutSessionCard: some View {
        let plan = activeSessionPlan
        let isStrength = store.activeWorkoutKind == .strength
        let lifts = plan.exercises
        let completedSets = store.totalCompletedSets(for: lifts)
        let plannedSets = store.totalPlannedSets(for: lifts)

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isStrength ? plan.focus : (store.activeWorkoutKind?.title ?? "Workout"))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("\(plan.weekday.title) session")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.mint)
                    }
                    Spacer()
                    if isStrength && plannedSets > 0 {
                        Text("\(completedSets)/\(plannedSets) sets")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RestFitTheme.mint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RestFitTheme.mint.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text(store.workoutTimerLabel)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                Group {
                    if isStrength {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(lifts.isEmpty
                                 ? "No lifts planned for this day yet."
                                 : "Tap a lift each time you finish a set.")
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.muted)

                            if lifts.isEmpty {
                                Text("Add lifts on the plan screen after you finish this session.")
                                    .font(.caption)
                                    .foregroundStyle(RestFitTheme.faint)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(lifts) { exercise in
                                        sessionLiftRow(exercise)
                                    }
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session in progress")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RestFitTheme.muted)
                            Text(plan.isCardioDay
                                 ? "Keep moving — run, bike, walk, or whatever you planned for cardio day."
                                 : "Stay with your session until you're ready to finish.")
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.faint)
                        }
                    }
                }
                .opacity(sessionDetailsVisible ? 1.0 : 0.0)
                .offset(y: sessionDetailsVisible ? 0.0 : 10.0)

                HStack(spacing: 12) {
                    Button {
                        cancelWorkoutAnimated()
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
                        finishWorkoutAnimated()
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
        let cardioTotal = points.reduce(0) { $0 + $1.cardioMinutes }
        let workoutTotal = points.reduce(0) { $0 + $1.workoutMinutes }
        let restTotal = points.filter(\.isRestDay).count
        let hasData = points.contains { point in
            point.cardioMinutes > 0 || point.workoutMinutes > 0 || point.dayType != .none
        }

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
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

                HStack(spacing: 8) {
                    activityStatPill(value: "\(cardioTotal)", unit: "min", title: "Cardio", color: RestFitTheme.coral)
                    activityStatPill(value: "\(workoutTotal)", unit: "min", title: "Workouts", color: RestFitTheme.mint)
                    activityStatPill(value: "\(restTotal)", unit: restTotal == 1 ? "day" : "days", title: "Rest", color: RestFitTheme.faint)
                }

                activityChartModeSelector

                Group {
                    switch activityChartMode {
                    case .overview:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What you did each day")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RestFitTheme.muted)
                            DailyTypeStripChart(points: points)
                                .frame(height: 108)
                            chartLegend
                        }
                    case .cardio:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cardio minutes")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RestFitTheme.muted)
                            BarTrendChart(
                                values: points.map { Double($0.cardioMinutes) },
                                labels: labels,
                                color: RestFitTheme.coral
                            )
                            .frame(height: 108)
                            HStack(spacing: 16) {
                                chartLegendItem(color: RestFitTheme.coral, title: "Cardio")
                            }
                        }
                    case .workouts:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Workout minutes")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RestFitTheme.muted)
                            BarTrendChart(
                                values: points.map { Double($0.workoutMinutes) },
                                labels: labels,
                                color: RestFitTheme.mint
                            )
                            .frame(height: 108)
                            HStack(spacing: 16) {
                                chartLegendItem(color: RestFitTheme.mint, title: "Workouts")
                            }
                        }
                    case .combined:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("All activity")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RestFitTheme.muted)
                            StackedMinutesChart(
                                cardioValues: points.map { Double($0.cardioMinutes) },
                                workoutValues: points.map { Double($0.workoutMinutes) },
                                labels: labels
                            )
                            .frame(height: 108)
                            HStack(spacing: 16) {
                                chartLegendItem(color: RestFitTheme.coral, title: "Cardio")
                                chartLegendItem(color: RestFitTheme.mint, title: "Workouts")
                            }
                        }
                    }
                }
                .animation(AppLayout.tabSwitchAnimation, value: activityChartMode)
            }
        }
    }

    private var activityChartModeSelector: some View {
        HStack(spacing: 0) {
            ForEach(WorkoutActivityChartMode.allCases, id: \.self) { mode in
                activityChartModeChip(mode)
            }
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

    private func activityChartModeChip(_ mode: WorkoutActivityChartMode) -> some View {
        let selected = activityChartMode == mode
        return Button {
            withAnimation(AppLayout.tabSwitchAnimation) {
                activityChartMode = mode
            }
        } label: {
            Text(mode.rawValue)
                .font(.caption2.weight(.bold))
                .foregroundStyle(selected ? RestFitTheme.canvas : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected ? RestFitTheme.mint : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func activityStatPill(value: String, unit: String, title: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(RestFitTheme.faint)
            }
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(RestFitTheme.line, lineWidth: 1)
        )
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
        let current = selectedPlan.exercises.first { $0.id == exercise.id } ?? exercise

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(current.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(store.liftPrescription(current))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RestFitTheme.mint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    store.deleteStrengthExercise(selectedDay, id: current.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.faint)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                inlineLiftStepper(title: "Sets", value: current.sets) {
                    var updated = current
                    updated.sets = max(1, current.sets - 1)
                    updateExercise(updated)
                } onIncrement: {
                    var updated = current
                    updated.sets = min(10, current.sets + 1)
                    updateExercise(updated)
                }

                inlineLiftStepper(title: "Reps", value: current.reps) {
                    var updated = current
                    updated.reps = max(1, current.reps - 1)
                    updateExercise(updated)
                } onIncrement: {
                    var updated = current
                    updated.reps = min(30, current.reps + 1)
                    updateExercise(updated)
                }
            }

            HStack {
                Text("Weight")
                    .font(.caption)
                    .foregroundStyle(RestFitTheme.muted)
                Spacer()
                MintStepperButton(symbol: "−") {
                    store.adjustStrengthWeight(selectedDay, id: current.id, deltaDisplay: -store.liftWeightStep)
                }

                Text(store.liftWeightLabel(current.weightKg))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 72)

                MintStepperButton(symbol: "+") {
                    store.adjustStrengthWeight(selectedDay, id: current.id, deltaDisplay: store.liftWeightStep)
                }
            }

            HStack {
                Text("Warm-up sets (0% → 50% → 75%)")
                    .font(.caption)
                    .foregroundStyle(RestFitTheme.muted)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { current.includeWarmUp },
                    set: { val in
                        var updated = current
                        updated.includeWarmUp = val
                        updateExercise(updated)
                    }
                ))
                .labelsHidden()
                .tint(RestFitTheme.mint)
            }
        }
        .padding(12)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sessionLiftRow(_ exercise: StrengthExercise) -> some View {
        let totalTapped  = store.completedSets(for: exercise.id)
        let workingDone  = store.completedWorkingSets(for: exercise)
        let allDone      = store.isStrengthExerciseDone(exercise)
        let warmUps      = exercise.warmUpProgression

        return Button {
            store.tapStrengthSet(for: exercise)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: allDone ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(allDone ? RestFitTheme.mint : RestFitTheme.faint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(allDone ? RestFitTheme.muted : .white)
                        Text("\(exercise.reps) reps @ \(store.liftWeightLabel(exercise.weightKg))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RestFitTheme.mint)
                    }

                    Spacer()

                    Text("\(workingDone)/\(exercise.sets)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(workingDone > 0 ? RestFitTheme.mint : RestFitTheme.faint)
                }

                if !warmUps.isEmpty {
                    Divider().overlay(RestFitTheme.line)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Warm-up")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(RestFitTheme.faint)

                        HStack(spacing: 6) {
                            ForEach(Array(warmUps.enumerated()), id: \.offset) { index, warmUp in
                                let done = totalTapped > index
                                VStack(spacing: 3) {
                                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                        .font(.caption)
                                        .foregroundStyle(done ? RestFitTheme.mint : RestFitTheme.faint)
                                    Text(store.liftWeightLabel(warmUp.weightKg))
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(done ? RestFitTheme.muted : .white)
                                    Text("\(warmUp.reps)r")
                                        .font(.system(size: 9))
                                        .foregroundStyle(RestFitTheme.faint)
                                }
                                .frame(maxWidth: .infinity)
                            }

                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(RestFitTheme.faint)

                            ForEach(0..<exercise.sets, id: \.self) { index in
                                let done = workingDone > index
                                VStack(spacing: 3) {
                                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                        .font(.caption)
                                        .foregroundStyle(done ? RestFitTheme.mint : RestFitTheme.faint)
                                    Text(store.liftWeightLabel(exercise.weightKg))
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(done ? RestFitTheme.muted : .white)
                                    Text("\(exercise.reps)r")
                                        .font(.system(size: 9))
                                        .foregroundStyle(RestFitTheme.faint)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                } else {
                    setProgressDots(completed: workingDone, total: exercise.sets)
                }
            }
            .padding(12)
            .background(RestFitTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func setProgressDots(completed: Int, total: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(0..<total), id: \.self) { index in
                Circle()
                    .fill(index < completed ? RestFitTheme.mint : RestFitTheme.line)
                    .frame(width: 10, height: 10)
            }
            Spacer(minLength: 0)
        }
    }
}
