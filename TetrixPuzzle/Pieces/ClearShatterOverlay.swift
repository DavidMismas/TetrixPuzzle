//
//  ClearShatterOverlay.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 23. 1. 26.
//

import SwiftUI

struct ClearShatterOverlay: View {
    let clearedCells: Set<Int>
    let boardRectGlobal: CGRect
    let boardCell: CGFloat
    let boardSize: Int
    let particleColor: Color
    let particlesPerCell: Int

    struct Particle: Identifiable {
        let id = UUID()
        let start: CGPoint
        let dx: CGFloat
        let dy: CGFloat
        let rot: Angle
        let dur: Double
        let size: CGFloat
    }

    @State private var particles: [Particle] = []
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            let overlayGlobal = proxy.frame(in: .global)

            ZStack {
                ForEach(particles) { p in
                    RoundedRectangle(cornerRadius: max(1, p.size * 0.18), style: .continuous)
                        .fill(particleColor)
                        .frame(width: p.size, height: p.size)
                        .position(p.start)
                        .rotationEffect(animate ? p.rot : .zero)
                        .offset(x: animate ? p.dx : 0, y: animate ? p.dy : 0)
                        .opacity(animate ? 0 : 1)
                        .animation(.easeOut(duration: p.dur), value: animate)
                }
            }
            .onAppear {
                particles = makeParticles(overlayGlobal: overlayGlobal)
                animate = false
                DispatchQueue.main.async { animate = true }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func makeParticles(overlayGlobal: CGRect) -> [Particle] {
        guard boardCell > 2 else { return [] }
        var out: [Particle] = []
        out.reserveCapacity(clearedCells.count * max(1, particlesPerCell))

        for idx in clearedCells {
            let row = idx / boardSize
            let col = idx % boardSize

            // cell center in GLOBAL
            let gx = boardRectGlobal.minX + (CGFloat(col) + 0.5) * boardCell
            let gy = boardRectGlobal.minY + (CGFloat(row) + 0.5) * boardCell

            // convert to LOCAL of overlay
            let lx = gx - overlayGlobal.minX
            let ly = gy - overlayGlobal.minY

            for _ in 0..<max(1, particlesPerCell) {
                let jitterX = CGFloat.random(in: -boardCell * 0.15 ... boardCell * 0.15)
                let jitterY = CGFloat.random(in: -boardCell * 0.15 ... boardCell * 0.15)

                let start = CGPoint(x: lx + jitterX, y: ly + jitterY)

                let dx = CGFloat.random(in: -boardCell * 1.2 ... boardCell * 1.2)
                let dy = CGFloat.random(in: boardCell * 2.8 ... boardCell * 6.0)

                let rot = Angle.degrees(Double.random(in: -140...140))
                let dur = Double.random(in: 0.45...0.75)
                let size = max(2, boardCell * CGFloat.random(in: 0.18...0.30))

                out.append(.init(start: start, dx: dx, dy: dy, rot: rot, dur: dur, size: size))
            }
        }

        return out
    }
}

