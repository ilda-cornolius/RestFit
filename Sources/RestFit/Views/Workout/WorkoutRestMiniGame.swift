import SwiftUI

private enum RestMiniGameKind: String, CaseIterable {
    case ticTacToe
    case orbRush
    case studyClicker

    var title: String {
        switch self {
        case .ticTacToe: "Tic-tac-toe"
        case .orbRush: "Orb rush"
        case .studyClicker: "Study RPG"
        }
    }

    var subtitle: String {
        switch self {
        case .ticTacToe: "You are X vs the AI"
        case .orbRush: "Tap the mint orb before it jumps"
        case .studyClicker: "Tap notes to level up your sprite"
        }
    }
}

/// Rest-time mini-games on the active workout screen.
/// Pass an increasing `restKick` when a set is completed to start the rest timer + shuffle countdown.
/// Keep lift rows OUT of `middle` — nesting them here made every set tap rebuild the whole list.
struct WorkoutRestMiniGame<Middle: View>: View {
    /// Parent increments this after each completed set to restart rest + game pick.
    var restKick: Int = 0
    @ViewBuilder var middle: () -> Middle

    @State private var kind = RestMiniGameKind.allCases.randomElement() ?? .ticTacToe
    @State private var gameSeed = 0
    @State private var restSecondsRemaining: Int = 0
    @State private var isResting = false
    @State private var isShuffling = false
    @State private var shuffleCountdown = 0
    @State private var shuffleFlashTitle = "…"
    @State private var restTickToken = 0
    @State private var shuffleToken = 0

    /// Fixed rest between working sets.
    private let restDurationSeconds = 180

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isResting {
                restTimerSection
                    .padding(12)
                    .background(RestFitTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            middle()

            if isResting || isShuffling {
                gameSection
                    .padding(12)
                    .background(RestFitTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .onChange(of: restKick) { _, newValue in
            guard newValue > 0 else { return }
            beginRestAfterSet()
        }
    }

    // MARK: - Rest timer

    private var restTimerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Rest · 3:00")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Button("Skip") {
                    endRest()
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RestFitTheme.mint)
                .buttonStyle(.plain)
            }

            Text(restClockLabel)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(restSecondsRemaining == 0 ? RestFitTheme.coral : RestFitTheme.mint)
                .frame(maxWidth: .infinity)

            Text(restSecondsRemaining == 0 ? "Rest done — next set" : "Resting between sets…")
                .font(.caption2)
                .foregroundStyle(RestFitTheme.muted)
                .frame(maxWidth: .infinity)
        }
        .task(id: restTickToken) {
            guard isResting else { return }
            while !Task.isCancelled, isResting, restSecondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { break }
                await MainActor.run {
                    guard isResting, restSecondsRemaining > 0 else { return }
                    restSecondsRemaining -= 1
                }
            }
            guard !Task.isCancelled, isResting, restSecondsRemaining == 0 else { return }
            try? await Task.sleep(for: .seconds(2))
            if Task.isCancelled { return }
            await MainActor.run {
                if isResting, restSecondsRemaining == 0 {
                    endRest()
                }
            }
        }
    }

    private var restClockLabel: String {
        let minutes = restSecondsRemaining / 60
        let seconds = restSecondsRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Game + shuffle countdown

    private var gameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest game")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(isShuffling ? "Picking a game…" : kind.subtitle)
                        .font(.caption2)
                        .foregroundStyle(RestFitTheme.muted)
                }
                Spacer(minLength: 8)
                if isShuffling {
                    Text("\(shuffleCountdown)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RestFitTheme.mint)
                        .frame(minWidth: 28)
                } else {
                    Text(kind.title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(RestFitTheme.mint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RestFitTheme.mint.opacity(0.15))
                        .clipShape(Capsule())
                    Button("Shuffle") {
                        startShuffleCountdown()
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RestFitTheme.mint)
                    .buttonStyle(.plain)
                    .disabled(isShuffling)
                }
            }

            if isShuffling {
                shuffleCountdownCard
            } else {
                Group {
                    switch kind {
                    case .ticTacToe:
                        RestTicTacToeView()
                            .id(gameSeed)
                    case .orbRush:
                        RestOrbRushView()
                            .id(gameSeed)
                    case .studyClicker:
                        RestStudyClickerView()
                            .id(gameSeed)
                    }
                }
            }
        }
        .task(id: shuffleToken) {
            guard isShuffling else { return }
            await runShuffleCountdown()
        }
    }

    private var shuffleCountdownCard: some View {
        VStack(spacing: 12) {
            Text("\(shuffleCountdown)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(RestFitTheme.mint)
                .frame(maxWidth: .infinity)

            Text(shuffleFlashTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(RestFitTheme.canvas.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(shuffleCountdown > 0 ? "Randomizing…" : "Let’s play!")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RestFitTheme.muted)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private func beginRestAfterSet() {
        isResting = true
        restSecondsRemaining = restDurationSeconds
        restTickToken += 1
        startShuffleCountdown()
    }

    private func endRest() {
        isResting = false
        restSecondsRemaining = 0
        restTickToken += 1
    }

    private func startShuffleCountdown() {
        isShuffling = true
        shuffleCountdown = 3
        shuffleFlashTitle = RestMiniGameKind.allCases.randomElement()?.title ?? "…"
        shuffleToken += 1
    }

    @MainActor
    private func runShuffleCountdown() async {
        // Light countdown — avoid flashing titles every 200ms (that lagged set taps on Fold).
        for second in stride(from: 3, through: 1, by: -1) {
            guard !Task.isCancelled, isShuffling else { return }
            shuffleCountdown = second
            shuffleFlashTitle = RestMiniGameKind.allCases.randomElement()?.title ?? "…"
            try? await Task.sleep(for: .seconds(1))
        }

        guard !Task.isCancelled, isShuffling else { return }

        var next = RestMiniGameKind.allCases.randomElement() ?? .ticTacToe
        if RestMiniGameKind.allCases.count > 1 {
            while next == kind {
                next = RestMiniGameKind.allCases.randomElement() ?? .ticTacToe
            }
        }
        kind = next
        shuffleFlashTitle = next.title
        shuffleCountdown = 0
        gameSeed += 1
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        isShuffling = false
    }
}

// MARK: - Tic-tac-toe vs AI

private enum TicTacToeMark: Equatable {
    case x
    case o
}

private enum TicTacToeOutcome: Equatable {
    case playing
    case playerWon
    case aiWon
    case draw
}

private struct RestTicTacToeView: View {
    @State private var board: [TicTacToeMark?] = Array(repeating: nil, count: 9)
    @State private var outcome: TicTacToeOutcome = .playing
    @State private var aiThinking = false

    private let winLines: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                Spacer()
                if outcome != .playing {
                    Button("Rematch") {
                        resetBoard()
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RestFitTheme.mint)
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { col in
                            ticTacToeCell(row * 3 + col)
                        }
                    }
                }
            }
        }
    }

    private var statusText: String {
        if aiThinking { return "AI is thinking..." }
        switch outcome {
        case .playing: return "Your turn — place X"
        case .playerWon: return "You win!"
        case .aiWon: return "AI wins this one"
        case .draw: return "Draw — good game"
        }
    }

    private var statusColor: Color {
        switch outcome {
        case .playing: return RestFitTheme.muted
        case .playerWon: return RestFitTheme.mint
        case .aiWon: return RestFitTheme.coral
        case .draw: return RestFitTheme.faint
        }
    }

    private func ticTacToeCell(_ index: Int) -> some View {
        let mark = board[index]
        let enabled = outcome == .playing && !aiThinking && mark == nil

        return Button {
            playerMove(at: index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(RestFitTheme.canvas.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52.0)
                if let mark {
                    Text(mark == .x ? "X" : "O")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(mark == .x ? RestFitTheme.mint : RestFitTheme.coral)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(cellAccessibility(index))
    }

    private func cellAccessibility(_ index: Int) -> String {
        switch board[index] {
        case .x: return "X"
        case .o: return "O"
        case nil: return "Empty square \(index + 1)"
        }
    }

    private func playerMove(at index: Int) {
        guard outcome == .playing, !aiThinking, board[index] == nil else { return }
        board[index] = .x
        refreshOutcome()
        guard outcome == .playing else { return }

        aiThinking = true
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                aiMove()
                aiThinking = false
            }
        }
    }

    private func aiMove() {
        guard outcome == .playing else { return }
        let move = bestAIMove(for: board, mark: .o, opponent: .x)
        guard board[move] == nil else { return }
        board[move] = .o
        refreshOutcome()
    }

    private func refreshOutcome() {
        if let winner = winningMark(in: board) {
            outcome = winner == .x ? .playerWon : .aiWon
            return
        }
        if board.allSatisfy({ $0 != nil }) {
            outcome = .draw
        }
    }

    private func resetBoard() {
        board = Array(repeating: nil, count: 9)
        outcome = .playing
        aiThinking = false
    }

    private func winningMark(in cells: [TicTacToeMark?]) -> TicTacToeMark? {
        for line in winLines {
            guard let first = cells[line[0]],
                  cells[line[1]] == first,
                  cells[line[2]] == first else { continue }
            return first
        }
        return nil
    }

    private func bestAIMove(for cells: [TicTacToeMark?], mark: TicTacToeMark, opponent: TicTacToeMark) -> Int {
        var bestScore = Int.min
        var bestMove = availableMoves(in: cells).first ?? 4

        for move in availableMoves(in: cells) {
            var next = cells
            next[move] = mark
            let score = minimax(board: next, ai: mark, human: opponent, isAIMax: false)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        return bestMove
    }

    private func minimax(
        board cells: [TicTacToeMark?],
        ai: TicTacToeMark,
        human: TicTacToeMark,
        isAIMax: Bool
    ) -> Int {
        if let winner = winningMark(in: cells) {
            if winner == ai { return 10 }
            if winner == human { return -10 }
        }
        if cells.allSatisfy({ $0 != nil }) { return 0 }

        let moves = availableMoves(in: cells)
        if isAIMax {
            var best = Int.min
            for move in moves {
                var next = cells
                next[move] = ai
                best = max(best, minimax(board: next, ai: ai, human: human, isAIMax: false))
            }
            return best
        }

        var best = Int.max
        for move in moves {
            var next = cells
            next[move] = human
            best = min(best, minimax(board: next, ai: ai, human: human, isAIMax: true))
        }
        return best
    }

    private func availableMoves(in cells: [TicTacToeMark?]) -> [Int] {
        cells.enumerated().compactMap { index, mark in
            mark == nil ? index : nil
        }
    }
}

// MARK: - Orb rush

private struct RestOrbRushView: View {
    @State private var targetIndex = 4
    @State private var score = 0
    @State private var best = 0
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Streak \(score)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RestFitTheme.muted)
                Spacer()
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
        .onAppear {
            randomizeTarget()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(1150))
                if Task.isCancelled { break }
                randomizeTarget()
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
                    .frame(
                        width: isTarget ? (pulse ? 22.0 : 18.0) : 10.0,
                        height: isTarget ? (pulse ? 22.0 : 18.0) : 10.0
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func tap(_ index: Int) {
        guard index == targetIndex else {
            score = 0
            pulse = false
            return
        }
        score += 1
        if score > best { best = score }
        pulse.toggle()
        randomizeTarget()
    }

    private func randomizeTarget() {
        var next = Int.random(in: 0..<9)
        if next == targetIndex {
            next = (targetIndex + 1 + Int.random(in: 0..<8)) % 9
        }
        targetIndex = next
        pulse = false
    }
}

// MARK: - Study notes RPG clicker

private struct RestStudyClickerView: View {
    @State private var notes = 0
    @State private var level = 1
    @State private var xp = 0
    @State private var bounce = false
    @State private var frame = 0

    private var xpToNext: Int { level * 8 }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Lv \(level)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RestFitTheme.mint)
                Spacer()
                Text("\(notes) notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RestFitTheme.muted)
            }

            Button {
                tapStudy()
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(RestFitTheme.canvas.opacity(0.65))
                            .frame(height: 96)
                        Text(spriteGlyph)
                            .font(.system(size: bounce ? 44.0 : 36.0, weight: .bold))
                            .foregroundStyle(RestFitTheme.mint)
                            .scaleEffect(bounce ? 1.12 : 1.0)
                            .animation(.easeOut(duration: 0.12), value: bounce)
                    }
                    Text("Tap to study")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RestFitTheme.faint)
                }
            }
            .buttonStyle(.plain)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RestFitTheme.line.opacity(0.7))
                    Capsule()
                        .fill(RestFitTheme.mint)
                        .frame(width: max(8.0, geo.size.width * (Double(xp) / Double(max(1, xpToNext)))))
                }
            }
            .frame(height: 8)

            Text("XP \(xp)/\(xpToNext)")
                .font(.caption2)
                .foregroundStyle(RestFitTheme.faint)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(420))
                if Task.isCancelled { break }
                frame = (frame + 1) % 4
            }
        }
    }

    private var spriteGlyph: String {
        switch frame {
        case 0: return "•"
        case 1: return "◆"
        case 2: return "★"
        default: return "▲"
        }
    }

    private func tapStudy() {
        notes += 1
        xp += 1
        bounce.toggle()
        if xp >= xpToNext {
            xp = 0
            level += 1
        }
    }
}
