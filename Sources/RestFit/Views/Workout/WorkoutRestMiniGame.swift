import SwiftUI

private enum RestMiniGameKind: String, CaseIterable {
    case ticTacToe
    case orbRush

    var title: String {
        switch self {
        case .ticTacToe: "Tic-tac-toe"
        case .orbRush: "Orb rush"
        }
    }

    var subtitle: String {
        switch self {
        case .ticTacToe: "You are X vs the AI"
        case .orbRush: "Tap the mint orb before it jumps"
        }
    }
}

/// Rest-time mini-games on the active workout screen.
struct WorkoutRestMiniGame: View {
    @State private var kind = RestMiniGameKind.allCases.randomElement() ?? .ticTacToe
    @State private var gameSeed = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest game")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(kind.subtitle)
                        .font(.caption2)
                        .foregroundStyle(RestFitTheme.muted)
                }
                Spacer(minLength: 8)
                Text(kind.title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(RestFitTheme.mint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RestFitTheme.mint.opacity(0.15))
                    .clipShape(Capsule())
                Button("Shuffle") {
                    pickRandomGame()
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RestFitTheme.mint)
                .buttonStyle(.plain)
            }

            Group {
                switch kind {
                case .ticTacToe:
                    RestTicTacToeView()
                        .id(gameSeed)
                case .orbRush:
                    RestOrbRushView()
                        .id(gameSeed)
                }
            }
        }
        .padding(12)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func pickRandomGame() {
        var next = RestMiniGameKind.allCases.randomElement() ?? .ticTacToe
        if RestMiniGameKind.allCases.count > 1 {
            while next == kind {
                next = RestMiniGameKind.allCases.randomElement() ?? .ticTacToe
            }
        }
        kind = next
        gameSeed += 1
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
