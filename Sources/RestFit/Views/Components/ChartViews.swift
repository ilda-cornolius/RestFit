import SwiftUI

struct LineTrendChart: View {
    let values: [Double]
    let labels: [String]
    let color: Color
    let fillOpacity: Double

    var body: some View {
        GeometryReader { geometry in
            let width = Double(geometry.size.width)
            let height = Double(geometry.size.height)
            let minValue = (values.min() ?? 0.0) * 0.95
            let maxValue = (values.max() ?? 1.0) * 1.05
            let range = max(maxValue - minValue, 1.0)
            let count = max(values.count - 1, 1)

            ZStack(alignment: .bottomLeading) {
                if values.count >= 2 {
                    Path { path in
                        for (index, value) in values.enumerated() {
                            let x = width * Double(index) / Double(count)
                            let y = height - ((value - minValue) / range) * height
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    Path { path in
                        for (index, value) in values.enumerated() {
                            let x = width * Double(index) / Double(count)
                            let y = height - ((value - minValue) / range) * height
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: height))
                                path.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.closeSubpath()
                    }
                    .fill(color.opacity(fillOpacity))

                    ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                        let x = width * Double(index) / Double(count)
                        let y = height - ((value - minValue) / range) * height
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(RestFitTheme.canvas, lineWidth: 2))
                            .position(x: x, y: y)
                    }
                }

                HStack {
                    ForEach(labels, id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(RestFitTheme.faint)
                            .frame(maxWidth: .infinity)
                    }
                }
                .offset(y: height + 4.0)
            }
        }
        .padding(.bottom, 18)
    }
}

struct FastingRingView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(RestFitTheme.line, lineWidth: 10)
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(RestFitTheme.mint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100.0))%")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

struct GuidanceCard: View {
    let guidance: WellnessGuidance

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: guidance.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(RestFitTheme.mint)
                .frame(width: 36, height: 36)
                .background(RestFitTheme.mint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(guidance.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(guidance.message)
                    .font(.caption)
                    .foregroundStyle(RestFitTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RestFitTheme.line, lineWidth: 1)
        )
    }
}
