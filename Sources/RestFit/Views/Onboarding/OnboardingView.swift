import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
}

struct OnboardingView: View {
    @Environment(WellnessStore.self) private var store
    @State private var pageIndex = 0
    @State private var name = ""
    @State private var targetWeight = "143.3"
    @State private var usesPounds = true
    @State private var selectedProtocol: FastingProtocol = .sixteenEight
    @State private var enableReminders = true
    @State private var enableHealth = false
    @State private var isFinishing = false

    let onComplete: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "moon.stars.fill",
            title: "Welcome to RestFit",
            subtitle: "Track fasting, sleep, and weight in one calm dashboard built around your circadian rhythm.",
            tint: RestFitTheme.mint
        ),
        OnboardingPage(
            icon: "clock.fill",
            title: "Guided fasting",
            subtitle: "Pick a protocol, run a live timer, and get reminders when your fast completes.",
            tint: RestFitTheme.coral
        ),
        OnboardingPage(
            icon: "bed.double.fill",
            title: "Sleep & weight",
            subtitle: "Log trends over time and receive coaching tips tailored to your daily rhythm.",
            tint: RestFitTheme.mint
        )
    ]

    var body: some View {
        ZStack {
            RestFitTheme.canvas.ignoresSafeArea()

            VStack(spacing: 24) {
                if pageIndex < pages.count {
                    introPage(pages[pageIndex])
                } else {
                    setupPage
                }

                progressDots

                HStack(spacing: 12) {
                    if pageIndex > 0 && pageIndex <= pages.count {
                        Button("Back") { pageIndex -= 1 }
                            .foregroundStyle(RestFitTheme.muted)
                    }

                    Spacer()

                    MintButton(title: pageIndex < pages.count ? "Continue" : "Get Started") {
                        advance()
                    }
                    .disabled(isFinishing)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<(pages.count + 1), id: \.self) { index in
                Capsule()
                    .fill(index == pageIndex ? RestFitTheme.mint : RestFitTheme.line)
                    .frame(width: index == pageIndex ? 24.0 : 8.0, height: 8.0)
            }
        }
    }

    private func introPage(_ page: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 44))
                .foregroundStyle(page.tint)
                .frame(width: 96, height: 96)
                .background(page.tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(RestFitTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
    }

    private var setupPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Set up your profile")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 48)

                setupField("Your name", text: $name)

                Toggle(isOn: $usesPounds) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weight in pounds")
                            .foregroundStyle(.white)
                        Text(usesPounds ? "Target will be saved in lb" : "Target will be saved in kg")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    }
                }
                .tint(RestFitTheme.mint)
                .onChange(of: usesPounds) { _, newValue in
                    if let value = Double(targetWeight) {
                        if newValue {
                            targetWeight = String(format: "%.1f", value * 2.2046226218)
                        } else {
                            targetWeight = String(format: "%.1f", value / 2.2046226218)
                        }
                    }
                }

                setupField("Target weight (\(usesPounds ? "lb" : "kg"))", text: $targetWeight)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Fasting protocol")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                    Picker("Protocol", selection: $selectedProtocol) {
                        ForEach(FastingProtocol.allCases) { proto in
                            Text(proto.displayName).tag(proto)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(RestFitTheme.mint)
                }

                Toggle(isOn: $enableReminders) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fasting reminders")
                            .foregroundStyle(.white)
                        Text("Hydration nudge and fast-complete alerts")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    }
                }
                .tint(RestFitTheme.mint)

                Toggle(isOn: $enableHealth) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Import from Apple Health")
                            .foregroundStyle(.white)
                        Text(HealthDataService.authorizationStatusDescription())
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                    }
                }
                .tint(RestFitTheme.mint)
                #if SKIP
                .disabled(true)
                #endif
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func setupField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RestFitTheme.muted)
            TextField(title, text: text)
                .padding(12)
                .background(RestFitTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(RestFitTheme.line, lineWidth: 1)
                )
                .foregroundStyle(.white)
        }
    }

    private func advance() {
        if pageIndex < pages.count {
            pageIndex += 1
            if pageIndex == pages.count {
                name = store.profile.name
                usesPounds = store.usesPounds
                targetWeight = String(format: "%.1f", store.targetWeightDisplay)
            }
            return
        }

        finishOnboarding()
    }

    private func finishOnboarding() {
        isFinishing = true
        store.setUsesPounds(usesPounds)
        let entered = Double(targetWeight) ?? store.targetWeightDisplay
        store.completeOnboarding(
            name: name.isEmpty ? "Maria" : name,
            targetWeight: store.kilogramsFromDisplay(entered),
            fastingProtocol: selectedProtocol,
            remindersEnabled: enableReminders
        )

        Task {
            if enableReminders {
                _ = await FastingReminderService.requestAuthorization()
                await FastingReminderService.scheduleFastingReminders(
                    isFasting: store.isFasting,
                    startedAt: store.fastingStartedAt,
                    targetHours: store.profile.fastingProtocol.targetHours,
                    remindersEnabled: store.remindersEnabled
                )
            }

            if enableHealth {
                let authorized = await HealthDataService.requestAuthorization()
                if authorized {
                    let snapshot = await HealthDataService.fetchRecentSnapshot()
                    HealthDataService.importIntoStore(store, snapshot: snapshot)
                }
            }

            await MainActor.run {
                isFinishing = false
                onComplete()
            }
        }
    }
}
