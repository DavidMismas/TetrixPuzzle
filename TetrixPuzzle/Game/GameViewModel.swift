//
//  GameViewModel.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 20. 1. 26.
//

import Foundation
import Combine
import SwiftUI
import UIKit
import AudioToolbox

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

    @Published private(set) var topScore: Int = 0
    private let topScoreKey = "tetrispuzzle.topScore"

    @Published var hoverCells: Set<Int> = []
    @Published var hoverIsValid: Bool = false

    @Published var helperCells: Set<Int> = []
    @Published var clearingCells: Set<Int> = []

    @Published private(set) var isAnimatingClear: Bool = false

    private var hoverOrigin: (row: Int, col: Int)? = nil

    @AppStorage("tetrispuzzle.setting.rotateEnabled") private var rotateEnabled: Bool = true
    @AppStorage("tetrispuzzle.setting.rotateClockwise") private var rotateClockwise: Bool = true
    @AppStorage("tetrispuzzle.setting.clearColumnsEnabled") private var clearColumnsEnabled: Bool = true
    @AppStorage("tetrispuzzle.setting.soundsEnabled") private var soundsEnabled: Bool = true
    @AppStorage("tetrispuzzle.setting.hapticsEnabled") private var hapticsEnabled: Bool = true

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

        isGameOver = !canPlaceAnywhereConsideringRotation(piece: currentPiece)
        persistTopScoreIfNeeded()
    }

    func advanceQueue() {
        currentPiece = next1
        next1 = next2
        next2 = pieceBag.nextPiece()
    }

    // MARK: - Rotation

    func rotateCurrentPieceCW() {
        guard rotateEnabled else { return }
        guard isStarted, !isGameOver, !isAnimatingClear else { return }

        currentPiece = rotateClockwise ? currentPiece.rotatedCW() : currentPiece.rotatedCCW()
        recalcHover()

        hapticImpactLight()
        soundClick()
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

    func peekHoverOrigin() -> (row: Int, col: Int)? { hoverOrigin }

    // MARK: - Commit

    @discardableResult
    func commitHover() -> Bool {
        guard isStarted, !isGameOver, !isAnimatingClear else { return false }
        guard let origin = hoverOrigin else { return false }

        if canPlace(piece: currentPiece, originRow: origin.row, originCol: origin.col) {

            place(piece: currentPiece, originRow: origin.row, originCol: origin.col)

            let fullRows = currentFullRows()
            let fullCols = clearColumnsEnabled ? currentFullColumns() : []
            let anyClear = !fullRows.isEmpty || !fullCols.isEmpty

            if anyClear {
                isAnimatingClear = true
                clearingCells = indicesForRows(fullRows).union(indicesForColumns(fullCols))
                helperCells = []

                soundClear()
                hapticSuccess()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [weak self] in
                    guard let self else { return }

                    let rowsCleared = self.clearFullRows(fullRows)
                    let colsCleared = self.clearColumnsEnabled ? self.clearFullColumns(fullCols) : 0

                    let clearedTotal = rowsCleared + colsCleared
                    if clearedTotal > 0 { self.score += clearedTotal * 10 }

                    self.persistTopScoreIfNeeded()

                    self.clearingCells = []
                    self.isAnimatingClear = false

                    self.advanceQueue()
                    self.clearHover()

                    self.isGameOver = !self.canPlaceAnywhereConsideringRotation(piece: self.currentPiece)
                    if self.isGameOver { self.persistTopScoreIfNeeded() }
                }

                return true
            } else {
                soundPlace()
                hapticImpactMedium()

                persistTopScoreIfNeeded()
                advanceQueue()
                clearHover()

                isGameOver = !canPlaceAnywhereConsideringRotation(piece: currentPiece)
                if isGameOver { persistTopScoreIfNeeded() }

                return true
            }
        } else {
            soundError()
            hapticError()
            clearHover()
            return false
        }
    }

    private func persistTopScoreIfNeeded() {
        if score > topScore {
            topScore = score
            UserDefaults.standard.set(topScore, forKey: topScoreKey)
        }
    }

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

        helperCells = hoverIsValid ? helperCellsForPotentialClear(withHoverIndices: indices) : []
    }

    private func helperCellsForPotentialClear(withHoverIndices hover: Set<Int>) -> Set<Int> {
        var lines = Set<Int>()

        for row in 0..<Board.size {
            var full = true
            for col in 0..<Board.size {
                let idx = board.index(row: row, col: col)
                if !(board.cells[idx] || hover.contains(idx)) { full = false; break }
            }
            if full {
                for col in 0..<Board.size { lines.insert(board.index(row: row, col: col)) }
            }
        }

        if clearColumnsEnabled {
            for col in 0..<Board.size {
                var full = true
                for row in 0..<Board.size {
                    let idx = board.index(row: row, col: col)
                    if !(board.cells[idx] || hover.contains(idx)) { full = false; break }
                }
                if full {
                    for row in 0..<Board.size { lines.insert(board.index(row: row, col: col)) }
                }
            }
        }

        return lines
    }

    private func currentFullRows() -> [Int] {
        var rows: [Int] = []
        for row in 0..<Board.size {
            let full = (0..<Board.size).allSatisfy { col in board.isOccupied(row: row, col: col) }
            if full { rows.append(row) }
        }
        return rows
    }

    private func currentFullColumns() -> [Int] {
        var cols: [Int] = []
        for col in 0..<Board.size {
            let full = (0..<Board.size).allSatisfy { row in board.isOccupied(row: row, col: col) }
            if full { cols.append(col) }
        }
        return cols
    }

    private func indicesForRows(_ rows: [Int]) -> Set<Int> {
        var set: Set<Int> = []
        for row in rows {
            for col in 0..<Board.size { set.insert(board.index(row: row, col: col)) }
        }
        return set
    }

    private func indicesForColumns(_ cols: [Int]) -> Set<Int> {
        var set: Set<Int> = []
        for col in cols {
            for row in 0..<Board.size { set.insert(board.index(row: row, col: col)) }
        }
        return set
    }

    private func clearFullRows(_ rows: [Int]) -> Int {
        guard !rows.isEmpty else { return 0 }
        for row in rows {
            for col in 0..<Board.size {
                board.setOccupied(row: row, col: col, value: false)
            }
        }
        return rows.count
    }

    private func clearFullColumns(_ cols: [Int]) -> Int {
        guard !cols.isEmpty else { return 0 }
        for col in cols {
            for row in 0..<Board.size {
                board.setOccupied(row: row, col: col, value: false)
            }
        }
        return cols.count
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

    // ✅ KEY FIX (game over when rotate ON)
    private func canPlaceAnywhereConsideringRotation(piece: Piece) -> Bool {
        if !rotateEnabled { return canPlaceAnywhere(piece: piece) }
        for p in piece.uniqueRotationsCW() {
            if canPlaceAnywhere(piece: p) { return true }
        }
        return false
    }

    // MARK: - Feedback

    private func soundClick() { guard soundsEnabled else { return }; AudioServicesPlaySystemSound(1104) }
    private func soundPlace() { guard soundsEnabled else { return }; AudioServicesPlaySystemSound(1105) }
    private func soundClear() { guard soundsEnabled else { return }; AudioServicesPlaySystemSound(1111) }
    private func soundError() { guard soundsEnabled else { return }; AudioServicesPlaySystemSound(1053) }

    private func hapticImpactLight() { guard hapticsEnabled else { return }; UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    private func hapticImpactMedium() { guard hapticsEnabled else { return }; UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    private func hapticSuccess() { guard hapticsEnabled else { return }; UINotificationFeedbackGenerator().notificationOccurred(.success) }
    private func hapticError() { guard hapticsEnabled else { return }; UINotificationFeedbackGenerator().notificationOccurred(.error) }
}

// MARK: - Piece rotation helpers (model untouched)

private extension Piece {

    func rotatedCW() -> Piece {
        let maxRow = cells.map(\.row).max() ?? 0
        let rotated = cells.map { (row: $0.col, col: maxRow - $0.row) }

        let minRow = rotated.map(\.row).min() ?? 0
        let minCol = rotated.map(\.col).min() ?? 0
        let normalized = rotated.map { (row: $0.row - minRow, col: $0.col - minCol) }

        return Piece(cells: normalized)
    }

    func rotatedCCW() -> Piece {
        let maxCol = cells.map(\.col).max() ?? 0
        let rotated = cells.map { (row: maxCol - $0.col, col: $0.row) }

        let minRow = rotated.map(\.row).min() ?? 0
        let minCol = rotated.map(\.col).min() ?? 0
        let normalized = rotated.map { (row: $0.row - minRow, col: $0.col - minCol) }

        return Piece(cells: normalized)
    }

    func normalizedKey() -> String {
        let minRow = cells.map(\.row).min() ?? 0
        let minCol = cells.map(\.col).min() ?? 0
        let norm = cells.map { (r: $0.row - minRow, c: $0.col - minCol) }
            .sorted { ($0.r, $0.c) < ($1.r, $1.c) }
        return norm.map { "\($0.r),\($0.c)" }.joined(separator: "|")
    }

    func uniqueRotationsCW() -> [Piece] {
        var out: [Piece] = []
        var seen: Set<String> = []
        var p: Piece = self

        for _ in 0..<4 {
            let key = p.normalizedKey()
            if !seen.contains(key) {
                seen.insert(key)
                out.append(p)
            }
            p = p.rotatedCW()
        }
        return out
    }
}
