import SwiftUI
import Observation

enum AeroKeyboardMode: Equatable {
    case text
    case email
    case secure
    case decimal
    case number
}

@MainActor
@Observable final class AeroKeyboardController {
    static let shared = AeroKeyboardController()
    var isPresented: Bool = false
    var title: String = ""
    var draft: String = ""
    var mode: AeroKeyboardMode = .text
    var placeholder: String = ""
    var activeFieldTitle: String = ""

    /// Called on every keystroke so the bound field stays live.
    var onChange: ((String) -> Void)?
    /// Called when the user taps Done / Return.
    var onDone: (() -> Void)?

    private var openedAt: Date?
    private let minimumVisibleSeconds: TimeInterval = 0.55

    func present(
        title: String,
        text: String,
        mode: AeroKeyboardMode,
        placeholder: String = "",
        onChange: @escaping (String) -> Void,
        onDone: (() -> Void)? = nil
    ) {
        let switchingField = isPresented && activeFieldTitle != title

        self.title = title
        self.draft = text
        self.mode = mode
        self.placeholder = placeholder
        self.onChange = onChange
        self.onDone = onDone
        self.activeFieldTitle = title

        if isPresented && !switchingField {
            return
        }

        if !isPresented {
            openedAt = Date()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                isPresented = true
            }
        }
    }

    func dismiss(force: Bool = false) {
        guard isPresented else { return }
        if !force,
           let openedAt,
           Date().timeIntervalSince(openedAt) < minimumVisibleSeconds {
            return
        }
        withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
            isPresented = false
        }
        onChange = nil
        onDone = nil
        activeFieldTitle = ""
        openedAt = nil
    }

    func insert(_ chunk: String) {
        draft += chunk
        onChange?(draft)
    }

    func deleteBackward() {
        guard !draft.isEmpty else { return }
        draft = String(draft.dropLast())
        onChange?(draft)
    }

    func clear() {
        draft = ""
        onChange?(draft)
    }

    func finish() {
        onDone?()
        dismiss(force: true)
    }
}

// MARK: - Field (no system TextField → no system keyboard)

struct AeroTextField: View {
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }

    let title: String
    @Binding var text: String
    var mode: AeroKeyboardMode = .text
    var placeholder: String = ""
    var minHeight: CGFloat = 58.0

    var body: some View {
        let isActive = keyboard.isPresented && keyboard.activeFieldTitle == title
        Button {
            keyboard.present(
                title: title,
                text: text,
                mode: mode,
                placeholder: placeholder.isEmpty ? title : placeholder,
                onChange: { text = $0 }
            )
        } label: {
            VStack(alignment: .leading, spacing: 6.0) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text(displayText)
                        .font(RestFitTheme.manrope(size: 17.0, bold: false))
                        .foregroundStyle(text.isEmpty ? RestFitTheme.faint : .white)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: mode == .secure ? "lock.fill" : "keyboard")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isActive ? RestFitTheme.mint : RestFitTheme.mint.opacity(0.85))
                }
                .padding(.horizontal, 18.0)
                .padding(.vertical, 16.0)
                .frame(minHeight: minHeight)
                .background(aeroFill)
                .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16.0, style: .continuous)
                        .stroke(isActive ? activeStroke : aeroStroke, lineWidth: isActive ? 1.8 : 1.2)
                )
                .shadow(
                    color: RestFitTheme.mint.opacity(isActive ? 0.28 : 0.12),
                    radius: isActive ? 16.0 : 12.0,
                    x: 0.0,
                    y: 4.0
                )
            }
        }
        .buttonStyle(.plain)
    }

    private var displayText: String {
        if text.isEmpty { return placeholder.isEmpty ? title : placeholder }
        if mode == .secure {
            return String(repeating: "•", count: min(text.count, 24))
        }
        return text
    }

    private var aeroFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.16),
                Color.white.opacity(0.05),
                RestFitTheme.mint.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var aeroStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.42),
                RestFitTheme.mint.opacity(0.35),
                Color.white.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var activeStroke: LinearGradient {
        LinearGradient(
            colors: [
                RestFitTheme.mint.opacity(0.95),
                Color.white.opacity(0.55),
                RestFitTheme.mint.opacity(0.45)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Overlay shell

struct AeroKeyboardOverlay: View {
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 740.0 || geo.size.width < 360.0
            let bottomInset = max(10.0, geo.safeAreaInsets.bottom)
            ZStack(alignment: .bottom) {
                if keyboard.isPresented {
                    Color.black.opacity(0.48)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .allowsHitTesting(false)

                    AeroKeyboardPanel(compact: compact)
                        .padding(.horizontal, compact ? 6.0 : 10.0)
                        .padding(.bottom, bottomInset + 6.0)
                        .frame(maxWidth: min(geo.size.width, 680.0))
                        .frame(maxWidth: .infinity)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: keyboard.isPresented)
    }
}

// MARK: - Panel

private struct AeroKeyboardPanel: View {
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }
    let compact: Bool

    @State private var shifted = true
    @State private var showingSymbols = false
    @State private var glowingKey: String? = nil

    private var keyHeight: CGFloat { compact ? 40.0 : 44.0 }
    private var keyFontSize: CGFloat { compact ? 16.0 : 18.0 }
    private var rowSpacing: CGFloat { compact ? 6.0 : 8.0 }

    var body: some View {
        VStack(spacing: rowSpacing + 4.0) {
            Capsule()
                .fill(Color.white.opacity(0.28))
                .frame(width: 42.0, height: 4.0)
                .padding(.top, 8.0)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(keyboard.title.uppercased())
                        .font(.system(size: compact ? 10.0 : 11.0, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(RestFitTheme.mint)
                    Text(previewText)
                        .font(RestFitTheme.manrope(size: compact ? 19.0 : 22.0, bold: true))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 8.0)
                Button("Done") { keyboard.finish() }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RestFitTheme.canvas)
                    .padding(.horizontal, 14.0)
                    .padding(.vertical, 8.0)
                    .background(RestFitTheme.mint)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 8.0)

            Group {
                if keyboard.mode == .decimal || keyboard.mode == .number {
                    numberPad
                } else if showingSymbols {
                    symbolsPad
                } else {
                    letterPad
                }
            }
        }
        .padding(compact ? 12.0 : 14.0)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 24.0 : 28.0, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 24.0 : 28.0, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.45),
                            RestFitTheme.mint.opacity(0.4),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: RestFitTheme.mint.opacity(0.22), radius: 28.0, x: 0.0, y: -4.0)
    }

    private var previewText: String {
        if keyboard.draft.isEmpty {
            return keyboard.placeholder
        }
        if keyboard.mode == .secure {
            return String(repeating: "•", count: min(keyboard.draft.count, 28))
        }
        return keyboard.draft
    }

    private var panelBackground: some View {
        ZStack {
            RestFitTheme.surface.opacity(0.82)
            LinearGradient(
                colors: [
                    Color.white.opacity(0.22),
                    RestFitTheme.mint.opacity(0.08),
                    Color.clear,
                    RestFitTheme.coral.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(RestFitTheme.mint.opacity(0.16))
                .frame(width: 180.0, height: 180.0)
                .blur(radius: 36.0)
                .offset(x: 90.0, y: -40.0)
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 140.0, height: 140.0)
                .blur(radius: 28.0)
                .offset(x: -80.0, y: 50.0)
        }
    }

    private var letterPad: some View {
        VStack(spacing: rowSpacing) {
            keyRow(["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"])
            keyRow(["A", "S", "D", "F", "G", "H", "J", "K", "L"])
            HStack(spacing: 6.0) {
                actionKey(id: "action-shift", label: shifted ? "⇧" : "⇧", wide: true) {
                    shifted.toggle()
                    flashKey("action-shift")
                }
                keyRowInline(["Z", "X", "C", "V", "B", "N", "M"])
                actionKey(id: "action-delete", label: "⌫", wide: true) {
                    keyboard.deleteBackward()
                    flashKey("action-delete")
                }
            }
            HStack(spacing: 6.0) {
                actionKey(id: "action-symbols", label: "123", wide: true) {
                    showingSymbols = true
                    flashKey("action-symbols")
                }
                if keyboard.mode == .email {
                    letterKey("@")
                    letterKey(".")
                }
                actionKey(id: "action-space", label: "space", flex: true) {
                    keyboard.insert(" ")
                    flashKey("action-space")
                }
                actionKey(id: "action-return", label: "return", wide: true, primary: true) {
                    flashKey("action-return")
                }
            }
        }
    }

    private var symbolsPad: some View {
        VStack(spacing: rowSpacing) {
            keyRow(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
            keyRow(["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""])
            keyRow([".", ",", "?", "!", "'", "#", "%", "*", "+", "="])
            HStack(spacing: 6.0) {
                actionKey(id: "action-abc", label: "ABC", wide: true) {
                    showingSymbols = false
                    flashKey("action-abc")
                }
                actionKey(id: "action-delete", label: "⌫", wide: true) {
                    keyboard.deleteBackward()
                    flashKey("action-delete")
                }
                actionKey(id: "action-space", label: "space", flex: true) {
                    keyboard.insert(" ")
                    flashKey("action-space")
                }
                actionKey(id: "action-return", label: "return", wide: true, primary: true) {
                    flashKey("action-return")
                }
            }
        }
    }

    private var numberPad: some View {
        VStack(spacing: rowSpacing) {
            keyRow(["1", "2", "3"])
            keyRow(["4", "5", "6"])
            keyRow(["7", "8", "9"])
            HStack(spacing: 6.0) {
                if keyboard.mode == .decimal {
                    letterKey(".")
                } else {
                    actionKey(id: "action-clear", label: "C", wide: true) {
                        keyboard.clear()
                        flashKey("action-clear")
                    }
                }
                letterKey("0")
                actionKey(id: "action-delete", label: "⌫", wide: true) {
                    keyboard.deleteBackward()
                    flashKey("action-delete")
                }
            }
            actionKey(id: "action-done", label: "Done", flex: true, primary: true) {
                keyboard.finish()
            }
        }
    }

    private func keyRow(_ keys: [String]) -> some View {
        HStack(spacing: 6.0) {
            ForEach(keys, id: \.self) { key in
                letterKey(key)
            }
        }
    }

    private func keyRowInline(_ keys: [String]) -> some View {
        HStack(spacing: 6.0) {
            ForEach(keys, id: \.self) { key in
                letterKey(key)
            }
        }
    }

    private func letterKey(_ raw: String) -> some View {
        let isAlphaKey = isAlphabeticKey(raw)
        let output: String = {
            if isAlphaKey {
                return shifted ? raw.uppercased() : raw.lowercased()
            }
            return raw
        }()
        let keyID = "letter-\(raw.uppercased())"
        let glowing = glowingKey == keyID
        return Button {
            keyboard.insert(output)
            if shifted && isAlphaKey && keyboard.mode != .secure {
                shifted = false
            }
            flashKey(keyID)
        } label: {
            keyFace(label: output, glowing: glowing, primary: false)
        }
        .buttonStyle(.plain)
    }

    private func actionKey(
        id: String,
        label: String,
        wide: Bool = false,
        flex: Bool = false,
        primary: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let glowing = glowingKey == id
        return Button(action: action) {
            keyFace(label: label, glowing: glowing, primary: primary || label == "Done")
                .frame(maxWidth: flex ? .infinity : (wide ? 56.0 : .infinity))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: flex ? .infinity : nil)
    }

    private func keyFace(label: String, glowing: Bool, primary: Bool) -> some View {
        let fontSize = label.count > 2 ? (compact ? 12.0 : 13.0) : keyFontSize
        return Text(label)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(primary ? RestFitTheme.canvas : .white)
            .frame(maxWidth: .infinity)
            .frame(height: keyHeight)
            .background(keyBackground(primary: primary, glowing: glowing))
            .overlay(keyGlowOverlay(glowing: glowing))
            .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
            .scaleEffect(glowing ? 1.05 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.62), value: glowing)
    }

    private func keyBackground(primary: Bool, glowing: Bool) -> some View {
        Group {
            if primary {
                LinearGradient(
                    colors: glowing
                        ? [Color.white.opacity(0.95), RestFitTheme.mint]
                        : [RestFitTheme.mint, RestFitTheme.mint.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if glowing {
                LinearGradient(
                    colors: [
                        RestFitTheme.mint.opacity(0.42),
                        Color.white.opacity(0.24),
                        RestFitTheme.mint.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color.white.opacity(0.18), Color.white.opacity(0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private func keyGlowOverlay(glowing: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10.0, style: .continuous)
            .stroke(
                glowing ? RestFitTheme.mint.opacity(0.95) : Color.white.opacity(0.22),
                lineWidth: glowing ? 2.0 : 1.0
            )
            .shadow(color: glowing ? RestFitTheme.mint.opacity(0.75) : .clear, radius: glowing ? 14.0 : 0.0)
            .shadow(color: glowing ? Color.white.opacity(0.35) : .clear, radius: glowing ? 6.0 : 0.0)
    }

    private func flashKey(_ id: String) {
        glowingKey = id
        Task {
            try? await Task.sleep(for: .milliseconds(340))
            if glowingKey == id {
                glowingKey = nil
            }
        }
    }

    private func isAlphabeticKey(_ raw: String) -> Bool {
        guard raw.count == 1 else { return false }
        let lower = raw.lowercased()
        return "abcdefghijklmnopqrstuvwxyz".contains(lower)
    }
}

/// Reserve space above the custom keyboard overlay on small / tall layouts.
enum AeroKeyboardLayout {
    static func contentInset(compact: Bool, keyboardVisible: Bool) -> CGFloat {
        guard keyboardVisible else { return 0.0 }
        return compact ? 300.0 : 340.0
    }
}
