import SwiftUI

/// Tiny reaction game for rest between sets on the active workout screen.
struct WorkoutRestMiniGame: View {
    @State private var targetIndex = 4
    @State private var score = 0
    @State private var best = 0
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest game")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Tap the mint orb between sets")
                        .font(.caption2)
                        .foregroundStyle(RestFitTheme.muted)
                }
                Spacer(minLength: 8)
                Text("\(score)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RestFitTheme.mint)
                if best > 0 {
                    Text("best \(best)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RestFitTheme.faint)
                }
            }

            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { col in
                            orbCell(row * 3 + col)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(1150))
                if Task.isCancelled { break }
                jumpTarget()
            }
        }
    }

    private func orbCell(_ index: Int) -> some View {
        let isTarget = index == targetIndex
        return Button {
            tap(index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(RestFitTheme.canvas.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44.0)
                Circle()
                    .fill(isTarget ? RestFitTheme.mint : RestFitTheme.line.opacity(0.55))
                    .frame(width: isTarget ? (pulse ? 22.0 : 18.0) : 10.0, height: isTarget ? (pulse ? 22.0 : 18.0) : 10.0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isTarget ? "Mint orb" : "Empty cell")
    }

    private func tap(_ index: Int) {
        guard index == targetIndex else { return }
        score += 1
        if score > best { best = score }
        pulse.toggle()
        jumpTarget()
    }

    private func jumpTarget() {
        var next = Int.random(in: 0..<9)
        if next == targetIndex {
            next = (targetIndex + 1 + Int.random(in: 0..<8)) % 9
        }
        targetIndex = next
        pulse = false
    }
}
