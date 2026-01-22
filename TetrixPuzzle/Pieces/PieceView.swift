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
    var color: Color = GameColors.filled

    /// Use for Current/Next cards: 4 makes pieces visually centered consistently.
    /// Leave nil for ghost/other uses if you want original tight bounding box.
    var canvasSize: Int? = nil

    private var normalizedCells: [(row: Int, col: Int)] {
        let minRow = piece.cells.map(\.row).min() ?? 0
        let minCol = piece.cells.map(\.col).min() ?? 0
        return piece.cells.map { (row: $0.row - minRow, col: $0.col - minCol) }
    }

    private var dims: (rows: Int, cols: Int) {
        let maxRow = normalizedCells.map(\.row).max() ?? 0
        let maxCol = normalizedCells.map(\.col).max() ?? 0
        return (rows: maxRow + 1, cols: maxCol + 1)
    }

    private func pixelSize(rows: Int, cols: Int) -> CGSize {
        let w = CGFloat(cols) * cellSize + CGFloat(max(0, cols - 1)) * spacing
        let h = CGFloat(rows) * cellSize + CGFloat(max(0, rows - 1)) * spacing
        return CGSize(width: w, height: h)
    }

    var body: some View {
        let rows = dims.rows
        let cols = dims.cols

        // Inner content (tight bounding box)
        let content = ZStack(alignment: .topLeading) {
            ForEach(Array(normalizedCells.enumerated()), id: \.offset) { _, cell in
                RoundedRectangle(cornerRadius: max(2, cellSize * 0.1), style: .continuous)
                    .fill(color)
                    .frame(width: cellSize, height: cellSize)
                    .shadow(color: .black.opacity(0.1), radius: 0.2, x: 0, y: 1)
                    .offset(
                        x: CGFloat(cell.col) * (cellSize + spacing),
                        y: CGFloat(cell.row) * (cellSize + spacing)
                    )

            }
        }
        .frame(
            width: pixelSize(rows: rows, cols: cols).width,
            height: pixelSize(rows: rows, cols: cols).height,
            alignment: .topLeading
        )

        // If no canvas => return tight content (as before)
        guard let n = canvasSize else {
            return AnyView(content)
        }

        // Canvas pixel size (NxN)
        let canvas = pixelSize(rows: n, cols: n)
        let contentSize = pixelSize(rows: rows, cols: cols)

        // Fractional centering (THIS is the fix)
        let dx = (canvas.width - contentSize.width) / 2
        let dy = (canvas.height - contentSize.height) / 2

        return AnyView(
            ZStack(alignment: .topLeading) {
                content
                    .offset(x: dx, y: dy)
            }
            .frame(width: canvas.width, height: canvas.height, alignment: .topLeading)
        )
    }
}
