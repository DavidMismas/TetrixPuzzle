//
//  PieceView.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 20. 1. 26.
//

import SwiftUI

struct PieceView: View {
    let piece: Piece
    let cellSize: CGFloat
    let spacing: CGFloat

    var body: some View {
        let cells = normalize(piece.cells)
        let bounds = boundingBox(cells)

        LazyVGrid(
            columns: Array(
                repeating: GridItem(.fixed(cellSize), spacing: spacing),
                count: bounds.width
            ),
            spacing: spacing
        ) {
            ForEach(0..<bounds.width * bounds.height, id: \.self) { index in
                let row = index / bounds.width
                let col = index % bounds.width

                if cells.contains(where: { $0.row == row && $0.col == col }) {
                    RoundedRectangle(cornerRadius: max(3, cellSize * 0.18))
                        .fill(Color.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: max(3, cellSize * 0.18))
                                .stroke(Color.black.opacity(0.35), lineWidth: max(1, cellSize * 0.06))
                        )
                        .frame(width: cellSize, height: cellSize)
                } else {
                    Color.clear
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
    }

    // MARK: - Helpers

    private func normalize(_ cells: [(row: Int, col: Int)]) -> [(row: Int, col: Int)] {
        let minRow = cells.map(\.row).min() ?? 0
        let minCol = cells.map(\.col).min() ?? 0
        return cells.map { (row: $0.row - minRow, col: $0.col - minCol) }
    }

    private func boundingBox(_ cells: [(row: Int, col: Int)]) -> (width: Int, height: Int) {
        let maxRow = cells.map(\.row).max() ?? 0
        let maxCol = cells.map(\.col).max() ?? 0
        return (width: maxCol + 1, height: maxRow + 1)
    }
}
