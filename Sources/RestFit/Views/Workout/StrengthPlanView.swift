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
                    .frame(width: 28.0, height: 28.0)
                Text(symbol)
                    .font(.body.weight(.bold))
                    .foregroundStyle(RestFitTheme.canvas)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Session clock that ticks in isolation so the lift list doesn't rebuild every second.
private struct SessionWorkoutClock: View {
    let startedAt: Date?
    @State private var now = Date()

    var body: some View {
        Text(label)
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .task(id: startedAt?.timeIntervalSince1970 ?? 0) {
                while !Task.isCancelled {
                    now = Date()
                    try? await Task.sleep(for: .seconds(1))
                }
            }
    }

    private var label: String {
        guard let startedAt else { return "00:00:00" }
        let total = max(0, Int(now.timeIntervalSince(startedAt)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

private enum LiveSecondsStyle {
    case minutesSeconds
    case hoursMinutesSeconds
}

/// Live elapsed label with its own 1s tick (keeps parent views calm).
private struct LiveSecondsLabel: View {
    let startedAt: Date
    var style: LiveSecondsStyle = .minutesSeconds
    @State private var now = Date()

    var body: some View {
        Text(label)
            .task(id: startedAt.timeIntervalSince1970) {
                while !Task.isCancelled {
                    now = Date()
                    try? await Task.sleep(for: .seconds(1))
                }
            }
    }

    private var label: String {
        let total = max(0, Int(now.timeIntervalSince(startedAt)))
        switch style {
        case .minutesSeconds:
            return String(format: "%02d:%02d", total / 60, total % 60)
        case .hoursMinutesSeconds:
            return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
        }
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
    @State private var draftLiftName = ""
    @State private var draftLiftSets: Int = 3
    @State private var draftLiftReps: Int = 5
    @State private var draftLiftWeight = ""
    @State private var draftTracksWeight = true
    @State private var showAddLift = false
    /// Bumped when a set is completed so the rest timer + mini-game shuffle restart.
    @State private var restKick = 0
    @State private var liftSplashName: String?
    @State private var showTemplatePicker = false
    /// Defer heavy charts so the workout tab appears quickly.
    @State private var showActivityCharts = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppHeader(section: "Workout", onProfile: onProfile)

                if !store.isWorkingOut {
                    weekHeader
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                } else {
                    Color.clear.frame(height: 8)
                }

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
                .padding(.top, 4)

                ZStack {
                    if store.isWorkingOut {
                        workoutSessionContent
                            .transition(AppLayout.workoutSessionTransition)
                    } else {
                        workoutPlanningContent
                            .transition(AppLayout.workoutSessionTransition)
                    }

                    if let splash = liftSplashName {
                        liftFinishedSplash(name: splash)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .animation(AppLayout.workoutSessionAnimation, value: store.isWorkingOut)
                .animation(.easeOut(duration: 0.25), value: liftSplashName)
            }
            .padding(.bottom, keyboard.isPresented ? 360.0 : AppLayout.scrollTailPadding)
        }
        .onAppear {
            selectedDay = store.todayWeekday
            selectedDate = Date()
            visibleMonth = Date()
            customFocus = store.strengthDay(for: selectedDay).focus
            resetDraftLift()
            restoreWorkoutSessionChrome()
            if !showActivityCharts {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(60))
                    withAnimation(.easeOut(duration: 0.28)) {
                        showActivityCharts = true
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            WorkoutSettingsView()
                .environment(store)
        }
        .sheet(isPresented: $showTemplatePicker) {
            WorkoutProgramPickerSheet { program in
                store.applyStrengthTemplate(program.plan)
                selectNextTrainingDay()
                customFocus = store.strengthDay(for: selectedDay).focus
                showTemplatePicker = false
            }
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
                weekDayChips
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
            if showActivityCharts {
                workoutActivityChartsCard
                    .padding(.horizontal, 24)
                    .transition(.opacity)
            }
        }
    }

    private var workoutSessionContent: some View {
        activeWorkoutSessionCard
            .padding(.horizontal, 24)
    }

    private var activeSessionPlan: StrengthDayPlan {
        store.strengthDay(for: store.activeWorkoutWeekday ?? activeWorkoutDay ?? selectedDay)
    }

    /// Incomplete lifts stay on top (deck order); finished lifts sink to the bottom.
    private var sessionLiftDeck: [StrengthExercise] {
        let lifts = activeSessionPlan.exercises
        let active = lifts.filter { !store.isStrengthExerciseDone($0) }
        let done = lifts.filter { store.isStrengthExerciseDone($0) }
        return active + done
    }

    private var sessionLiftDeckOrderKey: String {
        sessionLiftDeck.map { exercise in
            "\(exercise.id.uuidString):\(store.isStrengthExerciseDone(exercise) ? "1" : "0")"
        }.joined(separator: "|")
    }

    /// Tab switches and app resume recreate this view, which resets local @State.
    /// The store still has the live session (timer, kind, weekday) — bring the lifts back.
    private func restoreWorkoutSessionChrome() {
        guard store.isWorkingOut else { return }
        activeWorkoutDay = store.activeWorkoutWeekday ?? store.todayWeekday
    }

    private func startWorkoutAnimated(_ kind: WorkoutKind) {
        let day = kind == .strength ? dayToStartStrengthSession : selectedDay
        selectedDay = day
        activeWorkoutDay = day
        customFocus = store.strengthDay(for: day).focus
        withAnimation(AppLayout.workoutSessionAnimation) {
            store.startWorkout(kind, weekday: day)
        }
    }

    /// Prefer the selected day if it has lifts; otherwise the next planned training day.
    private var dayToStartStrengthSession: Weekday {
        let selected = store.strengthDay(for: selectedDay)
        if !selected.isOffDay, !selected.exercises.isEmpty {
            return selectedDay
        }
        return nextTrainingWeekday(from: selectedDay) ?? selectedDay
    }

    private func nextTrainingWeekday(from start: Weekday) -> Weekday? {
        let order = store.weekDayOrder
        guard let startIndex = order.firstIndex(of: start) else { return nil }
        for offset in 0..<order.count {
            let day = order[(startIndex + offset) % order.count]
            let plan = store.strengthDay(for: day)
            if !plan.isOffDay, !plan.exercises.isEmpty {
                return day
            }
        }
        return nil
    }

    private func selectNextTrainingDay() {
        if let day = nextTrainingWeekday(from: store.todayWeekday) {
            selectedDay = day
        } else if let day = nextTrainingWeekday(from: .monday) {
            selectedDay = day
        }
    }

    private func cancelWorkoutAnimated() {
        withAnimation(AppLayout.workoutSessionAnimation) {
            store.cancelWorkout()
            activeWorkoutDay = nil
        }
    }

    private func finishWorkoutAnimated() {
        withAnimation(AppLayout.workoutSessionAnimation) {
            store.finishWorkout()
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
        showAddLift = false
        keyboard.dismiss(force: true)
    }

    private var weekHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This week")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    Text(WorkoutCalendar.compactDateTimeTitle(store.now))
                        .font(.title3.weight(.bold))
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
                .padding(.top, 2)

            Button {
                showTemplatePicker = true
            } label: {
                Text("Load program")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RestFitTheme.canvas)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RestFitTheme.mint)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
    }

    private var weekDayChips: some View {
        HStack(spacing: 6) {
            ForEach(store.weekDayOrder) { day in
                dayChip(day)
            }
        }
    }

    private var dayCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(selectedPlan.weekday.title)
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                        if store.usesWorkoutCalendar {
                            Text(WorkoutCalendar.dayTitle(selectedDate))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(RestFitTheme.mint)
                        }
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
                            trailingLabel: "Edit",
                            suggestions: LiftNameSuggestions.workoutNames
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
                        Text("No lifts yet. Tap Add lift to start.")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(selectedPlan.exercises) { exercise in
                                exerciseEditorRow(exercise)
                            }
                        }
                    }

                    if showAddLift {
                        inlineAddLiftSection
                    } else {
                        Button {
                            resetDraftLift()
                            showAddLift = true
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
    }

    private var inlineAddLiftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Add lift")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Button("Cancel") {
                    keyboard.dismiss(force: true)
                    resetDraftLift()
                    showAddLift = false
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(RestFitTheme.mint)
                .buttonStyle(.plain)
            }

            AeroTextField(
                title: "Lift name",
                text: $draftLiftName,
                mode: AeroKeyboardMode.text,
                placeholder: "Pull-ups, Bench, Squat...",
                minHeight: 48.0,
                trailingLabel: "Edit",
                fieldID: "add-lift-name",
                suggestions: knownLiftNames
            )

            HStack(spacing: 10) {
                inlineLiftStepper(title: "Sets", value: $draftLiftSets, minimum: 1, maximum: 10)
                inlineLiftStepper(title: "Reps", value: $draftLiftReps, minimum: 1, maximum: 50)
            }

            liftTrackingModeBar(tracksWeight: draftTracksWeight) { tracksWeight in
                draftTracksWeight = tracksWeight
            }

            if draftTracksWeight {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                    HStack(spacing: 8) {
                        MintStepperButton(symbol: "−", action: {
                            nudgeDraftWeight(-store.liftWeightStep)
                        })
                        typedNumberButton(
                            text: draftLiftWeight,
                            fieldTitle: "Add weight",
                            mode: AeroKeyboardMode.decimal
                        ) { typed in
                            draftLiftWeight = typed
                        }
                        MintStepperButton(symbol: "+", action: {
                            nudgeDraftWeight(store.liftWeightStep)
                        })
                        Text(store.weightUnitLabel)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(RestFitTheme.muted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(RestFitTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

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
        .onAppear {
            resetDraftLift()
        }
    }

    private func inlineLiftStepper(
        title: String,
        value: Binding<Int>,
        minimum: Int,
        maximum: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
            HStack(spacing: 8) {
                MintStepperButton(symbol: "−", action: {
                    value.wrappedValue = max(minimum, value.wrappedValue - 1)
                })
                typedNumberButton(
                    text: "\(value.wrappedValue)",
                    fieldTitle: "Add \(title)",
                    mode: AeroKeyboardMode.number
                ) { typed in
                    guard let parsed = Int(typed) else { return }
                    value.wrappedValue = min(maximum, max(minimum, parsed))
                }
                MintStepperButton(symbol: "+", action: {
                    value.wrappedValue = min(maximum, value.wrappedValue + 1)
                })
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(RestFitTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func planLiftStepper(
        title: String,
        value: Int,
        fieldTitle: String,
        minimum: Int,
        maximum: Int,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
            HStack(spacing: 8) {
                MintStepperButton(symbol: "−", action: {
                    onChange(max(minimum, value - 1))
                })
                typedNumberButton(
                    text: "\(value)",
                    fieldTitle: fieldTitle,
                    mode: AeroKeyboardMode.number
                ) { typed in
                    guard let parsed = Int(typed) else { return }
                    onChange(min(maximum, max(minimum, parsed)))
                }
                MintStepperButton(symbol: "+", action: {
                    onChange(min(maximum, value + 1))
                })
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(RestFitTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func planWeightStepper(_ exercise: StrengthExercise, weekday: Weekday? = nil) -> some View {
        let display = store.displayWeight(exercise.weightKg)
        let text = store.usesPounds
            ? "\(Int(display.rounded()))"
            : String(format: "%.1f", display)
        let fieldTitle = "\(exercise.name) weight"

        return VStack(alignment: .leading, spacing: 8) {
            Text("Weight")
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
            HStack(spacing: 8) {
                MintStepperButton(symbol: "−", action: {
                    store.adjustStrengthWeight(
                        weekday ?? selectedDay,
                        id: exercise.id,
                        deltaDisplay: -store.liftWeightStep
                    )
                })
                typedNumberButton(
                    text: text,
                    fieldTitle: fieldTitle,
                    mode: AeroKeyboardMode.decimal
                ) { typed in
                    applyTypedWeight(typed, to: exercise, weekday: weekday)
                }
                MintStepperButton(symbol: "+", action: {
                    store.adjustStrengthWeight(
                        weekday ?? selectedDay,
                        id: exercise.id,
                        deltaDisplay: store.liftWeightStep
                    )
                })
                Text(store.weightUnitLabel)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(RestFitTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(RestFitTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func typedNumberButton(
        text: String,
        fieldTitle: String,
        mode: AeroKeyboardMode,
        onTyped: @escaping (String) -> Void
    ) -> some View {
        let isActive = keyboard.isPresented && keyboard.activeFieldTitle == fieldTitle
        return Button {
            keyboard.present(
                title: fieldTitle,
                text: text,
                mode: mode,
                placeholder: text,
                onChange: onTyped
            )
        } label: {
            Text(text)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 36.0)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isActive ? RestFitTheme.mint : RestFitTheme.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func applyTypedWeight(_ text: String, to exercise: StrengthExercise, weekday: Weekday? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let parsed = Double(trimmed), parsed >= 0.0 else { return }
        var updated = exercise
        updated.weightKg = store.kilogramsFromDisplay(parsed)
        updateExercise(updated, weekday: weekday)
    }

    private var knownLiftNames: [String] {
        var names = LiftNameSuggestions.catalog
        for day in store.strengthPlan.days {
            for exercise in day.exercises {
                names.append(exercise.name)
            }
        }
        return names
    }

    private func resetDraftLift() {
        draftLiftName = ""
        draftLiftSets = 3
        draftLiftReps = 5
        draftLiftWeight = store.usesPounds ? "45" : "20"
        draftTracksWeight = true
    }

    private func nudgeDraftWeight(_ delta: Double) {
        let current = Double(draftLiftWeight) ?? (store.usesPounds ? 45.0 : 20.0)
        let next = max(0.0, current + delta)
        if store.usesPounds {
            draftLiftWeight = "\(Int(next.rounded()))"
        } else {
            draftLiftWeight = String(format: "%.1f", next)
        }
    }

    private func addDraftLift() {
        keyboard.dismiss(force: true)
        let trimmed = draftLiftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let isDeadlift = StrengthExercise(name: trimmed.isEmpty ? "Lift" : trimmed).isDeadliftFamily
        let fallbackDisplay = isDeadlift ? 10.0 : (store.usesPounds ? 45.0 : 20.0)
        let parsed = Double(draftLiftWeight) ?? fallbackDisplay
        let weightKg = draftTracksWeight ? store.kilogramsFromDisplay(max(0.0, parsed)) : 0.0
        store.addStrengthExercise(
            selectedDay,
            exercise: StrengthExercise(
                name: trimmed.isEmpty ? "Lift" : trimmed,
                sets: draftLiftSets,
                reps: draftLiftReps,
                weightKg: weightKg,
                includeWarmUp: draftTracksWeight,
                tracksWeight: draftTracksWeight
            )
        )
        resetDraftLift()
        showAddLift = false
    }

    private func updateExercise(_ exercise: StrengthExercise, weekday: Weekday? = nil) {
        store.updateStrengthExercise(weekday ?? selectedDay, exercise: exercise)
    }

    private func liftTrackingModeBar(tracksWeight: Bool, onChange: @escaping (Bool) -> Void) -> some View {
        HStack(spacing: 0) {
            liftTrackingChip("Weight", selected: tracksWeight) {
                onChange(true)
            }
            liftTrackingChip("Reps only", selected: !tracksWeight) {
                onChange(false)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    private func liftTrackingChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(selected ? RestFitTheme.canvas : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? RestFitTheme.mint : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var sessionEditDay: Weekday {
        store.activeWorkoutWeekday ?? activeWorkoutDay ?? selectedDay
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
                    if let next = nextTrainingWeekday(from: day.weekday) {
                        let nextPlan = store.strengthDay(for: next)
                        Text("\(day.weekday.title) is rest. Next session: \(next.title) · \(nextPlan.focus) · \(nextPlan.exercises.count) lifts")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                        Button {
                            selectedDay = next
                            customFocus = nextPlan.focus
                            startWorkoutAnimated(.strength)
                        } label: {
                            Text("Start \(next.title) workout")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(RestFitTheme.canvas)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RestFitTheme.mint)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("\(day.weekday.title) is a rest day. Load a program or add lifts to a training day.")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    }
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
                                    Text(LiftNameSuggestions.sessionIcon(for: exercise.name))
                                        .font(.title2)
                                    Text(exercise.name)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(.white)
                                    Spacer(minLength: 8)
                                    Text(store.liftPrescription(exercise))
                                        .font(.body.weight(.bold))
                                        .foregroundStyle(RestFitTheme.mint)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .background(RestFitTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }

                    Button {
                        startWorkoutAnimated(.strength)
                    } label: {
                        Text(day.exercises.isEmpty ? "Start next training day" : "Start Workout")
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

                SessionWorkoutClock(startedAt: store.workoutStartedAt)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                // Rest timer → lift times → (game). Lifts stay outside so set taps don't rebuild them with rest chrome.
                WorkoutRestMiniGame(restKick: restKick) {
                    if !store.sessionLiftLaps.isEmpty || store.liftLapStartedAt.isEmpty == false {
                        sessionLapBoard
                    }
                }

                if isStrength {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lifts.isEmpty
                             ? "No lifts on this day."
                             : "Finish a lift to send it to the bottom — next lift moves up.")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)

                        if lifts.isEmpty {
                            Text("This day has no lifts (often a rest day). Cancel and start Mon/Wed/Fri after loading a program.")
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.faint)
                            Button {
                                cancelWorkoutAnimated()
                                selectNextTrainingDay()
                            } label: {
                                Text("Go to next training day")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(RestFitTheme.mint)
                            }
                            .buttonStyle(.plain)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(sessionLiftDeck) { exercise in
                                    sessionLiftRow(exercise)
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                                            removal: .opacity.combined(with: .move(edge: .top))
                                        ))
                                }
                            }
                            .animation(.easeInOut(duration: 0.38), value: sessionLiftDeckOrderKey)
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
            showAddLift = false
            keyboard.dismiss(force: true)
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

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Button {
                    let fieldID = "rename-\(current.id.uuidString)"
                    keyboard.present(
                        title: "Lift name",
                        text: current.name,
                        mode: AeroKeyboardMode.text,
                        placeholder: "Bench press",
                        fieldID: fieldID,
                        suggestions: knownLiftNames,
                        onChange: { typed in
                            let trimmed = typed.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            var updated = current
                            updated.name = trimmed
                            updateExercise(updated)
                        }
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(current.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Edit")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RestFitTheme.mint)
                        }
                        Text(store.liftPrescription(current))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(RestFitTheme.mint)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Button {
                    store.deleteStrengthExercise(selectedDay, id: current.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.title)
                        .foregroundStyle(RestFitTheme.faint)
                        .padding(10)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                planLiftStepper(
                    title: "Sets",
                    value: current.sets,
                    fieldTitle: "\(current.name) sets",
                    minimum: 1,
                    maximum: 10
                ) { next in
                    var updated = current
                    updated.sets = next
                    updateExercise(updated)
                }

                planLiftStepper(
                    title: "Reps",
                    value: current.reps,
                    fieldTitle: "\(current.name) reps",
                    minimum: 1,
                    maximum: 50
                ) { next in
                    var updated = current
                    updated.reps = next
                    updateExercise(updated)
                }
            }

            liftTrackingModeBar(tracksWeight: current.tracksWeight) { tracksWeight in
                var updated = current
                updated.tracksWeight = tracksWeight
                if !tracksWeight {
                    updated.includeWarmUp = false
                    updated.weightKg = 0.0
                }
                updateExercise(updated)
            }

            if current.tracksWeight {
                planWeightStepper(current)

                HStack {
                    Text("Warm-up sets (deadlift starts at 10; rounded to plates)")
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
        }
        .padding(12)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var activeInProgressLaps: [StrengthExercise] {
        activeSessionPlan.exercises.filter { exercise in
            store.liftLapStartedAt[exercise.id] != nil && !store.isStrengthExerciseDone(exercise)
        }
    }

    private var sessionLapBoard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lift times")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RestFitTheme.muted)

            ForEach(store.sessionLiftLaps) { lap in
                HStack {
                    Text(lap.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    if lap.beatBest {
                        Text("PB")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(RestFitTheme.canvas)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RestFitTheme.mint)
                            .clipShape(Capsule())
                    }
                    Text(store.lapTimeLabel(lap.elapsedSeconds))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RestFitTheme.mint)
                }
            }

            ForEach(activeInProgressLaps) { exercise in
                HStack {
                    Text(exercise.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RestFitTheme.faint)
                    Spacer()
                    if let best = store.bestLapSeconds(forLiftNamed: exercise.name) {
                        Text("best \(store.lapTimeLabel(best))")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(RestFitTheme.faint)
                    }
                    if let started = store.liveLiftLapStartDate(for: exercise) {
                        LiveSecondsLabel(startedAt: started, style: .minutesSeconds)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    } else {
                        Text(store.lapTimeLabel(store.liftLapElapsedSeconds(for: exercise) ?? 0))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(10)
        .background(RestFitTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func liftFinishedSplash(name: String) -> some View {
        VStack(spacing: 12) {
            Text("Lift complete")
                .font(.caption.weight(.bold))
                .foregroundStyle(RestFitTheme.mint)
            Text(name)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            if let lap = store.sessionLiftLaps.first(where: { $0.name == name }) {
                Text(store.lapTimeLabel(lap.elapsedSeconds))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(RestFitTheme.mint)
                if lap.beatBest {
                    Text("New personal best")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RestFitTheme.coral)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 280)
        .background(RestFitTheme.card.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.45).ignoresSafeArea())
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(1.8))
                await MainActor.run {
                    if liftSplashName == name {
                        liftSplashName = nil
                    }
                }
            }
        }
        .onTapGesture {
            liftSplashName = nil
        }
    }

    private func sessionLiftRow(_ exercise: StrengthExercise) -> some View {
        let totalTapped  = store.completedSets(for: exercise.id)
        let workingDone  = store.completedWorkingSets(for: exercise)
        let allDone      = store.isStrengthExerciseDone(exercise)
        let warmUps      = store.warmUpSets(for: exercise)
        let live = store.strengthDay(for: sessionEditDay).exercises.first { $0.id == exercise.id } ?? exercise
        let lapSeconds = store.liftLapElapsedSeconds(for: live)
        let bestSeconds = store.bestLapSeconds(forLiftNamed: live.name)
        let lastWorkingIndex: Int? = workingDone > 0 ? workingDone - 1 : nil
        let lastEffort = lastWorkingIndex.map {
            store.workingSetEffort(for: live, workingIndex: $0)
        } ?? LiftSetEffort.none

        return VStack(alignment: .leading, spacing: 10) {
            Button {
                registerSessionSetTap(for: live)
            } label: {
                HStack(spacing: 12) {
                    Text(LiftNameSuggestions.sessionIcon(for: live.name))
                        .font(.system(size: 28.0))
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(live.name)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(allDone ? RestFitTheme.muted : .white)
                        Text(
                            live.tracksWeight
                                ? "\(live.reps) reps @ \(store.liftWeightLabel(live.weightKg))"
                                : "\(live.reps) reps"
                        )
                            .font(.body.weight(.bold))
                            .foregroundStyle(RestFitTheme.mint)

                        if let started = store.liveLiftLapStartDate(for: live) {
                            HStack(spacing: 8) {
                                LiveSecondsLabel(startedAt: started, style: .minutesSeconds)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                if let bestSeconds {
                                    Text("best \(store.lapTimeLabel(bestSeconds))")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(RestFitTheme.faint)
                                }
                            }
                        } else if let lapSeconds {
                            HStack(spacing: 8) {
                                Text(store.lapTimeLabel(lapSeconds))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                if let bestSeconds {
                                    Text("best \(store.lapTimeLabel(bestSeconds))")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(RestFitTheme.faint)
                                }
                            }
                        }
                    }

                    Spacer()

                    setCheckMark(done: allDone)
                    Text("\(workingDone)/\(live.sets)")
                        .font(.body.weight(.bold))
                        .foregroundStyle(workingDone > 0 ? RestFitTheme.mint : RestFitTheme.faint)
                }
                .frame(minHeight: 52)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            if !warmUps.isEmpty {
                Divider().overlay(RestFitTheme.line)
                    .padding(.top, 10)

                VStack(alignment: .leading, spacing: 16) {
                    Text(live.isDeadliftFamily
                         ? "Warm-up (10 → 50% → 75%, plates)"
                         : "Warm-up (0% → 50% → 75%, plates)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RestFitTheme.faint)
                        .padding(.top, 4)
                        .padding(.bottom, 8)

                    HStack(alignment: .top, spacing: 2) {
                        ForEach(Array(warmUps.enumerated()), id: \.offset) { index, warmUp in
                            let done = totalTapped > index
                            Button {
                                registerSessionSetTap(for: live)
                            } label: {
                                VStack(spacing: 6) {
                                    setCheckMark(done: done)
                                    Text(store.liftWeightLabel(warmUp.weightKg))
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(done ? RestFitTheme.muted : .white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.55)
                                        .padding(.top, 2)
                                    Text("\(warmUp.reps)r")
                                        .font(.system(size: 9))
                                        .foregroundStyle(RestFitTheme.faint)
                                }
                                .frame(maxWidth: .infinity, minHeight: 56, alignment: .top)
                            }
                            .buttonStyle(.plain)
                            #if !SKIP
                            .layoutPriority(1)
                            #endif
                        }

                        setCheckSeparator()

                        ForEach(0..<live.sets, id: \.self) { index in
                            let done = workingDone > index
                            let effort = store.workingSetEffort(for: live, workingIndex: index)
                            Button {
                                if done {
                                    store.cycleWorkingSetEffort(for: live, workingIndex: index)
                                } else {
                                    registerSessionSetTap(for: live)
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    setCheckMark(done: done)
                                    if live.tracksWeight {
                                        Text(store.liftWeightLabel(live.weightKg))
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundStyle(done ? RestFitTheme.muted : .white)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.55)
                                            .padding(.top, 2)
                                    }
                                    Text("\(live.reps)r")
                                        .font(.system(size: 9))
                                        .foregroundStyle(RestFitTheme.faint)
                                    if done {
                                        sessionSetEffortMark(effort)
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 56, alignment: .top)
                            }
                            .buttonStyle(.plain)
                            #if !SKIP
                            .layoutPriority(1)
                            #endif
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 10)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(0..<live.sets, id: \.self) { index in
                        let done = workingDone > index
                        let effort = store.workingSetEffort(for: live, workingIndex: index)
                        Button {
                            if done {
                                store.cycleWorkingSetEffort(for: live, workingIndex: index)
                            } else {
                                registerSessionSetTap(for: live)
                            }
                        } label: {
                            VStack(spacing: 3) {
                                setCheckMark(done: done)
                                if done {
                                    sessionSetEffortMark(effort)
                                }
                            }
                            .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, 14)
                .padding(.bottom, 10)
            }

            HStack(spacing: 12) {
                Text("Reps")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RestFitTheme.muted)
                MintStepperButton(symbol: "−") {
                    var updated = live
                    updated.reps = max(1, live.reps - 1)
                    updateExercise(updated, weekday: sessionEditDay)
                }
                Text("\(live.reps)")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 28)
                MintStepperButton(symbol: "+") {
                    var updated = live
                    updated.reps = min(50, live.reps + 1)
                    updateExercise(updated, weekday: sessionEditDay)
                }
                Spacer(minLength: 0)
            }

            // Own row so ++ / -- chips aren't crushed beside reps on Fold cover / narrow panes.
            HStack(spacing: 10) {
                sessionEffortChip(
                    title: "++ easy",
                    selected: lastEffort == .plusPlus,
                    color: RestFitTheme.mint,
                    enabled: lastWorkingIndex != nil
                ) {
                    if let lastWorkingIndex {
                        store.setWorkingSetEffort(for: live, workingIndex: lastWorkingIndex, effort: .plusPlus)
                    }
                }
                sessionEffortChip(
                    title: "-- heavy",
                    selected: lastEffort == .minusMinus,
                    color: RestFitTheme.coral,
                    enabled: lastWorkingIndex != nil
                ) {
                    if let lastWorkingIndex {
                        store.setWorkingSetEffort(for: live, workingIndex: lastWorkingIndex, effort: .minusMinus)
                    }
                }
            }

            liftTrackingModeBar(tracksWeight: live.tracksWeight) { tracksWeight in
                var updated = live
                updated.tracksWeight = tracksWeight
                if !tracksWeight {
                    updated.includeWarmUp = false
                    updated.weightKg = 0.0
                }
                updateExercise(updated, weekday: sessionEditDay)
            }

            if live.tracksWeight {
                planWeightStepper(live, weekday: sessionEditDay)
            }
        }
        .padding(12)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// Advance one warm-up / working set; same rest + splash behavior as the lift header.
    private func registerSessionSetTap(for live: StrengthExercise) {
        let before = store.completedSets(for: live.id)
        let finishedLift = store.tapStrengthSet(for: live)
        let after = store.completedSets(for: live.id)
        if after > before, after > 1, !finishedLift {
            restKick += 1
        }
        if finishedLift {
            withAnimation(.easeInOut(duration: 0.38)) {
                liftSplashName = live.name
            }
        }
    }

    /// Incomplete caution a bit larger; completed checkmark stays smaller.
    @ViewBuilder
    private func setCheckMark(done: Bool) -> some View {
        let incompleteSize: CGFloat = 24.0
        let completedSize: CGFloat = 15.0
        let box: CGFloat = 28.0
        Group {
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: completedSize))
                    .foregroundStyle(RestFitTheme.mint)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: incompleteSize))
                    .foregroundStyle(Color.black)
            }
        }
        .frame(width: box, height: box, alignment: .center)
    }

    /// Middle separator — slightly larger than side cautions, centered on weight labels.
    /// Layout width stays narrow so Fold cover / phone columns aren't horizontally crushed.
    @ViewBuilder
    private func setCheckSeparator() -> some View {
        let markBox: CGFloat = 28.0
        let sepSize: CGFloat = 32.0
        let slotWidth: CGFloat = 20.0

        VStack(spacing: 6) {
            Color.clear
                .frame(width: slotWidth, height: markBox)
            ZStack {
                Text("00lbs")
                    .font(.system(size: 9, weight: .semibold))
                    .padding(.top, 2)
                    .hidden()
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: sepSize))
                    .foregroundStyle(Color.black.opacity(0.6))
                    // Nudge further up onto the weight-text midline.
                    .offset(y: -12)
            }
            .frame(width: slotWidth)
            Spacer(minLength: 0)
        }
        .frame(width: slotWidth)
        #if !SKIP
        .layoutPriority(-1)
        #endif
    }

    @ViewBuilder
    private func sessionSetEffortMark(_ effort: LiftSetEffort) -> some View {
        Text(effort == .none ? "·" : effort.rawValue)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(
                effort == .plusPlus ? RestFitTheme.mint
                : effort == .minusMinus ? RestFitTheme.coral
                : RestFitTheme.faint
            )
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        effort == .plusPlus ? RestFitTheme.mint.opacity(0.22)
                        : effort == .minusMinus ? RestFitTheme.coral.opacity(0.22)
                        : Color.clear
                    )
            )
    }

    @ViewBuilder
    private func sessionEffortChip(
        title: String,
        selected: Bool,
        color: Color,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .foregroundStyle(selected ? Color.black : (enabled ? color : RestFitTheme.faint))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selected ? color : color.opacity(enabled ? 0.14 : 0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(color.opacity(selected ? 0.0 : (enabled ? 0.55 : 0.2)), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.55)
    }

    @ViewBuilder
    private func setProgressDots(completed: Int, total: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(0..<total), id: \.self) { index in
                Circle()
                    .fill(index < completed ? RestFitTheme.mint : RestFitTheme.line)
                    .frame(width: 14, height: 14)
            }
            Spacer(minLength: 0)
        }
    }
}
