import SwiftUI

struct TodayWorkoutCard: View {
    @Environment(WellnessStore.self) private var store
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }
    @State private var customFocus = ""
    @State private var liftName = ""
    @State private var liftSets = 3
    @State private var liftReps = 8
    @State private var liftWeightText = ""
    @State private var walkMinutes = 30
    @State private var activityName = ""
    @State private var showLiftForm = false

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                headerRow
                Text("Planned: \(plannedLabel)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RestFitTheme.mint)

                FlowLayoutChips(items: store.suggestedWorkoutFocuses) { focus in
                    focusChip(focus)
                }

                customFocusRow
                activitySection
                footerNote
            }
        }
        .onAppear {
            customFocus = store.activeTodayFocus
            if liftWeightText.isEmpty {
                liftWeightText = store.usesPounds ? "45" : "20"
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today I'm doing")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                Text(statusLine)
                    .font(.caption)
                    .foregroundStyle(RestFitTheme.muted)
            }
            Spacer()
            if store.hasLoggedTodayWorkout {
                Text("LOGGED")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(RestFitTheme.canvas)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RestFitTheme.mint.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
    }

    private var customFocusRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            AeroTextField(
                title: "Something else",
                text: $customFocus,
                mode: AeroKeyboardMode.text,
                placeholder: "Yoga, swim...",
                minHeight: 48.0
            )
            Button("Set") {
                let name = customFocus.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                let lower = name.lowercased()
                store.pickTodayWorkout(
                    focus: name,
                    isRestDay: lower == "rest" || lower == "cardio"
                )
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(RestFitTheme.mint)
            .padding(.bottom, 14)
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What you did")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RestFitTheme.muted)

            HStack(spacing: 8) {
                quickActionButton("Just walked") {
                    store.addTodayWalk(minutes: walkMinutes)
                }
                quickActionButton(showLiftForm ? "Hide lift" : "Log a lift") {
                    showLiftForm.toggle()
                }
            }

            HStack(spacing: 10) {
                Text("Walk min")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RestFitTheme.faint)
                intStepper(value: $walkMinutes, range: 5...180, step: 5)
            }

            if showLiftForm {
                liftForm
            }

            HStack(alignment: .bottom, spacing: 10) {
                AeroTextField(
                    title: "Other activity",
                    text: $activityName,
                    mode: AeroKeyboardMode.text,
                    placeholder: "Bike, yoga...",
                    minHeight: 48.0
                )
                Button("Add") {
                    let name = activityName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    store.addTodayActivity(name: name)
                    activityName = ""
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(RestFitTheme.mint)
                .padding(.bottom, 14)
            }

            if store.todayWorkoutActivities.isEmpty {
                Text("Log lifts, a walk, or anything else you did today.")
                    .font(.caption2)
                    .foregroundStyle(RestFitTheme.faint)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.todayWorkoutActivities) { activity in
                        activityRow(activity)
                    }
                }
            }
        }
    }

    private var liftForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            AeroTextField(
                title: "Lift name",
                text: $liftName,
                mode: AeroKeyboardMode.text,
                placeholder: "Bench press",
                minHeight: 48.0
            )
            HStack(spacing: 12) {
                stepperField("Sets", value: $liftSets, range: 1...10)
                stepperField("Reps", value: $liftReps, range: 1...30)
            }
            AeroTextField(
                title: "Weight (\(store.weightUnitLabel))",
                text: $liftWeightText,
                mode: AeroKeyboardMode.decimal,
                placeholder: "0",
                minHeight: 48.0
            )
            Button {
                guard let weight = Double(liftWeightText) else { return }
                store.addTodayLift(
                    name: liftName,
                    sets: liftSets,
                    reps: liftReps,
                    weightKg: store.kilogramsFromDisplay(weight)
                )
                liftName = ""
                liftWeightText = store.usesPounds ? "45" : "20"
            } label: {
                Text("Add lift")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RestFitTheme.canvas)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RestFitTheme.mint)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(liftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Double(liftWeightText) == nil)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func stepperField(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RestFitTheme.faint)
            intStepper(value: value, range: range, step: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func intStepper(value: Binding<Int>, range: ClosedRange<Int>, step: Int) -> some View {
        HStack(spacing: 8) {
            Button {
                value.wrappedValue = max(range.lowerBound, value.wrappedValue - step)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(RestFitTheme.mint)
            }
            .buttonStyle(.plain)
            Text("\(value.wrappedValue)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(minWidth: 28)
            Button {
                value.wrappedValue = min(range.upperBound, value.wrappedValue + step)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(RestFitTheme.mint)
            }
            .buttonStyle(.plain)
        }
    }

    private func activityRow(_ activity: DailyWorkoutActivity) -> some View {
        HStack(spacing: 10) {
            Image(systemName: activityIcon(activity))
                .font(.caption.weight(.semibold))
                .foregroundStyle(RestFitTheme.mint)
                .frame(width: 22)
            Text(store.activityDisplayLabel(activity))
                .font(.caption)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                store.removeTodayWorkoutActivity(activity.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(RestFitTheme.faint)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func activityIcon(_ activity: DailyWorkoutActivity) -> String {
        switch activity.kind {
        case .lift: "dumbbell.fill"
        case .walk: "figure.walk"
        case .activity: "figure.run"
        }
    }

    private func quickActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var footerNote: some View {
        Text("Your last pick and activity list save automatically at the end of the day.")
            .font(.caption2)
            .foregroundStyle(RestFitTheme.faint)
    }

    private var plannedLabel: String {
        let plan = store.todayStrengthDay
        if plan.isCardioDay { return "Cardio" }
        if plan.isOffDay { return "Rest" }
        let focus = plan.focus.trimmingCharacters(in: .whitespacesAndNewlines)
        return focus.isEmpty || focus.lowercased() == "workout" ? "Workout" : focus
    }

    private var statusLine: String {
        if let log = store.dailyWorkoutLog(for: .now) {
            let source = log.wasPassive ? "Saved from your last pick" : "Logged today"
            return "\(log.dayTypeLabel) · \(source)"
        }
        if store.hasPickedTodayWorkout, let pick = store.todayWorkoutPick {
            let time = pick.pickedAt.formatted(date: .omitted, time: .shortened)
            return "\(store.activeTodayLabel) · picked \(time)"
        }
        return "Tap what you're doing today"
    }

    private func focusChip(_ focus: String) -> some View {
        let selected = isSelected(focus)
        return Button {
            let lower = focus.lowercased()
            store.pickTodayWorkout(
                focus: focus,
                isRestDay: lower == "rest" || lower == "cardio"
            )
        } label: {
            Text(focus)
                .font(.caption.weight(.bold))
                .foregroundStyle(selected ? RestFitTheme.canvas : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? RestFitTheme.mint : Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(selected ? RestFitTheme.mint : RestFitTheme.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func isSelected(_ focus: String) -> Bool {
        guard store.hasPickedTodayWorkout || store.hasLoggedTodayWorkout else { return false }
        return store.activeTodayLabel.caseInsensitiveCompare(focus) == ComparisonResult.orderedSame
            || (focus.lowercased() == "rest" && store.activeTodayLabel == "Rest")
            || (focus.lowercased() == "cardio" && store.activeTodayLabel == "Cardio")
    }
}

/// Simple wrapping chip row for Skip-compatible layouts.
private struct FlowLayoutChips<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunked(items, size: 3), id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func chunked(_ items: [Item], size: Int) -> [[Item]] {
        guard size > 0 else { return [items] }
        var rows: [[Item]] = []
        var index = 0
        while index < items.count {
            let end = min(index + size, items.count)
            rows.append(Array(items[index..<end]))
            index = end
        }
        return rows
    }
}

struct WeightCheckInSheet: View {
    @Environment(WellnessStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }
    @State private var weightText = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick weigh-in")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("You haven't logged weight in \(store.daysSinceLastWeightLog) days. A weekly check-in helps track progress.")
                    .font(.caption)
                    .foregroundStyle(RestFitTheme.muted)

                AeroTextField(
                    title: "Weight in \(store.weightUnitLabel)",
                    text: $weightText,
                    mode: AeroKeyboardMode.decimal,
                    placeholder: "0.0"
                )

                Spacer()
            }
            .padding(20)
            .padding(.bottom, keyboard.isPresented ? 300.0 : 0.0)
            .background(RestFitTheme.canvas)
            .navigationTitle("Weekly check-in")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") {
                        store.dismissWeightCheckInForToday()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let weight = Double(weightText) {
                            store.recordWeightCheckIn(store.kilogramsFromDisplay(weight))
                            dismiss()
                        }
                    }
                    .disabled(Double(weightText) == nil)
                }
            }
        }
        .presentationDetents([.medium])
        .overlay {
            AeroKeyboardOverlay()
        }
        .onAppear {
            weightText = String(format: "%.1f", store.currentWeightDisplay)
        }
    }
}
