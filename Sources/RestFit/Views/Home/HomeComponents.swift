import SwiftUI

struct AppHeader: View {
    let name: String
    var onProfile: () -> Void = {}

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "moon.stars.fill")
                    .font(.body)
                    .foregroundStyle(RestFitTheme.mint)
                    .frame(width: 32, height: 32)
                    .background(RestFitTheme.mint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                HStack(spacing: 0) {
                    Text("Rest")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Fit")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(RestFitTheme.mint)
                }
            }

            Spacer()

            Button(action: onProfile) {
                Circle()
                    .fill(RestFitTheme.line)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Text(String(name.prefix(1)).uppercased())
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .overlay(Circle().stroke(RestFitTheme.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 8)
    }
}

struct WelcomeSection: View {
    let greeting: String
    let headline: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting.uppercased())
                .font(.caption2.weight(.medium))
                .tracking(2)
                .foregroundStyle(RestFitTheme.faint)

            Text(headline)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FastingStatusCard: View {
    @Environment(WellnessStore.self) private var store

    var body: some View {
        SurfaceCard {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(RestFitTheme.mint.opacity(0.1))
                    .frame(width: 176, height: 176)
                    .blur(radius: 40)
                    .offset(x: 40, y: -80)

                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current fast")
                                .font(.subheadline)
                                .foregroundStyle(RestFitTheme.muted)
                            Text(store.profile.fastingProtocol.displayName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white)

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(store.fastingTimerLabel)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("/ \(store.fastingTargetShortLabel)")
                                    .font(.caption)
                                    .foregroundStyle(RestFitTheme.muted)
                            }
                            .padding(.vertical, 4)

                            MintButton(title: store.isFasting ? "End Fasting" : "Start Fasting") {
                                store.toggleFasting()
                            }
                        }

                        Spacer()

                        FastingRingView(progress: store.fastingProgress)
                            .frame(width: 112, height: 112)
                    }

                    Divider()
                        .overlay(RestFitTheme.line)
                        .padding(.top, 20)

                    HStack {
                        if store.isFasting {
                            Text("Next meal in \(store.nextMealLabel)")
                                .foregroundStyle(RestFitTheme.muted)
                        } else {
                            Text("Fasting paused")
                                .foregroundStyle(RestFitTheme.muted)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Text("Day \(store.profile.fastingStreakDays) streak")
                                .foregroundStyle(RestFitTheme.muted)
                            Image(systemName: "flame.fill")
                                .foregroundStyle(RestFitTheme.coral)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .font(.caption)
                    .padding(.top, 16)
                }
            }
        }
    }
}

struct FastingCircleButton: View {
    @Environment(WellnessStore.self) private var store

    var body: some View {
        VStack(spacing: 20) {
            if store.isFasting {
                Text(store.profile.fastingProtocol.displayName)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)
                Text(store.fastingTimerLabel)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("of \(store.fastingTargetShortLabel) · meal in \(store.nextMealLabel)")
                    .font(.subheadline)
                    .foregroundStyle(RestFitTheme.muted)
            } else {
                Text("Ready to fast")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)
                Text(store.profile.fastingProtocol.displayName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(Int(store.profile.fastingProtocol.targetHours)) hour target · Day \(store.profile.fastingStreakDays) streak")
                    .font(.subheadline)
                    .foregroundStyle(RestFitTheme.muted)
            }

            Button {
                store.toggleFasting()
            } label: {
                ZStack {
                    Circle()
                        .fill(store.isFasting ? RestFitTheme.coral : RestFitTheme.mint)
                        .frame(width: 148, height: 148)
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 6)
                        .frame(width: 148, height: 148)
                    Circle()
                        .trim(from: 0.0, to: store.isFasting ? store.fastingProgress : 0.0)
                        .stroke(RestFitTheme.canvas.opacity(0.35), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 148, height: 148)

                    VStack(spacing: 6) {
                        Image(systemName: store.isFasting ? "fork.knife" : "flame.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(RestFitTheme.canvas)
                        Text(store.isFasting ? "End Fast" : "Start Fast")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RestFitTheme.canvas)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct SleepBedCircleButton: View {
    @Environment(WellnessStore.self) private var store

    var body: some View {
        VStack(spacing: 20) {
            if store.isSleeping {
                Text("Since \(store.sleepStartedLabel)")
                    .font(.subheadline)
                    .foregroundStyle(RestFitTheme.muted)
                Text(store.sleepElapsedLabel)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Text("Ready for bed")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Last night: \(store.lastSleepLabel)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Button {
                store.toggleSleepSession()
            } label: {
                ZStack {
                    Circle()
                        .fill(store.isSleeping ? RestFitTheme.coral : RestFitTheme.mint)
                        .frame(width: 148, height: 148)
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 6)
                        .frame(width: 148, height: 148)

                    VStack(spacing: 6) {
                        Image(systemName: store.isSleeping ? "sun.max.fill" : "moon.zzz.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(RestFitTheme.canvas)
                        Text(store.isSleeping ? "Wake Up" : "I'm in bed")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RestFitTheme.canvas)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .buttonStyle(.plain)

            if store.isSleeping {
                Button("Cancel") {
                    store.cancelSleep()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RestFitTheme.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct SleepAdjustRow: View {
    @Environment(WellnessStore.self) private var store

    var body: some View {
        if !store.isSleeping, store.latestSleepEntry != nil {
            VStack(alignment: .leading, spacing: 10) {
                Text("Adjust last night")
                    .font(.caption)
                    .foregroundStyle(RestFitTheme.muted)
                Text("On your phone after lights out? Trim time. Fell asleep earlier? Add it back.")
                    .font(.caption2)
                    .foregroundStyle(RestFitTheme.faint)

                HStack(spacing: 10) {
                    sleepAdjustButton(title: "−30 min", delta: -30)
                    sleepAdjustButton(title: "+30 min", delta: 30)
                }
            }
        }
    }

    private func sleepAdjustButton(title: String, delta: Int) -> some View {
        Button {
            store.adjustLatestSleep(byMinutes: delta)
        } label: {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RestFitTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(RestFitTheme.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct QuickActionsGrid: View {
    @Environment(WellnessStore.self) private var store
    var onOpenSleep: () -> Void
    var onAddWeight: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            QuickActionButton(
                title: "Sleep",
                subtitle: store.isSleeping ? "In bed · \(store.sleepElapsedLabel)" : "Last night: \(store.lastSleepLabel)",
                icon: "bed.double.fill",
                tint: RestFitTheme.coral,
                action: onOpenSleep
            )

            QuickActionButton(
                title: "Add Weight",
                subtitle: "Last entry: \(store.lastWeightEntryLabel)",
                icon: "plus",
                tint: RestFitTheme.mint,
                action: onAddWeight
            )
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(RestFitTheme.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RestFitTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(RestFitTheme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SleepPanel: View {
    @Environment(WellnessStore.self) private var store

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sleep Quality")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Consistency is key")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    }
                    Spacer()
                    TrendBadge(
                        text: WellnessGuide.sleepTrendPercent(scores: store.weeklySleepScores),
                        color: RestFitTheme.mint
                    )
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(store.sleepScore)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("%")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(RestFitTheme.muted)
                    Text("Score")
                        .font(.subheadline)
                        .foregroundStyle(RestFitTheme.faint)
                        .padding(.leading, 4)
                }

                LineTrendChart(
                    values: store.weeklySleepScores.map { Double($0) },
                    labels: ["M", "T", "W", "T", "F", "S", "S"],
                    color: RestFitTheme.mint,
                    fillOpacity: 0.1
                )
                .frame(height: 140)
            }
        }
    }
}

struct WeightPanel: View {
    @Environment(WellnessStore.self) private var store

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weight Journey")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Target: \(String(format: "%.1f", store.targetWeightDisplay)) \(store.weightUnitLabel)")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    }
                    Spacer()
                    TrendBadge(
                        text: store.weightDeltaLabel,
                        color: RestFitTheme.coral
                    )
                }

                Toggle(isOn: Binding(
                    get: { store.usesPounds },
                    set: { store.setUsesPounds($0) }
                )) {
                    Text(store.usesPounds ? "Pounds (lb)" : "Kilograms (kg)")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                }
                .tint(RestFitTheme.mint)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", store.currentWeightDisplay))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(store.weightUnitLabel)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(RestFitTheme.muted)
                    Text("Current")
                        .font(.subheadline)
                        .foregroundStyle(RestFitTheme.faint)
                        .padding(.leading, 4)
                }

                LineTrendChart(
                    values: store.weeklyWeightDisplayValues,
                    labels: ["M", "T", "W", "T", "F", "S", "S"],
                    color: RestFitTheme.coral,
                    fillOpacity: 0.08
                )
                .frame(height: 140)
            }
        }
    }
}
