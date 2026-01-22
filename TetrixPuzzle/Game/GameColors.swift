//
//  GameColors.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 21. 1. 26.
//


import SwiftUI

enum GameColors {
    // Filled cells + pieces (dark blue-violet)
    static let filled = Color.indigo


    // Empty grid cell background (light mode friendly)
    static let empty = Color.blue.opacity(0.1)

    // Grid stroke
    static let gridStroke = Color.white.opacity(0.9)

    // Hover overlays (semi transparent so you can still see occupancy)
    static let hoverValid = Color.indigo.opacity(0.60)
    static let hoverInvalid = Color.pink.opacity(0.60)

    // Helper highlight (row will clear) — also semi transparent
    static let helperRow = Color.yellow.opacity(0.95)

    // Clear animation flash
    static let clearFlash = Color.white.opacity(0.80)
}
