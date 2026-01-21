//
//  GameView.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 20. 1. 26.
//

import SwiftUI

struct GameView: View {
    @StateObject private var vm = GameViewModel()

    @State private var boardRectGlobal: CGRect = .zero
    @State private var rootRectGlobal: CGRect = .zero

    @State private var isDragging: Bool = false
    @State private var fingerGlobal: CGPoint = .zero

    private let bottomGapPx: CGFloat = 100

    private let ghostCellSize: CGFloat = 28
    private let ghostSpacing: CGFloat = 0

    private let currentCellSize: CGFloat = 24
    private let currentSpacing: CGFloat = 3
    private let currentCardPadding: CGFloat = 12

    private let nextCellSize: CGFloat = 10
    private let nextSpacing: CGFloat = 2
    private let nextCardPadding: CGFloat = 8

    private var boardSide: CGFloat { min(boardRectGlobal.width, boardRectGlobal.height) }
    private var boardCell: CGFloat {
        guard boardSide > 2 else { return 0 }
        return boardSide / CGFloat(Board.size)
    }

    private var currentCardSize: CGSize {
        let maxPiece = maxPiecePixelSize(cellSize: currentCellSize, spacing: currentSpacing)
        return CGSize(
            width: maxPiece.width + currentCardPadding * 2,
            height: maxPiece.height + currentCardPadding * 2
        )
    }

    private var nextCardSize: CGSize {
        let maxPiece = maxPiecePixelSize(cellSize: nextCellSize, spacing: nextSpacing)
        return CGSize(
            width: maxPiece.width + nextCardPadding * 2,
            height: maxPiece.height + nextCardPadding * 2
        )
    }

    var body: some View {
        ZStack {
            mainLayout
            ghostLayer
        }
        .padding()
        // SCORE/TOP pinned at top (won’t get pushed away by GeometryReader)
        .overlay(alignment: .top) {
            scoreHeader
                .padding(.top, 6)
                .zIndex(1000)
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: RootRectGlobalKey.self, value: proxy.frame(in: .global))
            }
        )
        .onPreferenceChange(RootRectGlobalKey.self) { rect in
            rootRectGlobal = rect
        }
    }

    // MARK: - Header pinned at top

    private var scoreHeader: some View {
        HStack {
            Text("Score: \(vm.score)")
            Spacer()
            Text("Top: \(vm.topScore)")
                .opacity(0.75)
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        // tiny background so it’s always readable but still minimal
        .background(Color.black.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 6)
    }

    // MARK: - Main layout

    private var mainLayout: some View {
        VStack(spacing: 14) {

            // (header removed from here!)

            BoardView(
                board: vm.board,
                hoverCells: vm.hoverCells,
                hoverIsValid: vm.hoverIsValid,
                onCellTap: { row, col in
                    vm.updateHover(row: row, col: col)
                }
            )
            .padding(.horizontal, 10)
            .overlay(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: BoardRectGlobalKey.self, value: proxy.frame(in: .global))
                }
            )
            .onPreferenceChange(BoardRectGlobalKey.self) { rect in
                boardRectGlobal = rect
            }
            .overlay {
                if vm.isGameOver {
                    ZStack {
                        Color.black.opacity(0.45)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(spacing: 10) {
                            Text("Game Over")
                                .font(.title.bold())
                                .foregroundStyle(.white)

                            Text("Score: \(vm.score)")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.95))

                            Text("Top: \(vm.topScore)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding()
                    }
                    .padding(.horizontal, 12)
                }
            }

            VStack(spacing: 10) {
                Text("Current")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)

                ZStack {
                    PieceView(piece: vm.currentPiece, cellSize: currentCellSize, spacing: currentSpacing)
                        .opacity(isDragging ? 0.25 : 1.0)
                }
                .frame(width: currentCardSize.width, height: currentCardSize.height)
                .background(Color.gray.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.black.opacity(0.35), lineWidth: 1)
                )
                .cornerRadius(14)
                .contentShape(Rectangle())
                .gesture(dragGestureGlobal)

                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)

                HStack(spacing: 12) {
                    ZStack {
                        PieceView(piece: vm.next1, cellSize: nextCellSize, spacing: nextSpacing)
                    }
                    .frame(width: nextCardSize.width, height: nextCardSize.height)
                    .background(Color.gray.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.30), lineWidth: 1)
                    )
                    .cornerRadius(12)

                    ZStack {
                        PieceView(piece: vm.next2, cellSize: nextCellSize, spacing: nextSpacing)
                    }
                    .frame(width: nextCardSize.width, height: nextCardSize.height)
                    .background(Color.gray.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.30), lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 12) {
                Button {
                    vm.start()
                } label: {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isStarted && !vm.isGameOver)

                Button {
                    vm.restart()
                } label: {
                    Text("Restart")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
        // give some breathing room so pinned header doesn’t overlap board too much
        .padding(.top, 34)
    }

    // MARK: - Ghost (visual only)

    private var ghostLayer: some View {
        Group {
            if isDragging, rootRectGlobal != .zero {
                let pieceH = GhostPositioning.piecePixelSize(
                    piece: vm.currentPiece,
                    cellSize: ghostCellSize,
                    spacing: ghostSpacing
                ).height

                let ghostCenterGlobal = CGPoint(
                    x: fingerGlobal.x,
                    y: fingerGlobal.y - bottomGapPx - (pieceH / 2)
                )

                let ghostCenterLocal = CGPoint(
                    x: ghostCenterGlobal.x - rootRectGlobal.minX,
                    y: ghostCenterGlobal.y - rootRectGlobal.minY
                )

                PieceView(piece: vm.currentPiece, cellSize: ghostCellSize, spacing: ghostSpacing)
                    .position(ghostCenterLocal)
                    .zIndex(100)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Drag Gesture (GLOBAL, hover from dropPoint)

    private var dragGestureGlobal: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                guard vm.isStarted, !vm.isGameOver else { return }

                isDragging = true
                fingerGlobal = value.location

                guard boardRectGlobal != .zero, boardCell > 2 else {
                    vm.clearHover()
                    return
                }

                let dropPoint = CGPoint(x: fingerGlobal.x, y: fingerGlobal.y - bottomGapPx)

                if let origin = GhostPositioning.originCell(
                    dropPoint: dropPoint,
                    boardRect: boardRectGlobal,
                    boardCell: boardCell,
                    piece: vm.currentPiece
                ) {
                    vm.updateHover(row: origin.row, col: origin.col)
                } else {
                    vm.clearHover()
                }
            }
            .onEnded { _ in
                guard vm.isStarted, !vm.isGameOver else {
                    isDragging = false
                    vm.clearHover()
                    return
                }

                isDragging = false

                if vm.hoverIsValid {
                    _ = vm.commitHover()
                } else {
                    vm.clearHover()
                }
            }
    }

    // MARK: - Sizing helper (max of all oriented shapes)

    private func maxPiecePixelSize(cellSize: CGFloat, spacing: CGFloat) -> CGSize {
        var maxW: CGFloat = 0
        var maxH: CGFloat = 0

        for base in BaseShape.allCases {
            for rot in base.allowedRotations {
                let piece = Piece.make(base: base, rotation: rot)
                let size = GhostPositioning.piecePixelSize(piece: piece, cellSize: cellSize, spacing: spacing)
                maxW = max(maxW, size.width)
                maxH = max(maxH, size.height)
            }
        }
        return CGSize(width: maxW, height: maxH)
    }
}

// MARK: - Preference keys

private struct RootRectGlobalKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

private struct BoardRectGlobalKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}
