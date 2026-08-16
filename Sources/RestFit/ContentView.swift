import SwiftUI

enum AppTab: String, Hashable, CaseIterable {
    case home, fast, sleep, workout, alarm, profile

    static let barTabs: [AppTab] = [.home, .fast, .sleep, .workout, .alarm]

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
}

struct ContentView: View {
    @State private var store = WellnessStore()
    @State private var selectedTab: AppTab = .home
    @State private var showLogSleep = false
    @State private var showAddWeight = false

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
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showLogSleep) {
            LogSleepSheet()
                .environment(store)
        }
        .sheet(isPresented: $showAddWeight) {
            AddWeightSheet()
                .environment(store)
        }
        .task {
            while !Task.isCancelled {
                store.tick()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private var mainApp: some View {
        ZStack(alignment: .bottom) {
            RestFitTheme.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                tabContent
                    .frame(maxWidth: 440)
                    .frame(maxWidth: .infinity)
            }

            BottomTabBar(selectedTab: $selectedTab)
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView(
                onAddWeight: { showAddWeight = true },
                onOpenSleep: { selectedTab = .sleep },
                onProfile: { selectedTab = .profile }
            )
        case .fast:
            FastingView(onProfile: { selectedTab = .profile })
        case .sleep:
            SleepView(
                onManualLog: { showLogSleep = true },
                onProfile: { selectedTab = .profile }
            )
        case .workout:
            WorkoutView(onProfile: { selectedTab = .profile })
        case .alarm:
            AlarmView(onProfile: { selectedTab = .profile })
        case .profile:
            ProfileView(onProfile: { selectedTab = .profile })
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
                AppHeader(name: store.profile.name, onProfile: onProfile)

                WelcomeSection(
                    greeting: WellnessGuide.greeting(name: store.profile.name),
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
            .padding(.bottom, 120)
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
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack {
            ForEach(AppTab.barTabs, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        if selectedTab == tab {
                            Circle()
                                .fill(RestFitTheme.mint)
                                .frame(width: 6, height: 6)
                                .offset(y: -8)
                        }

                        Image(tab.icon, bundle: .module)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(selectedTab == tab ? RestFitTheme.mint : RestFitTheme.faint)

                        Text(tab.title.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(selectedTab == tab ? RestFitTheme.mint : RestFitTheme.faint)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .padding(.bottom, 28)
        .background(RestFitTheme.surface.opacity(0.95))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(RestFitTheme.line.opacity(0.4))
                .frame(height: 1)
        }
    }
}

struct FastingView: View {
    @Environment(WellnessStore.self) private var store
    var onProfile: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppHeader(name: store.profile.name, onProfile: onProfile)

                Text("Fasting")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

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

                ForEach(store.guidance.filter { $0.icon == "flame.fill" || $0.icon == "drop.fill" || $0.icon == "fork.knife" }) { tip in
                    GuidanceCard(guidance: tip)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 120)
        }
    }
}

struct SleepView: View {
    @Environment(WellnessStore.self) private var store
    let onManualLog: () -> Void
    var onProfile: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppHeader(name: store.profile.name, onProfile: onProfile)

                HStack {
                    Text("Sleep")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
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

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Nights")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)

                        ForEach(store.sleepEntries.sorted { $0.date > $1.date }.prefix(5)) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                        .foregroundStyle(.white)
                                    Text(entry.durationLabel)
                                        .font(.caption)
                                        .foregroundStyle(RestFitTheme.muted)
                                }
                                Spacer()
                                Text("\(entry.qualityScore)%")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RestFitTheme.mint)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.horizontal, 24)

                ForEach(store.guidance.filter { $0.icon == "moon.fill" || $0.icon == "sparkles" }) { tip in
                    GuidanceCard(guidance: tip)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 120)
        }
    }
}

struct ProfileView: View {
    @Environment(WellnessStore.self) private var store
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
                    AppHeader(name: store.profile.name, onProfile: onProfile)

                    Text("Profile")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 16) {
                            labeledField("Name", text: $name)

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

                            labeledField("Target weight (\(store.weightUnitLabel))", text: $targetWeight)

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
                        Text("About Stella Fit")
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
            .padding(.bottom, 120)
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

    private func labeledField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RestFitTheme.muted)
            TextField(title, text: text)
                .textFieldStyle(.plain)
                .padding(12)
                .background(RestFitTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(RestFitTheme.line, lineWidth: 1)
                )
                .foregroundStyle(.white)
        }
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
    @State private var weightText = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Weight in \(store.weightUnitLabel)", text: $weightText)
            }
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
        .onAppear {
            weightText = String(format: "%.1f", store.currentWeightDisplay)
        }
    }
}
