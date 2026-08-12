import SwiftUI

/// Past feature (not shown in the current UI). See `PastFeatures`.
struct PomodoroView: View {
    @Environment(WellnessStore.self) private var store
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BackHeader(title: "Pomodoro", action: onBack)

                SurfaceCard {
                    VStack(spacing: 20) {
                        Text(store.pomodoroPhase.rawValue)
                            .font(.caption.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(RestFitTheme.muted)

                        FastingRingView(progress: store.pomodoroProgress)
                            .frame(width: 180, height: 180)

                        Text(store.pomodoroRemainingLabel)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("\(store.pomodoroSettings.minutes(for: store.pomodoroPhase)) min \(store.pomodoroPhase.rawValue.lowercased())")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.faint)

                        HStack(spacing: 12) {
                            if store.isPomodoroRunning {
                                MintButton(title: "Pause") {
                                    store.pausePomodoro()
                                }
                            } else {
                                MintButton(title: store.pomodoroElapsed > 0 ? "Resume" : "Start") {
                                    store.startPomodoro()
                                }
                            }

                            Button(store.isPomodoroRunning ? "Skip" : "Reset") {
                                if store.isPomodoroRunning {
                                    store.skipPomodoroPhase()
                                } else {
                                    store.resetPomodoro()
                                }
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RestFitTheme.muted)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(RestFitTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        Text("\(store.todayFocusCount) focus sessions today")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Presets")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)

                        presetButton(title: "Classic 25 / 5", focus: 25, shortBreak: 5, longBreak: 15)
                        presetButton(title: "Deep work 50 / 10", focus: 50, shortBreak: 10, longBreak: 20)
                        presetButton(title: "Sprint 15 / 3", focus: 15, shortBreak: 3, longBreak: 10)
                    }
                }
                .padding(.horizontal, 24)

                if !store.pomodoroSessions.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Sessions")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)

                            ForEach(store.pomodoroSessions.sorted { $0.date > $1.date }.prefix(5)) { session in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.phase.rawValue)
                                            .foregroundStyle(.white)
                                        Text(session.date.formatted(date: .omitted, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(RestFitTheme.muted)
                                    }
                                    Spacer()
                                    Text("\(session.durationMinutes) min")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RestFitTheme.mint)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 120)
        }
    }

    private func presetButton(title: String, focus: Int, shortBreak: Int, longBreak: Int) -> some View {
        let selected = store.pomodoroSettings.focusMinutes == focus
            && store.pomodoroSettings.shortBreakMinutes == shortBreak

        return Button {
            store.applyPomodoroPreset(focus: focus, shortBreak: shortBreak, longBreak: longBreak)
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.white)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(RestFitTheme.mint)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
