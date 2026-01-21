//
//  GhostPositioning.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 21. 1. 26.
//

import SwiftUI

struct GhostPositioning {

    /// Point where we "aim" the placement on the board.
    /// We do NOT use the piece view geometry for hover math.
    /// We simply take the finger point and shift it UP by bottomGapPx.
    static func dropPoint(finger: CGPoint, bottomGapPx: CGFloat) -> CGPoint {
        CGPoint(x: finger.x, y: finger.y - bottomGapPx)
    }

    /// Ghost center for drawing (bottom of piece sits above the finger by bottomGapPx).
    /// This is purely visual.
    static func ghostCenter(
        finger: CGPoint,
        piece: Piece,
        renderCellSize: CGFloat,
        renderSpacing: CGFloat,
        bottomGapPx: CGFloat
    ) -> CGPoint {
        let pieceH = piecePixelSize(piece: piece, cellSize: renderCellSize, spacing: renderSpacing).height
        let centerY = finger.y - bottomGapPx - (pieceH / 2)
        return CGPoint(x: finger.x, y: centerY)
    }

    /// Compute origin cell from a drop point (in the same coordinate space as boardRect).
    /// origin cell = cell under the drop point.
    static func originCell(
        dropPoint: CGPoint,
        boardRect: CGRect,
        boardCell: CGFloat,
        piece: Piece
    ) -> (row: Int, col: Int)? {
        guard boardCell > 1, boardRect != .zero else { return nil }

        let x = dropPoint.x - boardRect.minX
        let y = dropPoint.y - boardRect.minY

        let targetCol = Int(floor(x / boardCell))
        let targetRow = Int(floor(y / boardCell))

        // Anchor inside the piece (in normalized coords)
        let anchor = pieceAnchorCell(piece: piece)

        // Origin = target - anchor
        let originRow = targetRow - anchor.row
        let originCol = targetCol - anchor.col

        guard originRow >= 0, originRow < Board.size,
              originCol >= 0, originCol < Board.size else { return nil }

        return (originRow, originCol)
    }

    /// Choose an anchor cell: bottom row of the piece, middle-ish column.
    /// This keeps X stable (no “drift” left/right across shapes).
    private static func pieceAnchorCell(piece: Piece) -> (row: Int, col: Int) {
        let cells = normalize(piece.cells)

        let maxRow = cells.map(\.row).max() ?? 0
        let bottomCells = cells.filter { $0.row == maxRow }.sorted { $0.col < $1.col }

        // Pick the median bottom cell (stable “under finger” feel)
        let mid = bottomCells.count / 2
        return bottomCells[mid]
    }


    // MARK: - Piece pixel size (for visuals only)

    static func piecePixelSize(piece: Piece, cellSize: CGFloat, spacing: CGFloat) -> CGSize {
        let cells = normalize(piece.cells)
        let (w, h) = boundingBox(cells)

        let width = CGFloat(w) * cellSize + CGFloat(max(0, w - 1)) * spacing
        let height = CGFloat(h) * cellSize + CGFloat(max(0, h - 1)) * spacing

        return CGSize(width: width, height: height)
    }

    private static func normalize(_ cells: [(row: Int, col: Int)]) -> [(row: Int, col: Int)] {
        let minRow = cells.map(\.row).min() ?? 0
        let minCol = cells.map(\.col).min() ?? 0
        return cells.map { (row: $0.row - minRow, col: $0.col - minCol) }
    }

    private static func boundingBox(_ cells: [(row: Int, col: Int)]) -> (width: Int, height: Int) {
        let maxRow = cells.map(\.row).max() ?? 0
        let maxCol = cells.map(\.col).max() ?? 0
        return (width: maxCol + 1, height: maxRow + 1)
    }
}
