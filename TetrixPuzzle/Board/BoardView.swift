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

    // helper highlight (rows that will clear)
    let helperCells: Set<Int>

    // clearing flash animation cells
    let clearingCells: Set<Int>
    
    let showGridHover: Bool

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
                    let isHelper = helperCells.contains(index)
                    let isClearing = clearingCells.contains(index)

                    
                    
                 

                    RoundedRectangle(cornerRadius: max(2, cellSize * 0.09), style: .continuous)
                        .fill(filled ? GameColors.filled : GameColors.empty)
                        .overlay { if isHelper { Rectangle().fill(GameColors.helperRow) } }
                        .overlay { if showGridHover && isHover { Rectangle().fill(hoverIsValid ? GameColors.hoverValid : GameColors.hoverInvalid) } }
                        .overlay { if isClearing { Rectangle().fill(GameColors.clearFlash) } }
                        .frame(width: cellSize - 2, height: cellSize - 2)
                        .frame(width: cellSize, height: cellSize)
                        .scaleEffect(isClearing ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 0.14), value: isClearing)
                        .contentShape(Rectangle())
                        .onTapGesture { onCellTap?(index / Board.size, index % Board.size) }
                        .accessibilityLabel("Row \(index / Board.size + 1), column \(index % Board.size + 1), \(filled ? "filled" : "empty")")
                        .accessibilityAddTraits(.isButton)
                    
                        

                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(GameColors.border, lineWidth: 1)
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

