import SwiftUI

enum AppTab: String, Hashable, CaseIterable {
    case home, fast, sleep, workout, alarm, profile

    static let barTabs: [AppTab] = [.home, .fast, .sleep, .workout, .alarm, .profile]

    var title: String {
        switch self {
        case .home: "Home"
        case .fast: "Fast"
        case .sleep: "Sleep"
        case .workout: "Workout"
        case .alarm: "Alarm"
        case .profile: "Me"
        }
    }

    var icon: String {
        switch self {
        case .home: "tab_home"
        case .fast: "tab_fast"
        case .sleep: "tab_sleep"
        case .workout: "tab_workout"
        case .alarm: "tab_alarm"
        case .profile: "person.fill"
        }
    }

    var barIndex: Int {
        Self.barTabs.firstIndex(of: self) ?? 0
    }
}

struct ContentView: View {
    @State private var store = WellnessStore()
    @State private var selectedTab: AppTab = .home
    @State private var tabTransitionForward = true
    @State private var showLogSleep = false
    @State private var showAddWeight = false
    @State private var showWeightCheckIn = false

    var body: some View {
        Group {
            if !store.isSignedIn {
                TitleLoginView()
            } else if !store.hasCompletedOnboarding {
                OnboardingView {
                    // Onboarding marks profile complete in the store.
                }
            } else {
                mainApp
            }
        }
        .environment(store)
        .overlay {
            ZStack {
                AeroKeyboardOverlay()
                AlarmRingOverlay()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showLogSleep) {
            LogSleepSheet()
                .environment(store)
        }
        .sheet(isPresented: $showAddWeight) {
            AddWeightSheet()
                .environment(store)
        }
        .sheet(isPresented: $showWeightCheckIn) {
            WeightCheckInSheet()
                .environment(store)
        }
        .onChange(of: store.shouldShowWeightCheckIn) { _, shouldShow in
            if shouldShow, store.hasCompletedOnboarding, store.isSignedIn {
                showWeightCheckIn = true
            }
        }
        .onAppear {
            if store.shouldShowWeightCheckIn, store.hasCompletedOnboarding, store.isSignedIn {
                showWeightCheckIn = true
            }
        }
        .task {
            while !Task.isCancelled {
                store.tick()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private var mainApp: some View {
        GeometryReader { geo in
            let contentMax = Self.preferredContentWidth(for: geo.size.width)
            let homeInset = geo.safeAreaInsets.bottom
            let tabBarHeight = AppLayout.tabBarHeight(homeIndicatorInset: homeInset)

            ZStack(alignment: .bottom) {
                RestFitTheme.canvas.ignoresSafeArea()

                ZStack {
                    tabContent
                        .id(selectedTab)
                        .transition(AppLayout.tabScreenTransition(forward: tabTransitionForward))
                }
                    .frame(maxWidth: contentMax)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, tabBarHeight)
                    .clipped()

                BottomTabBar(
                    selectedTab: Binding(
                        get: { selectedTab },
                        set: { selectTab($0) }
                    ),
                    homeIndicatorInset: homeInset
                )
                    .frame(maxWidth: contentMax)
                    .frame(maxWidth: .infinity)
            }
            // Force a fresh layout tree when the Fold cover/main display size changes.
            .id("main-\(Int(geo.size.width))x\(Int(geo.size.height))")
        }
    }

    /// Phone-like column on cover screens; wider readable column when unfolded / tablet.
    private static func preferredContentWidth(for width: CGFloat) -> CGFloat {
        if width >= 900.0 {
            return min(760.0, width - 48.0)
        }
        if width >= 600.0 {
            return min(600.0, width - 32.0)
        }
        return min(440.0, max(320.0, width))
    }

    private func selectTab(_ tab: AppTab) {
        guard tab != selectedTab else { return }
        tabTransitionForward = tab.barIndex > selectedTab.barIndex
        withAnimation(AppLayout.tabSwitchAnimation) {
            selectedTab = tab
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView(
                onAddWeight: { showAddWeight = true },
                onOpenSleep: { selectTab(.sleep) },
                onProfile: { selectTab(.profile) }
            )
        case .fast:
            FastingView(onProfile: { selectTab(.profile) })
        case .sleep:
            SleepView(
                onManualLog: { showLogSleep = true },
                onProfile: { selectTab(.profile) }
            )
        case .workout:
            WorkoutView(onProfile: { selectTab(.profile) })
        case .alarm:
            AlarmView(onProfile: { selectTab(.profile) })
        case .profile:
            ProfileView(onProfile: { selectTab(.profile) })
        }
    }
}

struct HomeView: View {
    @Environment(WellnessStore.self) private var store
    let onAddWeight: () -> Void
    let onOpenSleep: () -> Void
    let onProfile: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                WelcomeSection(
                    greeting: WellnessGuide.greeting(name: store.greetingName),
                    headline: WellnessGuide.rhythmHeadline(
                        sleepScores: store.weeklySleepScores,
                        fastingProgress: store.fastingProgress
                    )
                )
                .padding(.horizontal, 24)

                VStack(spacing: 20) {
                    if store.todayStrengthDay.isCardioDay {
                        CardioDayReminderCard()
                    }
                    FastingStatusCard()
                    QuickActionsGrid(onOpenSleep: onOpenSleep, onAddWeight: onAddWeight)
                    SleepPanel()
                    WeightPanel()

                    if !homeGuidance.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Guidance")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)

                            ForEach(homeGuidance) { tip in
                                GuidanceCard(guidance: tip)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, AppLayout.scrollTailPadding)
        }
    }

    private var homeGuidance: [WellnessGuidance] {
        let tips = store.guidance.filter { tip in
            // Cardio reminder is shown in its own card above.
            !(store.todayStrengthDay.isCardioDay && tip.icon == "heart.fill")
        }
        return Array(tips.prefix(3))
    }
}

struct CardioDayReminderCard: View {
    @Environment(WellnessStore.self) private var store

    var body: some View {
        let tip = WellnessGuide.workoutEncouragement(for: store.todayStrengthDay)
        return SurfaceCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundStyle(RestFitTheme.coral)
                    .frame(width: 36, height: 36)
                    .background(RestFitTheme.coral.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(tip.message)
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                    Text("Cardio day")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RestFitTheme.coral)
                }
            }
        }
    }
}

struct BottomTabBar: View {
    @Environment(WellnessStore.self) private var store
    @Binding var selectedTab: AppTab
    var homeIndicatorInset: CGFloat = 0

    private var bottomPadding: CGFloat {
        AppLayout.tabBarBottomPadding(homeIndicatorInset: homeIndicatorInset)
    }

    var body: some View {
        HStack {
            ForEach(AppTab.barTabs, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 3.0) {
                        tabIcon(tab)
                            .overlay(alignment: .top) {
                                if selectedTab == tab {
                                    Circle()
                                        .fill(RestFitTheme.mint)
                                        .frame(width: 5.0, height: 5.0)
                                        .offset(y: -7.0)
                                }
                            }

                        Text(tab.title.uppercased())
                            .font(.system(size: 10.0, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(selectedTab == tab ? RestFitTheme.mint : RestFitTheme.faint)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2.0)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(AppLayout.tabSwitchAnimation, value: selectedTab)
        .padding(.horizontal, 8.0)
        .padding(.top, 6.0)
        .padding(.bottom, bottomPadding)
        .background {
            RestFitTheme.surface.opacity(0.95)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(RestFitTheme.line.opacity(0.4))
                .frame(height: 1)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private func tabIcon(_ tab: AppTab) -> some View {
        if tab == .profile {
            let initial = store.greetingName.trimmingCharacters(in: .whitespacesAndNewlines)
            Circle()
                .fill(selectedTab == .profile ? RestFitTheme.mint.opacity(0.22) : RestFitTheme.line)
                .frame(width: 22.0, height: 22.0)
                .overlay {
                    Text(String((initial.isEmpty ? "Y" : initial).prefix(1)).uppercased())
                        .font(.system(size: 11.0, weight: .bold))
                        .foregroundStyle(selectedTab == .profile ? RestFitTheme.mint : RestFitTheme.faint)
                }
        } else {
            Image(tab.icon, bundle: .module)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 22.0, height: 22.0)
                .foregroundStyle(selectedTab == tab ? RestFitTheme.mint : RestFitTheme.faint)
        }
    }
}

struct FastingView: View {
    @Environment(WellnessStore.self) private var store
    var onProfile: () -> Void = {}
    @State private var showClearFastHistory = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppHeader(section: "Fasting", onProfile: onProfile)

                FastingCircleButton()
                    .padding(.horizontal, 24)

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose Protocol")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)

                        ForEach(FastingProtocol.allCases) { proto in
                            Button {
                                store.profile.fastingProtocol = proto
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(proto.displayName)
                                            .foregroundStyle(.white)
                                        Text("\(Int(proto.targetHours)) hour fast")
                                            .font(.caption)
                                            .foregroundStyle(RestFitTheme.muted)
                                    }
                                    Spacer()
                                    if store.profile.fastingProtocol == proto {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(RestFitTheme.mint)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)

                FastingHistoryCard(showClearConfirm: $showClearFastHistory)
                    .padding(.horizontal, 24)

                ForEach(store.guidance.filter { $0.icon == "flame.fill" || $0.icon == "drop.fill" || $0.icon == "fork.knife" }) { tip in
                    GuidanceCard(guidance: tip)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, AppLayout.scrollTailPadding)
        }
        .alert("Clear all fast history?", isPresented: $showClearFastHistory) {
            Button("Cancel", role: .cancel) {}
            Button("Clear all", role: .destructive) {
                store.deleteAllFastingEntries()
            }
        } message: {
            Text("This removes every completed fast from this device. It cannot be undone.")
        }
    }
}

struct SleepView: View {
    @Environment(WellnessStore.self) private var store
    let onManualLog: () -> Void
    var onProfile: () -> Void = {}
    @State private var showClearSleepHistory = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppHeader(section: "Sleep", onProfile: onProfile)

                HStack {
                    Spacer()
                    Button("Manual log") {
                        onManualLog()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RestFitTheme.mint)
                }
                .padding(.horizontal, 24)

                SleepBedCircleButton()
                    .padding(.horizontal, 24)

                SleepAdjustRow()
                    .padding(.horizontal, 24)

                SleepPanel()
                    .padding(.horizontal, 24)

                SleepHistoryCard(showClearConfirm: $showClearSleepHistory)
                    .padding(.horizontal, 24)

                ForEach(store.guidance.filter { $0.icon == "moon.fill" || $0.icon == "sparkles" }) { tip in
                    GuidanceCard(guidance: tip)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, AppLayout.scrollTailPadding)
        }
        .alert("Clear all sleep history?", isPresented: $showClearSleepHistory) {
            Button("Cancel", role: .cancel) {}
            Button("Clear all", role: .destructive) {
                store.deleteAllSleepEntries()
            }
        } message: {
            Text("This removes every logged night from this device. It cannot be undone.")
        }
    }
}

private struct SleepHistoryCard: View {
    @Environment(WellnessStore.self) private var store
    @Binding var showClearConfirm: Bool

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Sleep history")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)

                if store.sortedSleepEntries.isEmpty {
                    Text("No sleep logged yet. Use In bed or Manual log to add nights.")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.sortedSleepEntries) { entry in
                            historyRow(
                                title: entry.date.formatted(date: .abbreviated, time: .omitted),
                                subtitle: entry.durationLabel,
                                badge: "\(entry.qualityScore)%",
                                badgeColor: RestFitTheme.mint
                            ) {
                                store.deleteSleepEntry(entry.id)
                            }
                            if entry.id != store.sortedSleepEntries.last?.id {
                                Divider().overlay(RestFitTheme.line.opacity(0.5))
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        historyActionButton("Delete last night", destructive: true) {
                            store.deleteLatestSleepEntry()
                        }
                        historyActionButton("Clear all") {
                            showClearConfirm = true
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

private struct FastingHistoryCard: View {
    @Environment(WellnessStore.self) private var store
    @Binding var showClearConfirm: Bool

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Fast history")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)

                if store.sortedFastingEntries.isEmpty {
                    Text("No completed fasts yet. End a fast to save it here.")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.sortedFastingEntries) { entry in
                            historyRow(
                                title: entry.date.formatted(date: .abbreviated, time: .shortened),
                                subtitle: "\(entry.fastingProtocol.displayName) · \(entry.durationLabel)",
                                badge: entry.reachedGoal ? "Goal" : "Partial",
                                badgeColor: entry.reachedGoal ? RestFitTheme.mint : RestFitTheme.coral
                            ) {
                                store.deleteFastingEntry(entry.id)
                            }
                            if entry.id != store.sortedFastingEntries.last?.id {
                                Divider().overlay(RestFitTheme.line.opacity(0.5))
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        historyActionButton("Delete last fast", destructive: true) {
                            store.deleteLatestFastingEntry()
                        }
                        historyActionButton("Clear all") {
                            showClearConfirm = true
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

private func historyRow(
    title: String,
    subtitle: String,
    badge: String,
    badgeColor: Color,
    onDelete: @escaping () -> Void
) -> some View {
    HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(RestFitTheme.muted)
        }
        Spacer(minLength: 8)
        Text(badge)
            .font(.caption2.weight(.bold))
            .foregroundStyle(badgeColor)
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RestFitTheme.faint)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }
    .padding(.vertical, 8)
}

private func historyActionButton(
    _ title: String,
    destructive: Bool = false,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(destructive ? RestFitTheme.coral : RestFitTheme.mint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        destructive ? RestFitTheme.coral.opacity(0.35) : RestFitTheme.mint.opacity(0.28),
                        lineWidth: 1
                    )
            )
    }
    .buttonStyle(.plain)
}

struct ProfileView: View {
    @Environment(WellnessStore.self) private var store
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }
    var onProfile: () -> Void = {}
    @State private var name: String = ""
    @State private var targetWeight: String = ""
    @State private var selectedProtocol: FastingProtocol = .sixteenEight
    @State private var remindersEnabled = true
    @State private var healthMessage: String?
    @State private var showPrivacyPolicy = false
    @State private var showClearDataConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false
    @State private var accountMessage: String?
    @State private var showProfileSaved = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    AppHeader(section: "Profile", onProfile: onProfile)

                    ProfileAvatar(
                        name: WellnessGuide.firstName(from: name) ?? store.greetingName,
                        photoURL: store.authUser?.photoURL
                    )
                    .padding(.top, 4.0)

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 16) {
                            labeledField("Name", text: $name)
                            labeledField("Target weight (\(store.weightUnitLabel))", text: $targetWeight, mode: AeroKeyboardMode.decimal)

                            Toggle(isOn: Binding(
                                get: { store.usesPounds },
                                set: { newValue in
                                    store.setUsesPounds(newValue)
                                    targetWeight = String(format: "%.1f", store.targetWeightDisplay)
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Weight in pounds")
                                        .foregroundStyle(.white)
                                    Text(store.usesPounds ? "Currently showing lb" : "Currently showing kg")
                                        .font(.caption)
                                        .foregroundStyle(RestFitTheme.muted)
                                }
                            }
                            .tint(RestFitTheme.mint)

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

                            Toggle(isOn: $remindersEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Fasting reminders")
                                        .foregroundStyle(.white)
                                    Text("Hydration and fast-complete notifications")
                                        .font(.caption)
                                        .foregroundStyle(RestFitTheme.muted)
                                }
                            }
                            .tint(RestFitTheme.mint)

                            Toggle(isOn: Binding(
                                get: { store.backgroundAnimationEnabled },
                                set: { store.setBackgroundAnimationEnabled($0) }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Background animation")
                                        .foregroundStyle(.white)
                                    Text("Drifting glow on the sign-in screen")
                                        .font(.caption)
                                        .foregroundStyle(RestFitTheme.muted)
                                }
                            }
                            .tint(RestFitTheme.mint)

                            MintButton(title: "Save Profile") {
                                let entered = Double(targetWeight) ?? store.targetWeightDisplay
                                store.updateProfile(
                                    name: name,
                                    targetWeight: store.kilogramsFromDisplay(entered),
                                    fastingProtocol: selectedProtocol
                                )
                                store.setRemindersEnabled(remindersEnabled)
                                if remindersEnabled && store.isFasting {
                                    store.scheduleReminders()
                                } else if !remindersEnabled {
                                    store.cancelReminders()
                                }
                                withAnimation(.easeOut(duration: 0.18)) {
                                    showProfileSaved = true
                                }
                                Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 1_600_000_000)
                                    withAnimation(.easeIn(duration: 0.18)) {
                                        showProfileSaved = false
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Health data")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(HealthDataService.authorizationStatusDescription())
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)

                        #if !SKIP
                        MintButton(title: "Import from Apple Health") {
                            Task {
                                healthMessage = await store.importHealthData()
                            }
                        }
                        #endif

                        if let healthMessage {
                            Text(healthMessage)
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.mint)
                        }
                    }
                }
                .padding(.horizontal, 24)

                WeightPanel()
                    .padding(.horizontal, 24)

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                        if let user = store.authUser {
                            Text(user.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(user.email)
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.muted)
                        }
                        Button {
                            store.signOut()
                        } label: {
                            Text("Sign out")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(RestFitTheme.coral)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RestFitTheme.coral.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                            showClearDataConfirm = true
                        } label: {
                            Text("Clear on-device data")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                            showDeleteAccountConfirm = true
                        } label: {
                            Text(isDeletingAccount ? "Deleting…" : "Delete account")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RestFitTheme.coral.opacity(0.35))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(isDeletingAccount)

                        if let accountMessage {
                            Text(accountMessage)
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.mint)
                        }

                        Text("Clear on-device data removes wellness logs but keeps your sign-in (\(RestFitLegal.deleteDataURL)). Delete account removes your Stella Fit login and local data (\(RestFitLegal.deleteAccountURL)).")
                            .font(.caption2)
                            .foregroundStyle(RestFitTheme.faint)
                    }
                }
                .padding(.horizontal, 24)

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About \(RestFitLegal.appDisplayName)")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Track fasting, sleep, weight, and workouts in one place. Tips are based on what you log — not medical advice.")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                        Text(RestFitLegal.shortDisclaimer)
                            .font(.caption2)
                            .foregroundStyle(RestFitTheme.coral)
                        Text("Version \(RestFitLegal.appVersionLabel)")
                            .font(.caption2)
                            .foregroundStyle(RestFitTheme.faint)

                        Button {
                            showPrivacyPolicy = true
                        } label: {
                            Text("Privacy Policy")
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
                .padding(.horizontal, 24)
            }
            .padding(.bottom, keyboard.isPresented ? 360.0 : AppLayout.scrollTailPadding)
            }

            if showProfileSaved {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                Text("Profile saved")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 18)
                    .background(RestFitTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(RestFitTheme.mint.opacity(0.55), lineWidth: 1)
                    )
                    .shadow(color: RestFitTheme.mint.opacity(0.25), radius: 18.0, x: 0.0, y: 8.0)
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .alert("Clear on-device data?", isPresented: $showClearDataConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear data", role: .destructive) {
                store.clearOnDeviceDataKeepingAccount()
                name = store.profile.name
                targetWeight = String(format: "%.1f", store.targetWeightDisplay)
                selectedProtocol = store.profile.fastingProtocol
                remindersEnabled = store.remindersEnabled
                accountMessage = "On-device wellness data cleared. Your account is still signed in."
            }
        } message: {
            Text("This deletes fasting, sleep, weight, workout, and other logs stored on this device. Your Stella Fit account sign-in is kept.")
        }
        .alert("Delete account?", isPresented: $showDeleteAccountConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete account", role: .destructive) {
                Task { @MainActor in
                    isDeletingAccount = true
                    accountMessage = nil
                    defer { isDeletingAccount = false }
                    do {
                        try await store.deleteAccountAndLocalData()
                    } catch {
                        accountMessage = error.localizedDescription
                    }
                }
            }
        } message: {
            Text("This deletes your Stella Fit account (Firebase email login when applicable), signs you out, and clears on-device data. Google users should also revoke Stella Fit access in their Google Account if desired. See \(RestFitLegal.deleteAccountURL)")
        }
        .onAppear {
            name = store.profile.name
            targetWeight = String(format: "%.1f", store.targetWeightDisplay)
            selectedProtocol = store.profile.fastingProtocol
            remindersEnabled = store.remindersEnabled
        }
    }

    private func labeledField(_ title: String, text: Binding<String>, mode: AeroKeyboardMode = .text) -> some View {
        AeroTextField(title: title, text: text, mode: mode, placeholder: title, minHeight: 48.0)
    }
}

struct LogSleepSheet: View {
    @Environment(WellnessStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var hours = 7
    @State private var minutes = 45
    @State private var quality = 80

    var body: some View {
        NavigationStack {
            Form {
                Picker("Hours", selection: $hours) {
                    ForEach(0..<15, id: \.self) { hour in
                        Text("\(hour) h").tag(hour)
                    }
                }
                Picker("Minutes", selection: $minutes) {
                    ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { minute in
                        Text("\(minute) m").tag(minute)
                    }
                }
                Picker("Quality", selection: $quality) {
                    ForEach(Array(stride(from: 0, through: 100, by: 5)), id: \.self) { score in
                        Text("\(score)%").tag(score)
                    }
                }
            }
            .navigationTitle("Log Sleep")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.logSleep(hours: hours, minutes: minutes, quality: quality)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AddWeightSheet: View {
    @Environment(WellnessStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }
    @State private var weightText = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
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
            .navigationTitle("Add Weight")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let weight = Double(weightText) {
                            store.logWeight(store.kilogramsFromDisplay(weight))
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
