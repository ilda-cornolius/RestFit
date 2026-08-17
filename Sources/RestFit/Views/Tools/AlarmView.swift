import SwiftUI

struct AlarmView: View {
    @Environment(WellnessStore.self) private var store
    var onProfile: () -> Void = {}
    @State private var showComposer = false
    @State private var editingAlarm: AlarmItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppHeader(section: "Alarm", onProfile: onProfile)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.nextAlarmLabel)
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    }
                    Spacer()
                    MintButton(title: "Add Alarm") {
                        editingAlarm = nil
                        showComposer = true
                    }
                }
                .padding(.horizontal, 24)

                if store.alarms.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No alarms yet")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("Set a wake-up alarm and a wind-down reminder so fasting and sleep stay on schedule.")
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.muted)
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 12) {
                        ForEach(store.alarms.sorted { lhs, rhs in
                            if lhs.hour == rhs.hour {
                                return lhs.minute < rhs.minute
                            }
                            return lhs.hour < rhs.hour
                        }) { alarm in
                            alarmRow(alarm)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 120)
        }
        .sheet(isPresented: $showComposer) {
            AlarmComposerSheet(alarm: editingAlarm)
                .environment(store)
        }
    }

    private func alarmRow(_ alarm: AlarmItem) -> some View {
        HStack(spacing: 14) {
            Button {
                editingAlarm = alarm
                showComposer = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.timeLabel)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(alarm.isEnabled ? .white : RestFitTheme.faint)
                    Text("\(alarm.label) · \(alarm.repeatsDaily ? "Daily" : "Once")")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in store.toggleAlarm(alarm) }
            ))
            .labelsHidden()
            .tint(RestFitTheme.mint)
        }
        .padding(16)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RestFitTheme.line, lineWidth: 1)
        )
    }
}

struct AlarmComposerSheet: View {
    @Environment(WellnessStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var alarm: AlarmItem?
    @State private var label = "Wake up"
    @State private var hour = 7
    @State private var minute = 0
    @State private var repeatsDaily = true

    var body: some View {
        NavigationStack {
            Form {
                TextField("Label", text: $label)
                Picker("Hour", selection: $hour) {
                    ForEach(0..<24, id: \.self) { value in
                        Text(hourLabel(value)).tag(value)
                    }
                }
                Picker("Minute", selection: $minute) {
                    ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { value in
                        Text(String(format: "%02d", value)).tag(value)
                    }
                }
                Toggle("Repeat daily", isOn: $repeatsDaily)
            }
            .navigationTitle(alarm == nil ? "New Alarm" : "Edit Alarm")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if var existing = alarm {
                            existing.label = label.isEmpty ? "Alarm" : label
                            existing.hour = hour
                            existing.minute = minute
                            existing.repeatsDaily = repeatsDaily
                            existing.isEnabled = true
                            store.updateAlarm(existing)
                        } else {
                            store.addAlarm(
                                label: label.isEmpty ? "Alarm" : label,
                                hour: hour,
                                minute: minute,
                                repeatsDaily: repeatsDaily
                            )
                        }
                        dismiss()
                    }
                }
                if alarm != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive) {
                            if let alarm {
                                store.deleteAlarm(alarm)
                            }
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            if let alarm {
                label = alarm.label
                hour = alarm.hour
                minute = alarm.minute
                repeatsDaily = alarm.repeatsDaily
            }
        }
    }

    private func hourLabel(_ value: Int) -> String {
        let hour12 = value % 12 == 0 ? 12 : value % 12
        let period = value < 12 ? "AM" : "PM"
        return "\(hour12) \(period)"
    }
}
