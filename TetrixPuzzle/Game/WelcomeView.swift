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

    let onStart: () -> Void

    private var isPro: Bool { entitlements.isPro }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 18) {
                header
                settingsCard
                Spacer(minLength: 10)
                startButton
            }
            .padding(.horizontal, 18)
            .padding(.top, 28)
            .padding(.bottom, 18)
        }
        .onAppear { enforceFreeDefaultsIfNeeded() }
        .onChange(of: entitlements.isPro) { _, _ in enforceFreeDefaultsIfNeeded() }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(entitlements)
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

            // Soft glow blobs (gives contrast without dark theme)
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

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("Tetris Puzzle")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.92))

            Text("Quick settings before you start")
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.55))
        }
        .padding(.top, 6)
    }

    // MARK: - Settings card

    private var settingsCard: some View {
        VStack(spacing: 12) {

            settingRow(
                title: "Rotation",
                subtitle: isPro ? "Allow rotating the current piece" : "Pro only"
            ) {
                gatedToggle(isOn: $rotateEnabled, onColor: .blue)
            }

            Divider().background(Color.black.opacity(0.08))

            settingRow(
                title: "Rotate direction",
                subtitle: isPro ? (rotateClockwise ? "Clockwise" : "Counter-clockwise") : "Pro only"
            ) {
                gatedToggle(isOn: $rotateClockwise, onColor: .indigo)
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
                gatedToggle(isOn: $clearColumnsEnabled, onColor: .teal)
            }

            Divider().background(Color.black.opacity(0.08))

            settingRow(
                title: "Sounds",
                subtitle: isPro ? "Placement + clear sounds" : "Pro only"
            ) {
                gatedToggle(isOn: $soundsEnabled, onColor: .orange)
            }

            Divider().background(Color.black.opacity(0.08))

            settingRow(
                title: "Haptics",
                subtitle: isPro ? "Vibration feedback" : "Pro only"
            ) {
                gatedToggle(isOn: $hapticsEnabled, onColor: .pink)
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
                            .fill(Color.white.opacity(0.80))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 7)
                }
                .buttonStyle(.plain)
            }

        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
        .padding(.top, 12)
    }

    /// ✅ TUKAJ je točno kje je `showPaywall = true`
    private func gatedToggle(isOn: Binding<Bool>, onColor: Color) -> some View {
        Toggle("", isOn: Binding(
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
        Button {
            onStart()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.headline)
                Text("Start Game")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 6)
    }
}

#Preview {
    WelcomeView(onStart: {})
        .environmentObject(Entitlements())
}
