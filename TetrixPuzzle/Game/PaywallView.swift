//
//  PaywallView.swift
//  TetrixPuzzle
//
//  Created by David Mišmaš on 24. 1. 26.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: Entitlements

    @State private var isBuying = false
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView {
                    VStack(spacing: 14) {

                        Image(systemName: "sparkles")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 8)

                        Text("Unlock Pro")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.92))

                        Text("Enable rotation, column clears, sounds, haptics and rotate direction.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.black.opacity(0.60))
                            .padding(.horizontal, 22)

                        featuresCard

                        Button {
                            Task {
                                isBuying = true
                                let ok = await entitlements.buyPro()
                                isBuying = false
                                if ok { dismiss() }
                            }
                        } label: {
                            HStack {
                                Spacer()
                                if isBuying {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Buy Pro \(entitlements.proPrice ?? "€1.99")")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                }
                                Spacer()
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 14)
                            .background(primaryButtonBackground)
                            .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 10)
                        }
                        .buttonStyle(.plain)
                        .disabled(isBuying)

                        Button {
                            Task {
                                isRestoring = true
                                await entitlements.restorePurchases()
                                isRestoring = false
                                if entitlements.isPro { dismiss() }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isRestoring {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text("Restore Purchases")
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.75))
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .disabled(isRestoring)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 18)
                }
                // ✅ zagotovi, da "Buy Pro" nikoli ni pod robom / home barom
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 16)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.black.opacity(0.75))
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            featureRow("Rotation")
            featureRow("Rotate direction")
            featureRow("Clear columns")
            featureRow("Sounds")
            featureRow("Haptics")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
        .padding(.top, 4)
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.blue.opacity(0.85))
            Text(text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.85))
        }
    }

    private var primaryButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.95), Color.purple.opacity(0.90)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 0.92, green: 0.97, blue: 1.00),
                    Color(red: 0.96, green: 0.94, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.cyan.opacity(0.18), Color.clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 460
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.purple.opacity(0.14), Color.clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 520
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(Entitlements())
}
