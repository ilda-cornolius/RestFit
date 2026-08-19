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

struct BarTrendChart: View {
    let values: [Double]
    let labels: [String]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let width = Double(geometry.size.width)
            let height = Double(geometry.size.height)
            let maxValue = max(values.max() ?? 0.0, 1.0)
            let slotCount = max(values.count, 1)
            let slotWidth = width / Double(slotCount)
            let barWidth = max(slotWidth * 0.55, 4.0)

            ZStack(alignment: .bottomLeading) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    let barHeight = maxValue > 0 ? (value / maxValue) * height : 0.0
                    let x = slotWidth * Double(index) + (slotWidth - barWidth) / 2.0
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(value > 0 ? color : RestFitTheme.line.opacity(0.35))
                        .frame(width: barWidth, height: max(barHeight, value > 0 ? 4.0 : 2.0))
                        .offset(x: x, y: height - max(barHeight, value > 0 ? 4.0 : 2.0))
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

struct StackedMinutesChart: View {
    let cardioValues: [Double]
    let workoutValues: [Double]
    let labels: [String]

    var body: some View {
        GeometryReader { geometry in
            let width = Double(geometry.size.width)
            let height = Double(geometry.size.height)
            let totals = zip(cardioValues, workoutValues).map { $0 + $1 }
            let maxValue = max(totals.max() ?? 0.0, 1.0)
            let slotCount = max(labels.count, 1)
            let slotWidth = width / Double(slotCount)
            let barWidth = max(slotWidth * 0.55, 4.0)

            ZStack(alignment: .bottomLeading) {
                ForEach(Array(labels.enumerated()), id: \.offset) { index, _ in
                    let cardio = index < cardioValues.count ? cardioValues[index] : 0.0
                    let workout = index < workoutValues.count ? workoutValues[index] : 0.0
                    let total = cardio + workout
                    let totalHeight = total > 0 ? (total / maxValue) * height : 0.0
                    let cardioHeight = total > 0 ? (cardio / total) * totalHeight : 0.0
                    let workoutHeight = total > 0 ? (workout / total) * totalHeight : 0.0
                    let x = slotWidth * Double(index) + (slotWidth - barWidth) / 2.0

                    if total > 0 {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(RestFitTheme.coral)
                            .frame(width: barWidth, height: max(cardioHeight, cardio > 0 ? 2.0 : 0.0))
                            .offset(x: x, y: height - totalHeight)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(RestFitTheme.mint)
                            .frame(width: barWidth, height: max(workoutHeight, workout > 0 ? 2.0 : 0.0))
                            .offset(x: x, y: height - workoutHeight)
                    } else {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(RestFitTheme.line.opacity(0.35))
                            .frame(width: barWidth, height: 2.0)
                            .offset(x: x, y: height - 2.0)
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

struct DailyTypeStripChart: View {
    let points: [WorkoutDayChartPoint]

    var body: some View {
        GeometryReader { geometry in
            let width = Double(geometry.size.width)
            let height = Double(geometry.size.height)
            let slotCount = max(points.count, 1)
            let slotWidth = width / Double(slotCount)
            let barWidth = max(slotWidth * 0.55, 4.0)

            ZStack(alignment: .bottomLeading) {
                ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                    let x = slotWidth * Double(index) + (slotWidth - barWidth) / 2.0
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color(for: point.dayType))
                        .frame(width: barWidth, height: point.dayType == .none ? 2.0 : height * 0.82)
                        .offset(x: x, y: height - (point.dayType == .none ? 2.0 : height * 0.82))
                }

                HStack {
                    ForEach(points) { point in
                        Text(point.label)
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

    private func color(for type: WorkoutDayChartPoint.WorkoutChartDayType) -> Color {
        switch type {
        case .rest: RestFitTheme.faint
        case .cardio: RestFitTheme.coral
        case .workout: RestFitTheme.mint
        case .none: RestFitTheme.line.opacity(0.35)
        }
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
