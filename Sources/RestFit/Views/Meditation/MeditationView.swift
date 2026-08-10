import SwiftUI

struct MeditationView: View {
    @Environment(WellnessStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppHeader(name: store.profile.name)

                Text("Meditation")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                if store.isMeditating, let preset = store.activeMeditationPreset {
                    ActiveMeditationCard(preset: preset)
                        .padding(.horizontal, 24)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("This Week")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("Minutes of calm")
                                    .font(.caption)
                                    .foregroundStyle(RestFitTheme.muted)
                            }
                            Spacer()
                            TrendBadge(
                                text: "\(store.totalMeditationMinutesThisWeek) min",
                                color: RestFitTheme.mint
                            )
                        }

                        LineTrendChart(
                            values: store.weeklyMeditationMinutes,
                            labels: ["M", "T", "W", "T", "F", "S", "S"],
                            color: RestFitTheme.mint,
                            fillOpacity: 0.1
                        )
                        .frame(height: 120)
                    }
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Guided Sessions")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)

                    ForEach(MeditationPreset.allCases) { preset in
                        MeditationPresetRow(
                            preset: preset,
                            isActive: store.activeMeditationPreset == preset && store.isMeditating
                        )
                        .padding(.horizontal, 24)
                    }
                }

                if !store.meditationEntries.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Sessions")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)

                            ForEach(store.meditationEntries.sorted { $0.date > $1.date }.prefix(5)) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.presetName)
                                            .foregroundStyle(.white)
                                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(RestFitTheme.muted)
                                    }
                                    Spacer()
                                    Text("\(entry.durationMinutes) min")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RestFitTheme.mint)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                GuidanceCard(guidance: WellnessGuide.meditationTip)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 120)
        }
    }
}

private struct ActiveMeditationCard: View {
    @Environment(WellnessStore.self) private var store
    let preset: MeditationPreset

    var body: some View {
        SurfaceCard {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Now playing")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                        Text(preset.rawValue)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("\(preset.durationMinutes) min session")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.faint)
                    }
                    Spacer()
                    FastingRingView(progress: store.meditationProgress)
                        .frame(width: 88, height: 88)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(store.meditationTimerLabel)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("/ \(preset.durationMinutes):00")
                        .font(.subheadline)
                        .foregroundStyle(RestFitTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(store.meditationRemainingLabel) remaining")
                    .font(.caption)
                    .foregroundStyle(RestFitTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                MintButton(title: "End Session") {
                    store.endMeditation(completed: store.meditationProgress >= 0.95)
                }
            }
        }
        .onChange(of: store.meditationProgress) { _, progress in
            if progress >= 1.0 {
                store.endMeditation(completed: true)
            }
        }
    }
}

private struct MeditationPresetRow: View {
    @Environment(WellnessStore.self) private var store
    let preset: MeditationPreset
    let isActive: Bool

    var body: some View {
        Button {
            if isActive {
                store.endMeditation(completed: store.meditationProgress >= 0.95)
            } else if store.isMeditating {
                store.endMeditation(completed: false)
                store.startMeditation(preset)
            } else {
                store.startMeditation(preset)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: preset.icon)
                    .font(.title3)
                    .foregroundStyle(isActive ? RestFitTheme.canvas : RestFitTheme.mint)
                    .frame(width: 44, height: 44)
                    .background(isActive ? RestFitTheme.mint : RestFitTheme.mint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(preset.subtitle)
                        .font(.caption2)
                        .foregroundStyle(RestFitTheme.muted)
                        .lineLimit(2)
                }

                Spacer()

                Text("\(preset.durationMinutes)m")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RestFitTheme.mint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RestFitTheme.mint.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(16)
            .background(RestFitTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isActive ? RestFitTheme.mint : RestFitTheme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
