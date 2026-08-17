import SwiftUI

struct AlarmRingOverlay: View {
    private var ring: AlarmRingController { AlarmRingController.shared }
    @Environment(WellnessStore.self) private var store
    @State private var pulse = false
    @State private var spin = false

    var body: some View {
        ZStack {
            if ring.isRinging, let alarm = ring.alarm {
                RestFitTheme.canvas
                    .ignoresSafeArea()
                    .overlay {
                        AlarmSplashAtmosphere(pulse: pulse, spin: spin)
                    }
                    .transition(.opacity)

                VStack(spacing: 28.0) {
                    Spacer()

                    ZStack {
                        ForEach(ringPulseSizes, id: \.self) { size in
                            Circle()
                                .stroke(RestFitTheme.mint.opacity(pulse ? 0.42 : 0.12), lineWidth: 2.0)
                                .frame(width: size, height: size)
                                .scaleEffect(pulse ? 1.08 : 0.92)
                        }

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        RestFitTheme.mint.opacity(0.35),
                                        RestFitTheme.coral.opacity(0.12),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 8.0,
                                    endRadius: 120.0
                                )
                            )
                            .frame(width: 220.0, height: 220.0)
                            .blur(radius: 8.0)

                        Image(systemName: "alarm.fill")
                            .font(.system(size: 72.0, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: RestFitTheme.mint.opacity(0.65), radius: 24.0)
                            .rotationEffect(.degrees(spin ? 8.0 : -8.0))
                    }
                    .frame(height: 260.0)

                    VStack(spacing: 10.0) {
                        Text(alarm.timeLabel)
                            .font(.system(size: 56.0, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(alarm.label)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(RestFitTheme.mint)
                        Text("Stella Fit alarm")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RestFitTheme.muted)
                    }

                    Spacer()

                    VStack(spacing: 12.0) {
                        Button {
                            store.snoozeRingingAlarm()
                        } label: {
                            Text("Snooze 9 min")
                                .font(.body.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16.0)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 18.0, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18.0, style: .continuous)
                                        .stroke(Color.white.opacity(0.22), lineWidth: 1.0)
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.dismissRingingAlarm()
                        } label: {
                            Text("Dismiss")
                                .font(.body.weight(.bold))
                                .foregroundStyle(RestFitTheme.canvas)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16.0)
                                .background(RestFitTheme.mint)
                                .clipShape(RoundedRectangle(cornerRadius: 18.0, style: .continuous))
                                .shadow(color: RestFitTheme.mint.opacity(0.35), radius: 18.0, y: 8.0)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 28.0)
                    .padding(.bottom, 36.0)
                }
                .transition(
                    .asymmetric(
                        insertion: AnyTransition.scale(scale: 0.88).combined(with: AnyTransition.opacity),
                        removal: AnyTransition.scale(scale: 1.04).combined(with: AnyTransition.opacity)
                    )
                )
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.84), value: ring.isRinging)
        .onChange(of: ring.isRinging) { _, ringing in
            if ringing {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    pulse = true
                }
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                    spin = true
                }
            } else {
                pulse = false
                spin = false
            }
        }
    }

    private var ringPulseSizes: [CGFloat] {
        [180.0, 230.0, 280.0]
    }
}

private struct AlarmSplashAtmosphere: View {
    var pulse: Bool
    var spin: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(RestFitTheme.mint.opacity(0.18))
                .frame(width: 320.0, height: 320.0)
                .blur(radius: 60.0)
                .offset(x: pulse ? -40.0 : -90.0, y: pulse ? -120.0 : -180.0)

            Circle()
                .fill(RestFitTheme.coral.opacity(0.16))
                .frame(width: 280.0, height: 280.0)
                .blur(radius: 54.0)
                .offset(x: pulse ? 80.0 : 40.0, y: pulse ? 160.0 : 220.0)

            Circle()
                .stroke(RestFitTheme.mint.opacity(0.18), lineWidth: 1.5)
                .frame(width: 420.0, height: 420.0)
                .rotationEffect(.degrees(spin ? 24.0 : -18.0))
        }
        .allowsHitTesting(false)
    }
}
