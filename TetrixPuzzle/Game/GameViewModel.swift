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

    // internal hover origin used for placement
    private var hoverOrigin: (row: Int, col: Int)? = nil

    init() {
        // load saved top score
        topScore = UserDefaults.standard.integer(forKey: topScoreKey)

        // NEW: ne startamo avtomatsko, da Start gumb ima smisel
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

        pieceBag.reset()

        currentPiece = pieceBag.nextPiece()
        next1 = pieceBag.nextPiece()
        next2 = pieceBag.nextPiece()

        clearHover()

        // if current cannot be placed anywhere right after start => game over
        isGameOver = !canPlaceAnywhere(piece: currentPiece)

        // top score stays (do not reset)
        persistTopScoreIfNeeded()
    }

    func advanceQueue() {
        currentPiece = next1
        next1 = next2
        next2 = pieceBag.nextPiece()
    }

    // MARK: - Hover

    func updateHover(row: Int, col: Int) {
        guard isStarted, !isGameOver else { return }
        hoverOrigin = (row, col)
        recalcHover()
    }

    func clearHover() {
        hoverOrigin = nil
        hoverCells = []
        hoverIsValid = false
    }

    func peekHoverOrigin() -> (row: Int, col: Int)? {
        hoverOrigin
    }

    // MARK: - Commit

    @discardableResult
    func commitHover() -> Bool {
        guard isStarted, !isGameOver else { return false }
        guard let origin = hoverOrigin else { return false }

        if canPlace(piece: currentPiece, originRow: origin.row, originCol: origin.col) {
            place(piece: currentPiece, originRow: origin.row, originCol: origin.col)

            let cleared = board.clearFullRows()
            if cleared > 0 {
                // 1 vrstica = 10
                score += cleared * 10
            }

            // update + persist top score
            persistTopScoreIfNeeded()

            advanceQueue()
            clearHover()

            // game over: current ne paše nikamor
            isGameOver = !canPlaceAnywhere(piece: currentPiece)

            // če se konča igra, še enkrat poskrbimo da je top score shranjen
            if isGameOver {
                persistTopScoreIfNeeded()
            }

            return true
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
