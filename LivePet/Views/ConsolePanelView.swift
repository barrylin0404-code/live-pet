import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Beige Game Boy–style handheld console — layout tokens from 17-layout-pass.
/// LCD + hardware + emboss only. Widgets/Settings live in BottomUtilityBar (ContentView).
struct ConsolePanelView: View {
    @ObservedObject var store: PetStore

    var onFood: () -> Void
    var onPlay: () -> Void
    var onPets: () -> Void
    var onScenes: () -> Void
    var onClean: () -> Void
    var onSleep: () -> Void
    var onRename: (String) -> Void

    @State private var editingName = false
    @State private var draftName = ""

    private let shell = Color(red: 0xE6 / 255.0, green: 0xE6 / 255.0, blue: 0xE6 / 255.0)
    private let lcd = Color(red: 0xC8 / 255.0, green: 0xDC / 255.0, blue: 0xC4 / 255.0)
    private let lcdBorder = Color(red: 0x9B / 255.0, green: 0xB8 / 255.0, blue: 0x96 / 255.0)
    private let fpPink = Color(red: 0xE8 / 255.0, green: 0x91 / 255.0, blue: 0xB8 / 255.0)
    private let fpBevel = Color(red: 0xC4 / 255.0, green: 0x45 / 255.0, blue: 0x7A / 255.0)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let heartFill = Color(red: 1.0, green: 0.30, blue: 0.43)

    var body: some View {
        VStack(spacing: 10) {
            lcdBlock
            controlsRow
            Text("Live Pet")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(ink.opacity(0.35))
                .padding(.top, 2)
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(shell)
                .shadow(color: .black.opacity(0.12), radius: 8, y: -2)
        )
    }

    private var lcdBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                avatar
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    if editingName {
                        TextField("Name", text: $draftName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(ink)
                            .onSubmit { commitRename() }
                        Button("Save") { commitRename() }
                            .font(.caption.weight(.bold))
                    } else {
                        Button {
                            draftName = store.pet.name
                            editingName = true
                        } label: {
                            HStack(spacing: 4) {
                                Text(store.pet.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(ink)
                                    .lineLimit(1)
                                Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(ink.opacity(0.5))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Text("Age: \(store.pet.ageDays) Days")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.7))
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                Text("Feeling")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ink)
                    .frame(width: 52, alignment: .leading)
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        Image(systemName: i < filledHearts ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundStyle(i < filledHearts ? heartFill : heartFill.opacity(0.35))
                    }
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Feeling, \(store.pet.moodScore) percent")

            HStack(spacing: 8) {
                Text("Satiety")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ink)
                    .frame(width: 52, alignment: .leading)
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < filledSatiety ? Color.orange : Color.orange.opacity(0.22))
                            .frame(width: 12, height: 12)
                            .overlay(Circle().strokeBorder(Color.orange.opacity(0.5), lineWidth: 1.2))
                    }
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Satiety, \(store.pet.satiety) percent")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(lcd, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(lcdBorder, lineWidth: 2.5)
        )
    }

    private var controlsRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(spacing: 10) {
                pill("Pets", action: onPets)
                pill("Scenes", action: onScenes)
            }
            Spacer(minLength: 4)
            HStack(spacing: 18) {
                roundAction("F", accessibility: "Feed — select food", action: onFood, longPress: onClean)
                roundAction("P", accessibility: "Play — select game", action: onPlay, longPress: onSleep)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    private func pill(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            lightHaptic()
            action()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 28)
                .background(Color.black, in: Capsule())
        }
        .buttonStyle(PressScaleButtonStyle())
        .frame(minHeight: 44)
        .accessibilityLabel(title)
    }

    private func roundAction(_ letter: String, accessibility: String, action: @escaping () -> Void, longPress: @escaping () -> Void) -> some View {
        Button {
            lightHaptic()
            action()
        } label: {
            Text(letter)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(fpPink, in: Circle())
                .overlay(Circle().strokeBorder(fpBevel, lineWidth: 3))
                .shadow(color: fpPink.opacity(0.45), radius: 4, y: 2)
        }
        .buttonStyle(PressScaleButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                lightHaptic()
                longPress()
            }
        )
        .accessibilityLabel(accessibility)
        .accessibilityHint(letter == "F" ? "Long press to clean" : "Long press to tuck in")
    }

    @ViewBuilder
    private var avatar: some View {
        #if canImport(UIKit)
        let name = PetSprite.avatarName(speciesId: store.pet.petGlyph, growthStage: store.pet.growthStage)
        if UIImage(named: name) != nil {
            Image(name)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            AnimatedPixelPetView(
                mood: store.pet.mood,
                pose: store.pet.pose,
                isSleeping: store.pet.isSleeping,
                speciesId: store.pet.petGlyph,
                growthStage: store.pet.growthStage,
                scale: 0.50
            )
        }
        #else
        AnimatedPixelPetView(
            mood: store.pet.mood,
            pose: store.pet.pose,
            isSleeping: store.pet.isSleeping,
            speciesId: store.pet.petGlyph,
            growthStage: store.pet.growthStage,
            scale: 0.50
        )
        #endif
    }

    private var filledHearts: Int {
        switch store.pet.moodScore {
        case 75...100: return 4
        case 50..<75: return 3
        case 25..<50: return 2
        case 1..<25: return 1
        default: return 0
        }
    }

    private var filledSatiety: Int {
        switch store.pet.satiety {
        case 67...100: return 3
        case 34..<67: return 2
        case 1..<34: return 1
        default: return 0
        }
    }

    private func commitRename() {
        onRename(draftName)
        editingName = false
    }

    private func lightHaptic() {
        PetSound.shared.play(.uiTick)
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

/// Bottom 7% utility bar — Widgets | Settings only (17).
struct BottomUtilityBar: View {
    var onWidgets: () -> Void
    var onSettings: () -> Void

    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let bar = Color(red: 0x11 / 255.0, green: 0x11 / 255.0, blue: 0x11 / 255.0)

    var body: some View {
        HStack {
            Button {
                PetSound.shared.play(.uiTick)
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                onWidgets()
            } label: {
                Label("Widgets", systemImage: "square.grid.2x2.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(PressScaleButtonStyle())

            Button {
                PetSound.shared.play(.uiTick)
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                onSettings()
            } label: {
                Label("Settings", systemImage: "gearshape.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bar)
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.52), value: configuration.isPressed)
    }
}
