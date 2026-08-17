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

    /// Called on every keystroke so the bound field stays live.
    var onChange: ((String) -> Void)?
    /// Called when the user taps Done / Return.
    var onDone: (() -> Void)?

    func present(
        title: String,
        text: String,
        mode: AeroKeyboardMode,
        placeholder: String = "",
        onChange: @escaping (String) -> Void,
        onDone: (() -> Void)? = nil
    ) {
        self.title = title
        self.draft = text
        self.mode = mode
        self.placeholder = placeholder
        self.onChange = onChange
        self.onDone = onDone
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            isPresented = true
        }
    }

    func dismiss() {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
            isPresented = false
        }
        onChange = nil
        onDone = nil
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
        dismiss()
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
                        .foregroundStyle(RestFitTheme.mint.opacity(0.85))
                }
                .padding(.horizontal, 18.0)
                .padding(.vertical, 16.0)
                .frame(minHeight: minHeight)
                .background(aeroFill)
                .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16.0, style: .continuous)
                        .stroke(aeroStroke, lineWidth: 1.2)
                )
                .shadow(color: RestFitTheme.mint.opacity(0.12), radius: 12.0, x: 0.0, y: 4.0)
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
}

// MARK: - Overlay shell

struct AeroKeyboardOverlay: View {
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }

    var body: some View {
        ZStack(alignment: .bottom) {
            if keyboard.isPresented {
                Color.black.opacity(0.48)
                    .ignoresSafeArea()
                    .onTapGesture { keyboard.dismiss() }
                    .transition(.opacity)

                AeroKeyboardPanel()
                    .padding(.horizontal, 10.0)
                    .padding(.bottom, 10.0)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: keyboard.isPresented)
    }
}

// MARK: - Panel

private struct AeroKeyboardPanel: View {
    private var keyboard: AeroKeyboardController { AeroKeyboardController.shared }
    @State private var shifted = true
    @State private var showingSymbols = false

    var body: some View {
        VStack(spacing: 12.0) {
            Capsule()
                .fill(Color.white.opacity(0.28))
                .frame(width: 42.0, height: 4.0)
                .padding(.top, 8.0)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(keyboard.title.uppercased())
                        .font(.system(size: 11.0, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(RestFitTheme.mint)
                    Text(previewText)
                        .font(RestFitTheme.manrope(size: 22.0, bold: true))
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
        .padding(14.0)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28.0, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28.0, style: .continuous)
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
            RestFitTheme.surface.opacity(0.94)
            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.clear,
                    RestFitTheme.mint.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: Letter QWERTY

    private var letterPad: some View {
        VStack(spacing: 8.0) {
            keyRow(["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"])
            keyRow(["A", "S", "D", "F", "G", "H", "J", "K", "L"])
            HStack(spacing: 6.0) {
                actionKey(shifted ? "⇧" : "⇧", wide: true) {
                    shifted.toggle()
                }
                keyRowInline(["Z", "X", "C", "V", "B", "N", "M"])
                actionKey("⌫", wide: true) {
                    keyboard.deleteBackward()
                }
            }
            HStack(spacing: 6.0) {
                actionKey("123", wide: true) { showingSymbols = true }
                if keyboard.mode == .email {
                    letterKey("@")
                    letterKey(".")
                }
                actionKey("space", flex: true) { keyboard.insert(" ") }
                actionKey("return", wide: true) { keyboard.finish() }
            }
        }
    }

    private var symbolsPad: some View {
        VStack(spacing: 8.0) {
            keyRow(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
            keyRow(["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""])
            keyRow([".", ",", "?", "!", "'", "#", "%", "*", "+", "="])
            HStack(spacing: 6.0) {
                actionKey("ABC", wide: true) { showingSymbols = false }
                actionKey("⌫", wide: true) { keyboard.deleteBackward() }
                actionKey("space", flex: true) { keyboard.insert(" ") }
                actionKey("return", wide: true) { keyboard.finish() }
            }
        }
    }

    private var numberPad: some View {
        VStack(spacing: 8.0) {
            keyRow(["1", "2", "3"])
            keyRow(["4", "5", "6"])
            keyRow(["7", "8", "9"])
            HStack(spacing: 6.0) {
                if keyboard.mode == .decimal {
                    letterKey(".")
                } else {
                    actionKey("C", wide: true) { keyboard.clear() }
                }
                letterKey("0")
                actionKey("⌫", wide: true) { keyboard.deleteBackward() }
            }
            actionKey("Done", flex: true) { keyboard.finish() }
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
        return Button {
            keyboard.insert(output)
            if shifted && isAlphaKey && keyboard.mode != .secure {
                shifted = false
            }
        } label: {
            Text(output)
                .font(RestFitTheme.manrope(size: 18.0, bold: true))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44.0)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1.0)
                )
        }
        .buttonStyle(.plain)
    }

    private func isAlphabeticKey(_ raw: String) -> Bool {
        guard raw.count == 1 else { return false }
        let lower = raw.lowercased()
        return "abcdefghijklmnopqrstuvwxyz".contains(lower)
    }

    private func actionKey(
        _ label: String,
        wide: Bool = false,
        flex: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let isPrimary = label == "return" || label == "Done"
        return Button(action: action) {
            Text(label)
                .font(.system(size: label.count > 2 ? 13.0 : 16.0, weight: .bold))
                .foregroundStyle(isPrimary ? RestFitTheme.canvas : .white)
                .frame(maxWidth: flex ? .infinity : (wide ? 56.0 : .infinity))
                .frame(height: 44.0)
                .background(isPrimary ? RestFitTheme.mint : Color.white.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: flex ? .infinity : nil)
    }
}
