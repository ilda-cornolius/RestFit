import SwiftUI
#if SKIP
import androidx.compose.foundation.layout.imePadding
#endif

struct TitleLoginView: View {
    @Environment(WellnessStore.self) private var store
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }
    @State private var email = ""
    @State private var password = ""
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var animate = false
    @State private var showEmailForm = false
    @State private var hoverEmail = false
    @State private var hoverPassword = false
    @State private var hoverSignIn = false
    @State private var hoverCreate = false
    @State private var hoverEmailEntry = false
    @State private var hoverGoogle = false
    @State private var hoverBack = false

    private var motionEnabled: Bool {
        store.backgroundAnimationEnabled && animate
    }

    var body: some View {
        ZStack {
            RestFitTheme.canvas.ignoresSafeArea()
            LoginAtmosphere(animate: motionEnabled)

            GeometryReader { geo in
                let contentMax = min(520.0, max(320.0, geo.size.width - 24.0))
                let wide = geo.size.width >= 600.0
                let compact = geo.size.height < 740.0 || geo.size.width < 360.0
                let keyboardOpen = keyboard.isPresented
                let centerVertically = !showEmailForm && !keyboardOpen
                let keyboardInset = AeroKeyboardLayout.contentInset(compact: compact, keyboardVisible: keyboardOpen)
                ScrollView {
                    VStack(spacing: 0) {
                        if centerVertically {
                            Spacer(minLength: max(16.0, (geo.size.height - loginBlockHeight(wide: wide, compact: compact)) * 0.5))
                        } else {
                            Spacer(minLength: keyboardOpen ? 8.0 : (compact ? 12.0 : 24.0))
                        }

                        AnimatedLoginLogo(animate: motionEnabled)
                            .scaleEffect(showEmailForm ? 0.72 : 1.0)
                            .frame(height: showEmailForm ? (compact ? 92.0 : 108.0) : (compact ? 120.0 : 150.0))
                            .padding(.bottom, showEmailForm ? 4.0 : 8.0)

                        Text(RestFitLegal.appDisplayName)
                            .font(.system(size: wide ? (showEmailForm ? 40.0 : 52.0) : (showEmailForm ? 34.0 : 44.0), weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: RestFitTheme.mint.opacity(0.35), radius: 16.0, x: 0.0, y: 0.0)

                        if !showEmailForm {
                            Text("Track fasting, sleep, and workouts.\nSign in or create an account to continue.")
                                .font(.body)
                                .foregroundStyle(RestFitTheme.muted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                                .padding(.top, 8)
                        }

                        VStack(spacing: 14) {
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(RestFitTheme.coral)
                                    .multilineTextAlignment(.center)
                            }
                            if let infoMessage {
                                Text(infoMessage)
                                    .font(.caption)
                                    .foregroundStyle(RestFitTheme.mint)
                                    .multilineTextAlignment(.center)
                            }

                            if showEmailForm {
                                emailFormContent
                            } else {
                                methodChooserContent
                            }

                            backgroundAnimationToggle

                            Text(RestFitLegal.shortDisclaimer)
                                .font(.caption2)
                                .foregroundStyle(RestFitTheme.faint)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, showEmailForm ? 20.0 : 32.0)
                        .padding(.bottom, 32.0)

                        if centerVertically {
                            Spacer(minLength: max(16.0, (geo.size.height - loginBlockHeight(wide: wide, compact: compact)) * 0.5))
                        } else {
                            Spacer(minLength: 24.0)
                        }
                    }
                    .frame(maxWidth: contentMax)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, keyboardInset)
                }
                .id("login-\(Int(geo.size.width))x\(Int(geo.size.height))-\(showEmailForm)-\(keyboardOpen)")
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            FirebaseAuthService.configureIfNeeded()
            if !store.isSignedIn, let restored = FirebaseAuthService.restoreSession() {
                store.signIn(restored)
            }
            syncBackgroundAnimation()
        }
        .onChange(of: store.backgroundAnimationEnabled) { _, _ in
            syncBackgroundAnimation()
        }
    }

    private var backgroundAnimationToggle: some View {
        Toggle(isOn: Binding(
            get: { store.backgroundAnimationEnabled },
            set: { store.setBackgroundAnimationEnabled($0) }
        )) {
            HStack(spacing: 8.0) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RestFitTheme.mint)
                Text("Background animation")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RestFitTheme.muted)
            }
        }
        .tint(RestFitTheme.mint)
        .padding(.horizontal, 14.0)
        .padding(.vertical, 10.0)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14.0, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14.0, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1.0)
        )
        .padding(.top, 4.0)
    }

    private func syncBackgroundAnimation() {
        if store.backgroundAnimationEnabled {
            withAnimation(.easeInOut(duration: 5.2).repeatForever(autoreverses: true)) {
                animate = true
            }
        } else {
            animate = false
        }
    }

    private var methodChooserContent: some View {
        Group {
            Button {
                errorMessage = nil
                infoMessage = nil
                showEmailForm = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(RestFitTheme.canvas)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("Sign in with Email")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .modifier(LoginHoverLook(active: hoverEmailEntry, mintFill: false, corner: 16.0))
            }
            .buttonStyle(.plain)
            .restFitOnHover { hoverEmailEntry = $0 }
            .disabled(isWorking)

            if !GoogleAuthConfig.isConfigured {
                Text("Google Sign-In needs a Web client ID. See store/GOOGLE_SIGNIN_SETUP.md.")
                    .font(.caption2)
                    .foregroundStyle(RestFitTheme.faint)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { @MainActor in
                    await signInGoogle()
                }
            } label: {
                HStack(spacing: 12) {
                    Text("G")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RestFitTheme.canvas)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text(isWorking ? "Signing in…" : "Sign in with Google")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .modifier(LoginHoverLook(active: hoverGoogle, mintFill: false, corner: 16.0))
            }
            .buttonStyle(.plain)
            .restFitOnHover { hoverGoogle = $0 }
            .disabled(isWorking || !GoogleAuthConfig.isConfigured)
            .opacity(GoogleAuthConfig.isConfigured ? 1.0 : 0.55)
        }
    }

    private var emailFormContent: some View {
        Group {
            Button {
                errorMessage = nil
                infoMessage = nil
                showEmailForm = false
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                    Text("Back")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(RestFitTheme.mint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .opacity(hoverBack ? 0.85 : 1.0)
            }
            .buttonStyle(.plain)
            .restFitOnHover { hoverBack = $0 }
            .disabled(isWorking)

            AeroTextField(title: "Email", text: $email, mode: AeroKeyboardMode.email, placeholder: "you@email.com")
            AeroTextField(title: "Password", text: $password, mode: AeroKeyboardMode.secure, placeholder: "Password")

            Button {
                Task { @MainActor in
                    await signInEmail()
                }
            } label: {
                Text(isWorking ? "Please wait…" : "Sign in")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(RestFitTheme.canvas)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .modifier(LoginHoverLook(active: hoverSignIn, mintFill: true, corner: 16.0))
            }
            .buttonStyle(.plain)
            .restFitOnHover { hoverSignIn = $0 }
            .disabled(isWorking)

            Button {
                Task { @MainActor in
                    await registerEmail()
                }
            } label: {
                Text("Create account")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .modifier(LoginHoverLook(active: hoverCreate, mintFill: false, corner: 16.0))
            }
            .buttonStyle(.plain)
            .restFitOnHover { hoverCreate = $0 }
            .disabled(isWorking)
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.72))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func signInEmail() async {
        await runAuth {
            let user = try await FirebaseAuthService.signIn(email: email, password: password)
            store.signIn(user)
        }
    }

    private func registerEmail() async {
        await runAuth {
            let user = try await FirebaseAuthService.register(email: email, password: password)
            store.signIn(user)
            infoMessage = "Account created. You’re signed in."
        }
    }

    @MainActor
    private func signInGoogle() async {
        await runAuth {
            infoMessage = "Finishing Google sign-in…"
            let user = try await GoogleAuthService.signIn()
            store.signIn(user)
            infoMessage = nil
        }
    }

    @MainActor
    private func runAuth(_ work: () async throws -> Void) async {
        errorMessage = nil
        infoMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            try await work()
        } catch {
            infoMessage = nil
            if let authError = error as? GoogleAuthError {
                if case .cancelled = authError {
                    errorMessage = "Sign-in was cancelled. Tap Sign in with Google and try again."
                    return
                }
                errorMessage = authError.errorDescription ?? "Google sign-in failed. Try again."
                return
            }
            errorMessage = FirebaseAuthError.userFacingMessage(from: error)
        }
    }

    private func loginBlockHeight(wide: Bool, compact: Bool) -> CGFloat {
        if showEmailForm {
            return compact ? 520.0 : 580.0
        }
        return compact ? 460.0 : (wide ? 520.0 : 500.0)
    }
}

private struct LoginHoverLook: ViewModifier {
    var active: Bool
    var mintFill: Bool
    var corner: Double

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(stroke, lineWidth: active ? 1.6 : 1.0)
            )
            .scaleEffect(active ? 1.035 : 1.0)
            .shadow(
                color: RestFitTheme.mint.opacity(active ? 0.42 : (mintFill ? 0.22 : 0.0)),
                radius: active ? 16.0 : (mintFill ? 10.0 : 0.0),
                x: 0.0,
                y: active ? 8.0 : 4.0
            )
            .animation(.easeOut(duration: 0.16), value: active)
    }

    private var fill: LinearGradient {
        if mintFill {
            return LinearGradient(
                colors: active
                    ? [RestFitTheme.mint, RestFitTheme.mint.opacity(0.82)]
                    : [RestFitTheme.mint, RestFitTheme.mint.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: active
                ? [Color.white.opacity(0.28), RestFitTheme.mint.opacity(0.16)]
                : [Color.white.opacity(0.16), Color.white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var stroke: LinearGradient {
        LinearGradient(
            colors: active
                ? [Color.white.opacity(0.75), RestFitTheme.mint.opacity(0.7)]
                : [Color.white.opacity(0.38), RestFitTheme.mint.opacity(0.18), Color.white.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct LoginAtmosphere: View {
    var animate: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(RestFitTheme.mint.opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 48)
                .offset(x: animate ? -70.0 : -120.0, y: animate ? -180.0 : -240.0)

            Circle()
                .fill(RestFitTheme.coral.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 42)
                .offset(x: animate ? 110.0 : 70.0, y: animate ? 210.0 : 280.0)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 180, height: 180)
                .blur(radius: 30)
                .offset(x: animate ? 40.0 : -20.0, y: animate ? 40.0 : -30.0)

            Circle()
                .stroke(RestFitTheme.mint.opacity(0.12), lineWidth: 1)
                .frame(width: 420, height: 420)
                .rotationEffect(.degrees(animate ? 18.0 : -12.0))
                .offset(y: -40)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct AnimatedLoginLogo: View {
    var animate: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(RestFitTheme.mint.opacity(animate ? 0.22 : 0.08))
                .frame(width: 150, height: 150)
                .blur(radius: 18)

            Circle()
                .stroke(RestFitTheme.mint.opacity(0.28), lineWidth: 2)
                .frame(width: 124, height: 124)
                .scaleEffect(animate ? 1.08 : 0.94)

            Circle()
                .stroke(RestFitTheme.mint.opacity(0.45), lineWidth: 8)
                .frame(width: 96, height: 96)

            Circle()
                .trim(from: 0.12, to: 0.78)
                .stroke(RestFitTheme.coral, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 96, height: 96)
                .rotationEffect(.degrees(animate ? 220.0 : -40.0))

            Image(systemName: "heart.fill")
                .font(.title)
                .foregroundStyle(RestFitTheme.mint)
                .scaleEffect(animate ? 1.12 : 0.92)
                .shadow(color: RestFitTheme.mint.opacity(0.6), radius: 10.0, x: 0.0, y: 0.0)
        }
        .frame(height: 150)
    }
}

extension View {
    /// Hover polish for desktop/iPad pointer devices only.
    /// On Android, a `pointerInput` hover loop steals taps from TextFields and buttons.
    func restFitOnHover(_ handler: @escaping (Bool) -> Void) -> some View {
        #if SKIP
        return self
        #else
        return onHover(perform: handler)
        #endif
    }

    /// Lift content above the software keyboard on Android (edge-to-edge + Fold).
    func restFitImePadding() -> some View {
        #if SKIP
        return composeModifier { modifier in
            modifier.imePadding()
        }
        #else
        return self
        #endif
    }
}
