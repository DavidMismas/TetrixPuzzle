//
//  Piece+Generator.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 20. 1. 26.
//

import Foundation

// MARK: - Base Shapes

enum BaseShape: CaseIterable {
    case I, O, T, L, J, S, Z
}

struct OrientedShape {
    let base: BaseShape
    let rotation: Int   // 0,1,2,3 (odvisno od oblike)
}

extension BaseShape {

    /// Canonical (nerotirana) oblika
    var baseCells: [(Int, Int)] {
        switch self {
        case .I:
            return [(0,0),(0,1),(0,2),(0,3)]
        case .O:
            return [(0,0),(0,1),(1,0),(1,1)]
        case .T:
            return [(0,1),(1,0),(1,1),(1,2)]

        // L: stolpec 3 + “noga” desno spodaj
        case .L:
            return [(0,0),(1,0),(2,0),(2,1)]

        // J: stolpec 3 + “noga” levo spodaj (mirror od L)
        case .J:
            return [(0,1),(1,1),(2,1),(2,0)]

        // S
        case .S:
            return [(0,1),(0,2),(1,0),(1,1)]

        // Z (mirror od S)
        case .Z:
            return [(0,0),(0,1),(1,1),(1,2)]
        }
    }

    /// Dovoljene rotacije (unikatne rotacije na obliko)
    var allowedRotations: [Int] {
        switch self {
        case .O:
            return [0]
        case .I, .S, .Z:
            return [0, 1]
        case .T, .L, .J:
            return [0, 1, 2, 3]
        }
    }
}

extension Piece {

    static func make(base: BaseShape, rotation: Int) -> Piece {
        let baseCells = base.baseCells
        let rotated = rotate(cells: baseCells, times: rotation)
        let normalized = normalize(cells: rotated)
        return Piece(cells: normalized)
    }

    private static func rotate(cells: [(Int, Int)], times: Int) -> [(Int, Int)] {
        var result = cells

        for _ in 0..<times {
            let maxRow = result.map { $0.0 }.max() ?? 0
            result = result.map { (r, c) in
                (c, maxRow - r)
            }
        }

        return result
    }

    private static func normalize(cells: [(Int, Int)]) -> [(Int, Int)] {
        let minRow = cells.map { $0.0 }.min() ?? 0
        let minCol = cells.map { $0.1 }.min() ?? 0

        return cells.map { (r, c) in
            (r - minRow, c - minCol)
        }
    }
}

// MARK: - Seeded RNG (stable shuffle)

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0xDEADBEEF : seed
    }

    mutating func next() -> UInt64 {
        // xorshift64*
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2685821657736338717
    }
}

// MARK: - Piece Bag (13/19-shape orientation bag)

final class PieceBag {

    private var bag: [OrientedShape] = []
    private var rng: SeededGenerator

    init() {
        // seed: mikrosekunde + malo dodatnega šuma
        let t = UInt64(Date().timeIntervalSince1970 * 1_000_000)
        rng = SeededGenerator(seed: t ^ UInt64.random(in: 1...UInt64.max))
        refill()
    }

    func reset() {
        let t = UInt64(Date().timeIntervalSince1970 * 1_000_000)
        rng = SeededGenerator(seed: t ^ UInt64.random(in: 1...UInt64.max))
        refill()
    }

    func nextPiece() -> Piece {
        if bag.isEmpty { refill() }
        let oriented = bag.removeFirst()
        return Piece.make(base: oriented.base, rotation: oriented.rotation)
    }

    private func refill() {
        bag = []
        for base in BaseShape.allCases {
            for rot in base.allowedRotations {
                bag.append(OrientedShape(base: base, rotation: rot))
            }
        }
        bag.shuffle(using: &rng)

        print("NEW BAG:", bag.map { "\($0.base)-\($0.rotation)" }.joined(separator: ", "))
    }
}
