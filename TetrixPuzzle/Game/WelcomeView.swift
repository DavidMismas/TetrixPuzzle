//
//  WelcomeView.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 23. 1. 26.
//

import SwiftUI

// MARK: - Custom Toggle Style (light-friendly)

private struct GlowToggleStyle: ToggleStyle {
    var onColor: Color = .blue
    var offColor: Color = Color.black.opacity(0.12)

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer(minLength: 12)

            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule(style: .continuous)
                    .fill(configuration.isOn ? onColor.opacity(0.22) : offColor)
                    .frame(width: 56, height: 32)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.black.opacity(configuration.isOn ? 0.14 : 0.10), lineWidth: 1)
                    )

                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .padding(3)
                    .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
            }
            .animation(.spring(response: 0.22, dampingFraction: 0.9), value: configuration.isOn)
            .contentShape(Rectangle())
            .onTapGesture { configuration.isOn.toggle() }
        }
    }
}

// MARK: - WelcomeView

struct WelcomeView: View {

    @EnvironmentObject private var entitlements: Entitlements

    // ✅ Persisted settings
    @AppStorage("tetrispuzzle.setting.rotateEnabled") private var rotateEnabled: Bool = true
    @AppStorage("tetrispuzzle.setting.rotateClockwise") private var rotateClockwise: Bool = true
    @AppStorage("tetrispuzzle.setting.clearColumnsEnabled") private var clearColumnsEnabled: Bool = true
    @AppStorage("tetrispuzzle.setting.soundsEnabled") private var soundsEnabled: Bool = true
    @AppStorage("tetrispuzzle.setting.hapticsEnabled") private var hapticsEnabled: Bool = true

    @State private var showPaywall: Bool = false
    @State private var showNewGameConfirmation = false

    let onStart: (Bool) -> Void

    private var isPro: Bool { entitlements.isPro }

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 18) {
                    header
                    howToCard
                    settingsCard
                    startButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 28)
                .padding(.bottom, 24)
            }
        }
        .onAppear { enforceFreeDefaultsIfNeeded() }
        .onChange(of: entitlements.isPro) { _, _ in enforceFreeDefaultsIfNeeded() }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(entitlements)
        }
        .confirmationDialog("Start a new game?", isPresented: $showNewGameConfirmation) {
            Button("New game", role: .destructive) { onStart(true) }
        } message: {
            Text("Your saved game will be replaced.")
        }
    }

    private func enforceFreeDefaultsIfNeeded() {
        guard !isPro else { return }
        rotateEnabled = false
        clearColumnsEnabled = false
        soundsEnabled = false
        hapticsEnabled = false
        // rotateClockwise can stay; rotation itself is locked anyway
    }

    // MARK: - Background (light, more pronounced)

    private var background: some View {
        GameColors.background.ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("Tetromix")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.92))

            Text("A quiet place to play with shapes")
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.55))
        }
        .padding(.top, 6)
    }

    private var howToCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How to play", systemImage: "hand.draw")
                .font(.headline)
            Text("Drag the current piece onto the board. Fill a horizontal line to clear it and earn points. Plan ahead with the next two pieces.")
                .font(.subheadline)
                .foregroundStyle(GameColors.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18).fill(GameColors.surface))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(GameColors.border, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Settings card

    private var settingsCard: some View {
        VStack(spacing: 12) {

            settingRow(
                title: "Rotation",
                subtitle: isPro ? "Allow rotating the current piece" : "Pro only"
            ) {
                gatedToggle("Rotation", isOn: $rotateEnabled, onColor: .blue)
            }

            Divider().background(Color.black.opacity(0.08))

            settingRow(
                title: "Rotate direction",
                subtitle: isPro ? (rotateClockwise ? "Clockwise" : "Counter-clockwise") : "Pro only"
            ) {
                gatedToggle("Rotate direction", isOn: $rotateClockwise, onColor: .indigo)
                    .disabled(!isPro || !rotateEnabled)
                    .opacity((isPro && rotateEnabled) ? 1.0 : 0.35)
                    .onTapGesture {
                        if !isPro { showPaywall = true }
                    }
            }

            Divider().background(Color.black.opacity(0.08))

            settingRow(
                title: "Clear columns",
                subtitle: isPro ? "Clear vertical lines too" : "Pro only"
            ) {
                gatedToggle("Clear columns", isOn: $clearColumnsEnabled, onColor: .teal)
            }

            Divider().background(Color.black.opacity(0.08))

            settingRow(
                title: "Sounds",
                subtitle: isPro ? "Placement + clear sounds" : "Pro only"
            ) {
                gatedToggle("Sounds", isOn: $soundsEnabled, onColor: .orange)
            }

            Divider().background(Color.black.opacity(0.08))

            settingRow(
                title: "Haptics",
                subtitle: isPro ? "Vibration feedback" : "Pro only"
            ) {
                gatedToggle("Haptics", isOn: $hapticsEnabled, onColor: .pink)
            }

            if !isPro {
                Divider().background(Color.black.opacity(0.08))

                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.open")
                        Text("Unlock Pro")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Spacer()
                        Text(entitlements.proPrice ?? "€1.99")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color.black.opacity(0.85))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(GameColors.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(GameColors.border, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(GameColors.surface))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(GameColors.border, lineWidth: 1))
        .padding(.top, 12)
    }

    /// ✅ TUKAJ je točno kje je `showPaywall = true`
    private func gatedToggle(_ title: String, isOn: Binding<Bool>, onColor: Color) -> some View {
        Toggle(title, isOn: Binding(
            get: { isOn.wrappedValue },
            set: { newValue in
                if isPro {
                    isOn.wrappedValue = newValue
                } else {
                    // user tried to enable -> show paywall
                    showPaywall = true
                }
            }
        ))
        .labelsHidden()
        .toggleStyle(GlowToggleStyle(onColor: onColor))
        .disabled(!isPro)
        .opacity(isPro ? 1.0 : 0.55)
    }

    private func settingRow<Accessory: View>(
        title: String,
        subtitle: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.90))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.black.opacity(0.55))
            }

            Spacer(minLength: 8)
            accessory()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Start button

    private var startButton: some View {
        VStack(spacing: 10) {
            Button { onStart(!GameViewModel.hasSavedGame) } label: {
                Label(GameViewModel.hasSavedGame ? "Continue game" : "Start game", systemImage: "play.fill")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 16).fill(GameColors.filled))
            }
            .buttonStyle(.plain)

            if GameViewModel.hasSavedGame {
                Button("New game") { showNewGameConfirmation = true }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GameColors.filled)
                    .padding(.vertical, 8)
            }
        }
        .padding(.bottom, 6)
    }
}

#Preview {
    WelcomeView(onStart: { _ in })
        .environmentObject(Entitlements())
}
