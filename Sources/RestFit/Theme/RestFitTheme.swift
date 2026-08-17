import SwiftUI

enum RestFitTheme {
    static let canvas = Color(red: 0.043, green: 0.047, blue: 0.118)
    static let surface = Color(red: 0.071, green: 0.075, blue: 0.192)
    static let card = Color(red: 0.09, green: 0.095, blue: 0.22)
    static let line = Color(red: 0.149, green: 0.161, blue: 0.388)
    static let faint = Color(red: 0.337, green: 0.357, blue: 0.522)
    static let muted = Color(red: 0.45, green: 0.47, blue: 0.62)
    static let mint = Color(red: 0.18, green: 0.898, blue: 0.616)
    static let coral = Color(red: 1.0, green: 0.463, blue: 0.463)

    static func manrope(size: CGFloat, bold: Bool) -> Font {
        .custom(bold ? "Manrope-Bold" : "Manrope-SemiBold", size: size)
    }
}

struct SurfaceCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(24)
            .background(RestFitTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(RestFitTheme.line, lineWidth: 1)
            )
    }
}

struct MintButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(RestFitTheme.canvas)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(RestFitTheme.mint)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct TrendBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
