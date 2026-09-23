import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Chunky Feed / Play / Clean / Sleep tray — 13-playable-home toy chrome.
struct CareTrayView: View {
    var satiety: Int
    var feelingScore: Int
    var onFeed: () -> Void
    var onPlay: () -> Void
    var onClean: () -> Void
    var onSleep: () -> Void

    private let feedFill = Color(red: 0xFF / 255.0, green: 0x8B / 255.0, blue: 0x6A / 255.0)
    private let feedBorder = Color(red: 0xC4 / 255.0, green: 0x45 / 255.0, blue: 0x2D / 255.0)
    private let playFill = Color(red: 0x7E / 255.0, green: 0xC8 / 255.0, blue: 0xE3 / 255.0)
    private let playBorder = Color(red: 0x3A / 255.0, green: 0x8F / 255.0, blue: 0xB0 / 255.0)
    private let cleanFill = Color(red: 0xA8 / 255.0, green: 0xE6 / 255.0, blue: 0xCF / 255.0)
    private let cleanBorder = Color(red: 0x4C / 255.0, green: 0xAF / 255.0, blue: 0x8A / 255.0)
    private let sleepFill = Color(red: 0xC5 / 255.0, green: 0xB4 / 255.0, blue: 0xE3 / 255.0)
    private let sleepBorder = Color(red: 0x7B / 255.0, green: 0x6B / 255.0, blue: 0x9E / 255.0)

    var body: some View {
        HStack(spacing: 10) {
            CareChunkButton(
                title: "Feed",
                systemImage: "fish.fill",
                fill: feedFill,
                border: feedBorder,
                pulse: satiety < 34,
                action: onFeed
            )
            CareChunkButton(
                title: "Play",
                systemImage: "circle.fill",
                fill: playFill,
                border: playBorder,
                pulse: feelingScore < 34 && satiety >= 34,
                action: onPlay
            )
            CareChunkButton(
                title: "Clean",
                systemImage: "bubble.fill",
                fill: cleanFill,
                border: cleanBorder,
                pulse: false,
                action: onClean
            )
            CareChunkButton(
                title: "Sleep",
                systemImage: "moon.zzz.fill",
                fill: sleepFill,
                border: sleepBorder,
                pulse: false,
                accessibilityLabel: "Tuck in",
                action: onSleep
            )
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Care tray")
    }
}

private struct CareChunkButton: View {
    let title: String
    let systemImage: String
    let fill: Color
    let border: Color
    var pulse: Bool
    var accessibilityLabel: String? = nil
    let action: () -> Void

    @State private var pressed = false
    @State private var pulseScale: CGFloat = 1

    var body: some View {
        Button {
            lightHaptic()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.22, green: 0.18, blue: 0.16))
            }
            .frame(maxWidth: .infinity)
            .frame(minWidth: 72, minHeight: 64)
            .padding(.vertical, 8)
            .background(fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(border, lineWidth: 3)
            )
            .scaleEffect((pressed ? 0.92 : 1) * pulseScale)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed {
                        withAnimation(.easeOut(duration: 0.08)) { pressed = true }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) { pressed = false }
                }
        )
        .accessibilityLabel(accessibilityLabel ?? title)
        .onAppear { startPulseIfNeeded() }
        .onChange(of: pulse, perform: { _ in startPulseIfNeeded() })
    }

    private func startPulseIfNeeded() {
        guard pulse else {
            withAnimation(.easeOut(duration: 0.2)) { pulseScale = 1 }
            return
        }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulseScale = 1.04
        }
    }

    private func lightHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
