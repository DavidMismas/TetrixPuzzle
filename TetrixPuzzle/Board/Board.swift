//
//  Board.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 20. 1. 26.
//

import Foundation

struct Board {
    static let size = 10

    // 10x10 = 100 celic
    private(set) var cells: [Bool] = Array(repeating: false, count: size * size)

    func index(row: Int, col: Int) -> Int {
        row * Self.size + col
    }

    func isInside(row: Int, col: Int) -> Bool {
        row >= 0 && row < Self.size && col >= 0 && col < Self.size
    }

    func isOccupied(row: Int, col: Int) -> Bool {
        cells[index(row: row, col: col)]
    }

    mutating func setOccupied(row: Int, col: Int, value: Bool) {
        cells[index(row: row, col: col)] = value
    }

    mutating func clearFullRows() -> Int {
        var cleared = 0

        for row in 0..<Self.size {
            let full = (0..<Self.size).allSatisfy { col in
                isOccupied(row: row, col: col)
            }

            if full {
                cleared += 1
                for col in 0..<Self.size {
                    setOccupied(row: row, col: col, value: false)
                }
            }
        }

        return cleared
    }
}

