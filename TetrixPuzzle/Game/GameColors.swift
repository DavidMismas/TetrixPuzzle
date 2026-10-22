//
//  GameColors.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 21. 1. 26.
//


import SwiftUI

enum GameColors {
    static let background = Color(red: 0.96, green: 0.955, blue: 0.935)
    static let surface = Color(red: 0.995, green: 0.99, blue: 0.975)
    static let border = Color(red: 0.83, green: 0.84, blue: 0.81)
    static let mutedText = Color(red: 0.40, green: 0.45, blue: 0.44)
    static let filled = Color(red: 0.16, green: 0.43, blue: 0.43)
    static let empty = Color(red: 0.90, green: 0.92, blue: 0.89)
    static let gridStroke = background
    static let hoverValid = Color(red: 0.28, green: 0.64, blue: 0.52).opacity(0.66)
    static let hoverInvalid = Color(red: 0.75, green: 0.32, blue: 0.30).opacity(0.64)
    static let helperRow = Color(red: 0.92, green: 0.68, blue: 0.35).opacity(0.78)
    static let clearFlash = Color.white.opacity(0.85)
}
