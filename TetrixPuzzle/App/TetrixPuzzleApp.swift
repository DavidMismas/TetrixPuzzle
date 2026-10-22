//
//  TetrixPuzzleApp.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 20. 1. 26.
//

import SwiftUI

@main
struct TetrixPuzzleApp: App {
    @State private var started: Bool = false
    @State private var startFresh: Bool = false
    @StateObject private var entitlements = Entitlements()

    var body: some Scene {
        WindowGroup {
            Group {
                if started {
                    GameView(startFresh: startFresh, onHome: {
                        started = false
                    })
                } else {
                    WelcomeView { fresh in
                        startFresh = fresh
                        started = true
                    }
                }
            }
            .environmentObject(entitlements)
            .preferredColorScheme(.light)
            .onAppear {
                entitlements.start()
            }
        }
    }
}
