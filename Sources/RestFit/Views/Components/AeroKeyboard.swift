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
    var cursorIndex: Int = 0

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
        self.cursorIndex = text.count

        if isPresented && !switchingField {
            return
        }

        if !isPresented {
            openedAt = Date()
            withAnimation(AppLayout.keyboardAnimation) {
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
        withAnimation(AppLayout.keyboardAnimation) {
            isPresented = false
        }
        onChange = nil
        onDone = nil
        activeFieldTitle = ""
        cursorIndex = 0
        openedAt = nil
    }

    func moveCursor(to index: Int) {
        cursorIndex = min(max(0, index), draft.count)
    }

    func insert(_ chunk: String) {
        let index = min(max(0, cursorIndex), draft.count)
        let before = draft.prefix(index)
        let after = draft.dropFirst(index)
        draft = String(before) + chunk + String(after)
        cursorIndex = index + chunk.count
        onChange?(draft)
    }

    func deleteBackward() {
        guard cursorIndex > 0, !draft.isEmpty else { return }
        let index = cursorIndex - 1
        let before = draft.prefix(index)
        let after = draft.dropFirst(index + 1)
        draft = String(before) + String(after)
        cursorIndex = index
        onChange?(draft)
    }

    func clear() {
        draft = ""
        cursorIndex = 0
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
    var trailingLabel: String?

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
                    if let trailingLabel {
                        Text(trailingLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isActive ? RestFitTheme.mint : RestFitTheme.mint.opacity(0.85))
                    } else {
                        Image(systemName: mode == .secure ? "lock.fill" : "keyboard")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isActive ? RestFitTheme.mint : RestFitTheme.mint.opacity(0.85))
                    }
                }
                .padding(.horizontal, 18.0)
                .padding(.vertical, 16.0)
                .frame(minHeight: minHeight)
                .background {
                    if isActive {
                        Color.clear
                    } else {
                        aeroFill
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16.0, style: .continuous)
                        .stroke(isActive ? activeStroke : aeroStroke, lineWidth: isActive ? 1.8 : 1.2)
                )
                .shadow(
                    color: RestFitTheme.mint.opacity(isActive ? 0.0 : 0.12),
                    radius: isActive ? 0.0 : 12.0,
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
                    AeroKeyboardPanel(compact: compact)
                        .padding(.horizontal, compact ? 6.0 : 10.0)
                        .padding(.bottom, bottomInset + 6.0)
                        .frame(maxWidth: min(geo.size.width, 680.0))
                        .frame(maxWidth: .infinity)
                        .transition(AppLayout.keyboardTransition)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .animation(AppLayout.keyboardAnimation, value: keyboard.isPresented)
    }
}

// MARK: - Panel

private struct AeroKeyboardPanel: View {
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }
    let compact: Bool

    @State private var shifted = false
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
                    AeroKeyboardDraftPreview(compact: compact)
                }
                Spacer(minLength: 8.0)
                doneButton
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
        .onChange(of: keyboard.activeFieldTitle) { _, _ in
            shifted = false
            showingSymbols = false
        }
    }

    private var doneButton: some View {
        Button {
            finishFromDoneButton()
        } label: {
            Text("Done")
                .font(.body.weight(.bold))
                .foregroundStyle(RestFitTheme.canvas)
                .padding(.horizontal, 22.0)
                .padding(.vertical, 12.0)
                .background(
                    Capsule()
                        .fill(RestFitTheme.mint)
                        .shadow(color: RestFitTheme.mint.opacity(0.25), radius: 6.0)
                )
        }
        .buttonStyle(.plain)
    }

    private func finishFromDoneButton() {
        AeroHaptics.lightTap()
        keyboard.finish()
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
                actionKey(id: "action-shift", label: "⇧", extraWide: compact ? 72.0 : 80.0, primary: shifted) {
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
                    numberKey(".")
                } else {
                    numberKey("C", id: "action-clear") {
                        keyboard.clear()
                        flashKey("action-clear")
                    }
                }
                numberKey("0")
                numberKey("⌫", id: "action-delete") {
                    keyboard.deleteBackward()
                    flashKey("action-delete")
                }
            }
            actionKey(id: "action-done", label: "Done", flex: true, primary: true, tall: true) {
                finishFromDoneButton()
            }
        }
    }

    @ViewBuilder
    private func numberKey(_ label: String, id: String? = nil, action: (() -> Void)? = nil) -> some View {
        if let action, let id {
            actionKey(id: id, label: label, flex: true, action: action)
        } else {
            letterKey(label)
                .frame(maxWidth: .infinity)
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
        extraWide: CGFloat? = nil,
        flex: Bool = false,
        primary: Bool = false,
        tall: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let glowing = glowingKey == id
        let keyWidth: CGFloat? = extraWide ?? (wide ? 56.0 : nil)
        return Button(action: action) {
            keyFace(label: label, glowing: glowing, primary: primary || label == "Done", tall: tall)
                .frame(maxWidth: flex ? .infinity : keyWidth)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: flex ? .infinity : nil)
    }

    private func keyFace(label: String, glowing: Bool, primary: Bool, tall: Bool = false) -> some View {
        let fontSize = label.count > 2 ? (compact ? 12.0 : 13.0) : keyFontSize
        let height = tall ? keyHeight + 6.0 : keyHeight
        return Text(label)
            .font(.system(size: tall ? fontSize + 1.0 : fontSize, weight: .bold))
            .foregroundStyle(primary ? RestFitTheme.canvas : .white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(keyBackground(primary: primary, glowing: glowing))
            .overlay(keyGlowOverlay(glowing: glowing))
            .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
            .scaleEffect(glowing ? 1.04 : 1.0)
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
            .shadow(color: glowing ? RestFitTheme.mint.opacity(0.85) : .clear, radius: glowing ? 12.0 : 0.0)
            .shadow(color: glowing ? Color.white.opacity(0.45) : .clear, radius: glowing ? 4.0 : 0.0)
    }

    private func flashKey(_ id: String) {
        withAnimation(.easeOut(duration: 0.09)) {
            glowingKey = id
        }
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            if glowingKey == id {
                withAnimation(.easeIn(duration: 0.11)) {
                    glowingKey = nil
                }
            }
        }
    }

    private func isAlphabeticKey(_ raw: String) -> Bool {
        guard raw.count == 1 else { return false }
        let lower = raw.lowercased()
        return "abcdefghijklmnopqrstuvwxyz".contains(lower)
    }
}

private struct AeroKeyboardDraftPreview: View {
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }
    let compact: Bool

    @State private var cursorVisible = true

    private var previewFontSize: CGFloat { compact ? 19.0 : 22.0 }
    private var characterCount: Int { keyboard.draft.count }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                if keyboard.draft.isEmpty {
                    cursorReticle
                    Button {
                        keyboard.moveCursor(to: 0)
                    } label: {
                        Text(keyboard.placeholder)
                            .font(RestFitTheme.manrope(size: previewFontSize, bold: true))
                            .foregroundStyle(RestFitTheme.faint)
                            .lineLimit(1)
                            .background(Color.clear)
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(0..<characterCount, id: \.self) { index in
                        if keyboard.cursorIndex == index {
                            cursorReticle
                        }
                        characterButton(at: index)
                    }
                    if keyboard.cursorIndex == characterCount {
                        cursorReticle
                    }
                    Button {
                        keyboard.moveCursor(to: characterCount)
                    } label: {
                        Color.clear
                            .frame(width: 16.0, height: previewFontSize * 1.1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
        }
        .background(Color.clear)
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: keyboard.activeFieldTitle) {
            cursorVisible = true
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(520))
                cursorVisible.toggle()
            }
        }
    }

    private var cursorReticle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1.0, style: .continuous)
                .fill(RestFitTheme.mint.opacity(cursorVisible ? 0.95 : 0.25))
                .frame(width: 2.0, height: previewFontSize * 1.05)
                .shadow(color: RestFitTheme.mint.opacity(cursorVisible ? 0.75 : 0.0), radius: 5.0)

            Circle()
                .stroke(RestFitTheme.mint.opacity(cursorVisible ? 0.55 : 0.0), lineWidth: 1.0)
                .frame(width: 10.0, height: 10.0)
                .offset(y: -(previewFontSize * 0.62))
        }
        .padding(.horizontal, 1.0)
        .animation(.easeInOut(duration: 0.12), value: cursorVisible)
    }

    private func characterButton(at index: Int) -> some View {
        let glyph = displayCharacter(at: index)
        let atCursor = keyboard.cursorIndex == index
        return Button {
            keyboard.moveCursor(to: index)
        } label: {
            Text(glyph)
                .font(RestFitTheme.manrope(size: previewFontSize, bold: true))
                .foregroundStyle(atCursor ? RestFitTheme.mint : .white)
                .padding(.horizontal, 2.0)
                .padding(.vertical, 1.0)
                .background(Color.clear)
        }
        .buttonStyle(.plain)
    }

    private func displayCharacter(at index: Int) -> String {
        guard index >= 0, index < keyboard.draft.count else { return "" }
        if keyboard.mode == .secure {
            return "•"
        }
        return String(keyboard.draft.dropFirst(index).prefix(1))
    }
}

/// Reserve space above the custom keyboard overlay on small / tall layouts.
enum AeroKeyboardLayout {
    static func contentInset(compact: Bool, keyboardVisible: Bool) -> CGFloat {
        guard keyboardVisible else { return 0.0 }
        return compact ? 300.0 : 340.0
    }
}

enum AeroHaptics {
    static func lightTap() {
        #if SKIP
        guard let context = UIApplication.shared.androidActivity else { return }
        let service = context.getSystemService(android.content.Context.VIBRATOR_SERVICE)
        guard let vibrator = service as? android.os.Vibrator else { return }
        if android.os.Build.VERSION.SDK_INT >= 26 {
            vibrator.vibrate(
                android.os.VibrationEffect.createOneShot(14, android.os.VibrationEffect.DEFAULT_AMPLITUDE)
            )
        }
        #endif
    }
}
