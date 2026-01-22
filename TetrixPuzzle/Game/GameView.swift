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
    @State private var smoothedFingerGlobal: CGPoint = .zero
    @State private var lastHoverOrigin: (row: Int, col: Int)? = nil
    @State private var lastFingerTimestamp: TimeInterval = 0
    @State private var lastFingerPoint: CGPoint = .zero

    private let bottomGapPx: CGFloat = 100
    private let ghostFingerOffsetY: CGFloat = 60
    private let ghostFingerOffsetX: CGFloat = 40

    private let ghostCellSize: CGFloat = 28
    private let ghostSpacing: CGFloat = 0

    private let currentCellSize: CGFloat = 24
    private let currentSpacing: CGFloat = 1
    private let currentCardPadding: CGFloat = 12

    private let nextCellSize: CGFloat = 10
    private let nextSpacing: CGFloat = 1
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

    // Convert a global finger point into fractional board coordinates (colF, rowF)
    private func fractionalBoardCoordinate(from globalPoint: CGPoint) -> CGPoint? {
        guard boardRectGlobal != .zero, boardCell > 2 else { return nil }
        let localX = globalPoint.x - boardRectGlobal.minX - ghostFingerOffsetX
        let localY = globalPoint.y - boardRectGlobal.minY - bottomGapPx - ghostFingerOffsetY
        let colF = localX / boardCell
        let rowF = localY / boardCell
        return CGPoint(x: colF, y: rowF)
    }

    var body: some View {
        ZStack {
            mainLayout
            ghostLayer
        }
        .padding()
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
        .background(Color.black.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 6)
    }

    private var mainLayout: some View {
        VStack(spacing: 14) {

            BoardView(
                board: vm.board,
                hoverCells: vm.hoverCells,
                hoverIsValid: vm.hoverIsValid,
                helperCells: vm.helperCells,
                clearingCells: vm.clearingCells,
                showGridHover: true,
                onCellTap: { row, col in vm.updateHover(row: row, col: col) }
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
                        GeometryReader { geo in
                            let side = min(geo.size.width, geo.size.height)
                            let cardWidth = side * 0.78
                            let cardHeight = side * 0.48

                            VStack(spacing: 12) {
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
                            .frame(width: cardWidth, height: cardHeight)
                            .background(Color.black.opacity(0.2))
                            .background(.ultraThinMaterial.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 10)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .scaleEffect(vm.isGameOver ? 1.0 : 0.85)
                            .opacity(vm.isGameOver ? 1.0 : 0.0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.isGameOver)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.28), value: vm.isGameOver)

            VStack(spacing: 10) {
                Text("Current")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)

                // ✅ SAME AS YOUR WORKING VERSION: ZStack + fixed frame => centers PieceView
                ZStack(alignment: .center) {
                    PieceView(
                        piece: vm.currentPiece,
                        cellSize: currentCellSize,
                        spacing: currentSpacing,
                        color: GameColors.filled, canvasSize: 4
                    )
                }
                .frame(width: currentCardSize.width, height: currentCardSize.height, alignment: .center)
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
                    ZStack(alignment: .center) {
                        PieceView(piece: vm.next1, cellSize: nextCellSize, spacing: nextSpacing, color: GameColors.filled, canvasSize: 4)
                    }
                    .frame(width: nextCardSize.width, height: nextCardSize.height, alignment: .center)
                    .background(Color.gray.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.30), lineWidth: 1)
                    )
                    .cornerRadius(12)

                    ZStack(alignment: .center) {
                        PieceView(piece: vm.next2, cellSize: nextCellSize, spacing: nextSpacing, color: GameColors.filled, canvasSize: 4)
                    }
                    .frame(width: nextCardSize.width, height: nextCardSize.height, alignment: .center)
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
                Button { vm.start() } label: {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isStarted && !vm.isGameOver)

                Button { vm.restart() } label: {
                    Text("Restart")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
        .padding(.top, 34)
    }

    // MARK: - Ghost (visual only)

    private var ghostLayer: some View {
        Group {
            if isDragging, rootRectGlobal != .zero, boardCell > 0 {
                

                if let frac = fractionalBoardCoordinate(from: fingerGlobal) {
                    let pixelX = frac.x * boardCell + boardRectGlobal.minX
                    let pixelY = frac.y * boardCell + boardRectGlobal.minY + bottomGapPx
                    let ghostCenterGlobal = CGPoint(
                        x: pixelX,
                        y: pixelY
                    )
                    let ghostCenterLocal = CGPoint(
                        x: ghostCenterGlobal.x - rootRectGlobal.minX,
                        y: ghostCenterGlobal.y - rootRectGlobal.minY
                    )

                    PieceView(
                        piece: vm.currentPiece,
                        cellSize: ghostCellSize,
                        spacing: ghostSpacing,
                        color: (vm.hoverIsValid ? Color.green : Color.red)
                    )
                    .scaleEffect(1.05)
                    .position(ghostCenterLocal)
                    .zIndex(100)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Drag Gesture

    private var dragGestureGlobal: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                guard vm.isStarted, !vm.isGameOver, !vm.isAnimatingClear else { return }

                let raw = value.location
                fingerGlobal = raw
                isDragging = true

                guard let frac = fractionalBoardCoordinate(from: raw) else {
                    vm.clearHover()
                    lastHoverOrigin = nil
                    return
                }

                // Candidate origin based on fractional position
                let candCol = Int(floor(frac.x))
                let candRow = Int(floor(frac.y))

                if candRow >= 0 && candRow < Board.size && candCol >= 0 && candCol < Board.size {
                    if lastHoverOrigin?.row != candRow || lastHoverOrigin?.col != candCol {
                        vm.updateHover(row: candRow, col: candCol)
                        lastHoverOrigin = (row: candRow, col: candCol)
                    }
                } else {
                    vm.clearHover()
                    lastHoverOrigin = nil
                }
            }
            .onEnded { _ in
                guard vm.isStarted, !vm.isGameOver, !vm.isAnimatingClear else {
                    isDragging = false
                    lastHoverOrigin = nil
                    vm.clearHover()
                    return
                }

                lastHoverOrigin = nil
                lastFingerTimestamp = 0
                lastFingerPoint = .zero
                isDragging = false

                if vm.hoverIsValid {
                    _ = vm.commitHover()
                } else {
                    vm.clearHover()
                    lastHoverOrigin = nil
                }
            }
    }

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

private struct RootRectGlobalKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

private struct BoardRectGlobalKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

