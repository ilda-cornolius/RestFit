import SwiftUI

struct ToolRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RestFitTheme.faint)
            }
            .padding(16)
            .background(RestFitTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(RestFitTheme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct BackHeader: View {
    let title: String
    var backTitle: String = "More"
    let action: () -> Void

    var body: some View {
        HStack {
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text(backTitle)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RestFitTheme.mint)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 52, height: 1)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}
