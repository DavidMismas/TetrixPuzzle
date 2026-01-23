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

    // ✅ Persisted settings
    @AppStorage("tetrispuzzle.setting.rotateEnabled") private var rotateEnabled: Bool = true
    @AppStorage("tetrispuzzle.setting.clearColumnsEnabled") private var clearColumnsEnabled: Bool = true
    @AppStorage("tetrispuzzle.setting.soundsEnabled") private var soundsEnabled: Bool = true
    @AppStorage("tetrispuzzle.setting.hapticsEnabled") private var hapticsEnabled: Bool = true

    let onStart: () -> Void

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
                subtitle: "Allow rotating the current piece"
            ) {
                Toggle("", isOn: $rotateEnabled)
                    .labelsHidden()
                    .toggleStyle(GlowToggleStyle(onColor: .blue))
            }

            Divider().background(Color.black.opacity(0.08))

            settingRow(
                title: "Clear columns",
                subtitle: "Clear vertical lines too"
            ) {
                Toggle("", isOn: $clearColumnsEnabled)
                    .labelsHidden()
                    .toggleStyle(GlowToggleStyle(onColor: .teal))
            }

            Divider().background(Color.black.opacity(0.08))

            settingRow(
                title: "Sounds",
                subtitle: "Placement + clear sounds"
            ) {
                Toggle("", isOn: $soundsEnabled)
                    .labelsHidden()
                    .toggleStyle(GlowToggleStyle(onColor: .orange))
            }

            Divider().background(Color.black.opacity(0.08))

            settingRow(
                title: "Haptics",
                subtitle: "Vibration feedback"
            ) {
                Toggle("", isOn: $hapticsEnabled)
                    .labelsHidden()
                    .toggleStyle(GlowToggleStyle(onColor: .pink))
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
}
