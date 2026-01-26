//
//  GameView.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 20. 1. 26.
//
// GameView.swift
import SwiftUI

struct GameView: View {
    let onHome: () -> Void

    @StateObject private var vm = GameViewModel()

    @State private var boardRectGlobal: CGRect = .zero
    @State private var rootRectGlobal: CGRect = .zero

    @State private var isDragging: Bool = false
    @State private var fingerGlobal: CGPoint = .zero
    @State private var lastHoverOrigin: (row: Int, col: Int)? = nil

    @State private var grabOffsetCells: CGSize = .zero
    @State private var didCaptureGrabOffset: Bool = false

    // ✅ shatter snapshot + token to force overlay rebuild every clear
    @State private var shatterCells: Set<Int> = []
    @State private var shatterToken: UUID = UUID()

    @AppStorage("tetrispuzzle.setting.rotateEnabled") private var rotateEnabled: Bool = true

    private let bottomGapPx: CGFloat = 140
    private let freeOffsetPx = CGSize(width: -2, height: -2)
    private let ghostSpacing: CGFloat = 1

    private let boardTopExtra: CGFloat = 24

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

    private var grabOffsetPx: CGSize {
        CGSize(width: grabOffsetCells.width * boardCell,
               height: grabOffsetCells.height * boardCell)
    }

    private var currentCardSize: CGSize {
        let maxPiece = maxPiecePixelSize(cellSize: currentCellSize, spacing: currentSpacing)
        return CGSize(width: maxPiece.width + currentCardPadding * 2,
                      height: maxPiece.height + currentCardPadding * 2)
    }

    private var nextCardSize: CGSize {
        let maxPiece = maxPiecePixelSize(cellSize: nextCellSize, spacing: nextSpacing)
        return CGSize(width: maxPiece.width + nextCardPadding * 2,
                      height: maxPiece.height + nextCardPadding * 2)
    }

    // MARK: - Theme (from WelcomeView)

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 0.92, green: 0.97, blue: 1.00),   // very light blue
                    Color(red: 0.96, green: 0.94, blue: 1.00)    // very light purple
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.cyan.opacity(0.18),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 460
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.purple.opacity(0.14),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 520
            )
            .ignoresSafeArea()
        }
    }

    private func glassCard(corner: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Color.white.opacity(0.86))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
    }

    private func primaryGradientButtonBackground(corner: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.95),
                        Color.purple.opacity(0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 10)
    }

    var body: some View {
        ZStack {
            background
            mainLayout
        }
        .overlay { dragOverlay }

        // ✅ Shatter overlay ABOVE board (and not clipped)
        .overlay {
            if !shatterCells.isEmpty,
               boardRectGlobal != .zero,
               boardCell > 2 {
                ClearShatterOverlay(
                    clearedCells: shatterCells,
                    boardRectGlobal: boardRectGlobal,
                    boardCell: boardCell,
                    boardSize: Board.size,
                    // light theme particle (still visible on white)
                    particleColor: Color.orange.opacity(0.80),
                    particlesPerCell: 8
                )
                .id(shatterToken)
                .allowsHitTesting(false)
                .zIndex(5000)
            }
        }

        .overlay(alignment: .top) {
            scoreHeader
                .padding(.top, 8)
                .zIndex(6000)
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
        .onAppear {
            if !vm.isStarted { vm.start() }
        }

        .onChange(of: vm.clearingCells) { _, newValue in
            guard !newValue.isEmpty else { return }
            shatterCells = newValue
            shatterToken = UUID()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                if shatterCells == newValue {
                    shatterCells = []
                }
            }
        }
    }

    // MARK: - Header

    private var scoreHeader: some View {
        HStack {
            Text("Score: \(vm.score)")
            Spacer()
            Text("Top: \(vm.topScore)")
                .opacity(0.7)
        }
        .font(.headline)
        .foregroundColor(Color.black.opacity(0.85))
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 10)
        .padding(.horizontal, 10)
    }

    // MARK: - Layout

    private var mainLayout: some View {
        VStack(spacing: 14) {

            BoardView(
                board: vm.board,
                hoverCells: vm.hoverCells,
                hoverIsValid: vm.hoverIsValid,
                helperCells: vm.helperCells,
                clearingCells: [], // disable old flash
                showGridHover: true,
                onCellTap: { row, col in vm.updateHover(row: row, col: col) }
            )
            .padding(.horizontal, 10)
            .padding(.top, boardTopExtra)
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
                                    .foregroundStyle(Color.black.opacity(0.90))

                                Text("Score: \(vm.score)")
                                    .font(.headline)
                                    .foregroundStyle(Color.black.opacity(0.82))

                                Text("Top: \(vm.topScore)")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.black.opacity(0.60))
                            }
                            .frame(width: cardWidth, height: cardHeight)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.92))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.black.opacity(0.10), lineWidth: 1)
                                    )
                            )
                            .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 12)
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
                    .foregroundStyle(Color.black.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 12) {
                    Spacer(minLength: 0)

                    ZStack(alignment: .center) {
                        PieceView(
                            piece: vm.currentPiece,
                            cellSize: currentCellSize,
                            spacing: currentSpacing,
                            color: GameColors.filled,
                            canvasSize: 4
                        )
                    }
                    .frame(width: currentCardSize.width, height: currentCardSize.height, alignment: .center)
                    .background(glassCard(corner: 14))
                    .contentShape(Rectangle())
                    .gesture(dragGestureGlobal)

                    Button { vm.rotateCurrentPieceCW() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "rotate.right")
                            Text("Rotate")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.black.opacity(0.80))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.black.opacity(0.10), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(!rotateEnabled || !vm.isStarted || vm.isGameOver || vm.isAnimatingClear || isDragging)
                    .opacity((rotateEnabled && vm.isStarted && !vm.isGameOver && !vm.isAnimatingClear && !isDragging) ? 1.0 : 0.35)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)

                Text("Next")
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)

                HStack(spacing: 12) {
                    ZStack(alignment: .center) {
                        PieceView(
                            piece: vm.next1,
                            cellSize: nextCellSize,
                            spacing: nextSpacing,
                            color: GameColors.filled,
                            canvasSize: 4
                        )
                    }
                    .frame(width: nextCardSize.width, height: nextCardSize.height, alignment: .center)
                    .background(glassCard(corner: 12))

                    ZStack(alignment: .center) {
                        PieceView(
                            piece: vm.next2,
                            cellSize: nextCellSize,
                            spacing: nextSpacing,
                            color: GameColors.filled,
                            canvasSize: 4
                        )
                    }
                    .frame(width: nextCardSize.width, height: nextCardSize.height, alignment: .center)
                    .background(glassCard(corner: 12))
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 12) {
                Button { onHome() } label: {
                    Image(systemName: "house.fill")
                        .font(.headline)
                        .foregroundStyle(Color.black.opacity(0.78))
                        .frame(width: 46, height: 44)
                        .background(glassCard(corner: 14))
                }
                .buttonStyle(.plain)
                .disabled(isDragging || vm.isAnimatingClear)
                .opacity((isDragging || vm.isAnimatingClear) ? 0.6 : 1.0)

                Button { vm.restart() } label: {
                    Text("Restart")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 180)
                        .padding(.vertical, 12)
                        .background(primaryGradientButtonBackground(corner: 16))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 6)
        }
        .padding(.top, 34)
        .padding(.horizontal, 18)
    }

    // MARK: - Drag overlay

    private var dragOverlay: some View {
        GeometryReader { proxy in
            let overlayGlobal = proxy.frame(in: .global)

            ZStack {
                if isDragging, boardCell > 2 {
                    let pieceSize = GhostPositioning.piecePixelSize(
                        piece: vm.currentPiece,
                        cellSize: boardCell,
                        spacing: ghostSpacing
                    )

                    let fingerLocal = CGPoint(
                        x: fingerGlobal.x - overlayGlobal.minX,
                        y: (fingerGlobal.y - bottomGapPx) - overlayGlobal.minY
                    )

                    let off = (lastHoverOrigin == nil) ? .zero : grabOffsetPx
                    let x = fingerLocal.x - off.width + freeOffsetPx.width
                    let y = fingerLocal.y - off.height + freeOffsetPx.height

                    PieceView(
                        piece: vm.currentPiece,
                        cellSize: boardCell,
                        spacing: ghostSpacing,
                        color: GameColors.filled,
                        canvasSize: 4
                    )
                    .frame(width: pieceSize.width, height: pieceSize.height)
                    .position(x: x, y: y)
                    .zIndex(9999)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // --- keep your existing ghost/drag math below (unchanged) ---

    private func pieceCellSpan(piece: Piece) -> (w: Int, h: Int) {
        let px = GhostPositioning.piecePixelSize(piece: piece, cellSize: boardCell, spacing: ghostSpacing)
        let denom = (boardCell + ghostSpacing)
        guard denom > 0 else { return (1, 1) }

        let w = max(1, Int(round((px.width + ghostSpacing) / denom)))
        let h = max(1, Int(round((px.height + ghostSpacing) / denom)))
        return (w, h)
    }

    private func nearestOriginForShadow(dropPointGlobal: CGPoint) -> (row: Int, col: Int)? {
        guard boardRectGlobal != .zero, boardCell > 2 else { return nil }

        let margin = boardCell * 0.75
        let expanded = boardRectGlobal.insetBy(dx: -margin, dy: -margin)
        guard expanded.contains(dropPointGlobal) else { return nil }

        let localX = dropPointGlobal.x - boardRectGlobal.minX
        let localY = dropPointGlobal.y - boardRectGlobal.minY

        let span = pieceCellSpan(piece: vm.currentPiece)
        let w = span.w
        let h = span.h

        let colF = (localX / boardCell) - CGFloat(w) / 2.0
        let rowF = (localY / boardCell) - CGFloat(h) / 2.0

        var col = Int(colF.rounded(.toNearestOrAwayFromZero))
        var row = Int(rowF.rounded(.toNearestOrAwayFromZero))

        col = max(0, min(Board.size - w, col))
        row = max(0, min(Board.size - h, row))

        return (row, col)
    }

    private var dragGestureGlobal: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                guard vm.isStarted, !vm.isGameOver, !vm.isAnimatingClear else { return }

                isDragging = true
                fingerGlobal = value.location

                guard boardRectGlobal != .zero, boardCell > 2 else {
                    vm.clearHover()
                    lastHoverOrigin = nil
                    return
                }

                let fingerAnchorGlobal = CGPoint(
                    x: fingerGlobal.x,
                    y: fingerGlobal.y - bottomGapPx
                )

                if !didCaptureGrabOffset {
                    if let origin0 = nearestOriginForShadow(dropPointGlobal: fingerAnchorGlobal) {
                        let pieceSize = GhostPositioning.piecePixelSize(
                            piece: vm.currentPiece,
                            cellSize: boardCell,
                            spacing: ghostSpacing
                        )

                        let cellGlobalX = boardRectGlobal.minX + CGFloat(origin0.col) * boardCell
                        let cellGlobalY = boardRectGlobal.minY + CGFloat(origin0.row) * boardCell

                        let stickyCenterGlobal = CGPoint(
                            x: cellGlobalX + pieceSize.width / 2,
                            y: cellGlobalY + pieceSize.height / 2
                        )

                        let dxCells = (fingerAnchorGlobal.x - stickyCenterGlobal.x) / boardCell
                        let dyCells = (fingerAnchorGlobal.y - stickyCenterGlobal.y) / boardCell

                        let maxC: CGFloat = 0.4
                        grabOffsetCells = CGSize(
                            width: max(-maxC, min(maxC, dxCells)),
                            height: max(-maxC, min(maxC, dyCells))
                        )

                        didCaptureGrabOffset = true
                    } else {
                        grabOffsetCells = .zero
                    }
                }

                let offPx = grabOffsetPx
                let dropPointForShadow = CGPoint(
                    x: fingerAnchorGlobal.x - offPx.width,
                    y: fingerAnchorGlobal.y - offPx.height
                )

                if let origin = nearestOriginForShadow(dropPointGlobal: dropPointForShadow) {
                    if lastHoverOrigin?.row != origin.row || lastHoverOrigin?.col != origin.col {
                        vm.updateHover(row: origin.row, col: origin.col)
                        lastHoverOrigin = origin
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

                    didCaptureGrabOffset = false
                    grabOffsetCells = .zero
                    return
                }

                isDragging = false
                lastHoverOrigin = nil

                if vm.hoverIsValid {
                    _ = vm.commitHover()
                } else {
                    vm.clearHover()
                }

                didCaptureGrabOffset = false
                grabOffsetCells = .zero
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
