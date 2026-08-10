import SwiftUI

struct AppHeader: View {
    let name: String

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

struct QuickActionsGrid: View {
    @Environment(WellnessStore.self) private var store
    var onLogSleep: () -> Void
    var onAddWeight: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            QuickActionButton(
                title: "Log Sleep",
                subtitle: "Last night: \(store.lastSleepLabel)",
                icon: "bed.double.fill",
                tint: RestFitTheme.coral,
                action: onLogSleep
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

private struct QuickActionButton: View {
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
                        Text(String(format: "Target: %.1f kg", store.profile.targetWeightKg))
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    }
                    Spacer()
                    TrendBadge(
                        text: WellnessGuide.weightDelta(entries: store.weightEntries),
                        color: RestFitTheme.coral
                    )
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", store.currentWeightKg))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("kg")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(RestFitTheme.muted)
                    Text("Current")
                        .font(.subheadline)
                        .foregroundStyle(RestFitTheme.faint)
                        .padding(.leading, 4)
                }

                LineTrendChart(
                    values: store.weeklyWeightValues,
                    labels: ["M", "T", "W", "T", "F", "S", "S"],
                    color: RestFitTheme.coral,
                    fillOpacity: 0.08
                )
                .frame(height: 140)
            }
        }
    }
}
