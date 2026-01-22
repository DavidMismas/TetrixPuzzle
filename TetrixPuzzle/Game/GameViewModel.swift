//
//  GameViewModel.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 20. 1. 26.
//

import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {

    private let pieceBag = PieceBag()

    @Published var board = Board()

    @Published var currentPiece: Piece = Piece(cells: [(0,0),(0,1),(0,2),(0,3)])
    @Published var next1: Piece = Piece(cells: [(0,0),(0,1),(1,0),(1,1)])
    @Published var next2: Piece = Piece(cells: [(0,1),(1,0),(1,1),(1,2)])

    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var isStarted: Bool = false

    // TOP SCORE (persisted)
    @Published private(set) var topScore: Int = 0
    private let topScoreKey = "tetrispuzzle.topScore"

    // hover preview (board overlay)
    @Published var hoverCells: Set<Int> = []
    @Published var hoverIsValid: Bool = false

    // NEW: helper highlight — cells in rows that would clear if we drop now
    @Published var helperCells: Set<Int> = []

    // NEW: clearing flash animation cells
    @Published var clearingCells: Set<Int> = []

    // NEW: block interaction during clear animation
    @Published private(set) var isAnimatingClear: Bool = false

    // internal hover origin used for placement
    private var hoverOrigin: (row: Int, col: Int)? = nil

    init() {
        topScore = UserDefaults.standard.integer(forKey: topScoreKey)

        pieceBag.reset()
        currentPiece = pieceBag.nextPiece()
        next1 = pieceBag.nextPiece()
        next2 = pieceBag.nextPiece()

        clearHover()
        score = 0
        isGameOver = false
        isStarted = false
    }

    // MARK: - Start / Restart

    func start() {
        guard !isStarted || isGameOver else { return }
        isStarted = true
        startNewGameInternal()
    }

    func restart() {
        isStarted = true
        startNewGameInternal()
    }

    private func startNewGameInternal() {
        board = Board()
        score = 0
        isGameOver = false
        isAnimatingClear = false
        clearingCells = []
        helperCells = []

        pieceBag.reset()
        currentPiece = pieceBag.nextPiece()
        next1 = pieceBag.nextPiece()
        next2 = pieceBag.nextPiece()

        clearHover()

        isGameOver = !canPlaceAnywhere(piece: currentPiece)
        persistTopScoreIfNeeded()
    }

    func advanceQueue() {
        currentPiece = next1
        next1 = next2
        next2 = pieceBag.nextPiece()
    }

    // MARK: - Hover

    func updateHover(row: Int, col: Int) {
        guard isStarted, !isGameOver, !isAnimatingClear else { return }
        hoverOrigin = (row, col)
        recalcHover()
    }

    func clearHover() {
        hoverOrigin = nil
        hoverCells = []
        hoverIsValid = false
        helperCells = []
    }

    func peekHoverOrigin() -> (row: Int, col: Int)? {
        hoverOrigin
    }

    // MARK: - Commit

    @discardableResult
    func commitHover() -> Bool {
        guard isStarted, !isGameOver, !isAnimatingClear else { return false }
        guard let origin = hoverOrigin else { return false }

        if canPlace(piece: currentPiece, originRow: origin.row, originCol: origin.col) {

            // Place immediately (so we can detect full rows exactly)
            place(piece: currentPiece, originRow: origin.row, originCol: origin.col)

            // Determine full rows after placement (for animation)
            let fullRows = currentFullRows()
            if !fullRows.isEmpty {
                isAnimatingClear = true
                clearingCells = indicesForRows(fullRows)

                // keep helper off during clear
                helperCells = []

                // Flash duration then clear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [weak self] in
                    guard let self else { return }

                    let cleared = self.board.clearFullRows()
                    if cleared > 0 {
                        // 1 vrstica = 10
                        self.score += cleared * 10
                    }

                    self.persistTopScoreIfNeeded()

                    self.clearingCells = []
                    self.isAnimatingClear = false

                    self.advanceQueue()
                    self.clearHover()

                    self.isGameOver = !self.canPlaceAnywhere(piece: self.currentPiece)
                    if self.isGameOver {
                        self.persistTopScoreIfNeeded()
                    }
                }

                return true
            } else {
                // no rows cleared -> proceed normally
                persistTopScoreIfNeeded()
                advanceQueue()
                clearHover()

                isGameOver = !canPlaceAnywhere(piece: currentPiece)
                if isGameOver { persistTopScoreIfNeeded() }

                return true
            }
        } else {
            clearHover()
            return false
        }
    }

    // MARK: - Top score persistence

    private func persistTopScoreIfNeeded() {
        if score > topScore {
            topScore = score
            UserDefaults.standard.set(topScore, forKey: topScoreKey)
        }
    }

    // MARK: - Internals

    private func recalcHover() {
        guard let origin = hoverOrigin else {
            hoverCells = []
            hoverIsValid = false
            helperCells = []
            return
        }

        let absCells = absoluteCells(of: currentPiece, originRow: origin.row, originCol: origin.col)

        var indices = Set<Int>()
        var valid = true

        for (r, c) in absCells {
            guard board.isInside(row: r, col: c) else { valid = false; continue }
            let idx = board.index(row: r, col: c)
            indices.insert(idx)
            if board.cells[idx] { valid = false }
        }

        hoverCells = indices
        hoverIsValid = valid && absCells.allSatisfy { board.isInside(row: $0.0, col: $0.1) }

        // Helper: if hover valid, show which rows would clear (yellow)
        if hoverIsValid {
            helperCells = helperCellsForPotentialClear(withHoverIndices: indices)
        } else {
            helperCells = []
        }
    }

    private func helperCellsForPotentialClear(withHoverIndices hover: Set<Int>) -> Set<Int> {
        var rowsToHighlight: [Int] = []

        for row in 0..<Board.size {
            var full = true
            for col in 0..<Board.size {
                let idx = board.index(row: row, col: col)
                let occupiedAfter = board.cells[idx] || hover.contains(idx)
                if !occupiedAfter { full = false; break }
            }
            if full { rowsToHighlight.append(row) }
        }

        guard !rowsToHighlight.isEmpty else { return [] }
        return indicesForRows(rowsToHighlight)
    }

    private func currentFullRows() -> [Int] {
        var rows: [Int] = []
        for row in 0..<Board.size {
            let full = (0..<Board.size).allSatisfy { col in
                board.isOccupied(row: row, col: col)
            }
            if full { rows.append(row) }
        }
        return rows
    }

    private func indicesForRows(_ rows: [Int]) -> Set<Int> {
        var set: Set<Int> = []
        for row in rows {
            for col in 0..<Board.size {
                set.insert(board.index(row: row, col: col))
            }
        }
        return set
    }

    private func absoluteCells(of piece: Piece, originRow: Int, originCol: Int) -> [(Int, Int)] {
        piece.cells.map { (originRow + $0.row, originCol + $0.col) }
    }

    private func canPlace(piece: Piece, originRow: Int, originCol: Int) -> Bool {
        for (r, c) in absoluteCells(of: piece, originRow: originRow, originCol: originCol) {
            if !board.isInside(row: r, col: c) { return false }
            if board.isOccupied(row: r, col: c) { return false }
        }
        return true
    }

    private func place(piece: Piece, originRow: Int, originCol: Int) {
        for (r, c) in absoluteCells(of: piece, originRow: originRow, originCol: originCol) {
            board.setOccupied(row: r, col: c, value: true)
        }
    }

    private func canPlaceAnywhere(piece: Piece) -> Bool {
        for row in 0..<Board.size {
            for col in 0..<Board.size {
                if canPlace(piece: piece, originRow: row, originCol: col) { return true }
            }
        }
        return false
    }
}

