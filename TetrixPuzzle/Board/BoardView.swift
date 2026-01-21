//
//  BoardView.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 20. 1. 26.
//

import SwiftUI

struct BoardView: View {
    let board: Board

    // hover preview
    let hoverCells: Set<Int>
    let hoverIsValid: Bool

    // DEBUG: optional callback (if nil, no tap handling)
    var onCellTap: ((Int, Int) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cellSize = side / CGFloat(Board.size)

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 0), count: Board.size),
                spacing: 0
            ) {
                ForEach(0..<Board.size * Board.size, id: \.self) { index in
                    let filled = board.cells[index]
                    let isHover = hoverCells.contains(index)

                    let row = index / Board.size
                    let col = index % Board.size

                    Rectangle()
                        .fill(filled ? Color.blue : Color.gray.opacity(0.12))
                        .overlay(
                            Rectangle().stroke(Color.black.opacity(0.35), lineWidth: 0.8)
                        )
                        .overlay(
                            Group {
                                if isHover {
                                    Rectangle()
                                        .fill((hoverIsValid ? Color.green : Color.red).opacity(0.35))
                                }
                            }
                        )
                        .frame(width: cellSize, height: cellSize)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCellTap?(row, col)
                        }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.black.opacity(0.6), lineWidth: 1.5)
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
