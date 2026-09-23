import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Beige Game Boy–style handheld console — tokens from 14-video-parity-chrome.
struct ConsolePanelView: View {
    @ObservedObject var store: PetStore
    @ObservedObject var activityManager: PetLiveActivityManager

    var onFood: () -> Void
    var onPlay: () -> Void
    var onPets: () -> Void
    var onScenes: () -> Void
    var onWidgets: () -> Void
    var onSettings: () -> Void
    var onClean: () -> Void
    var onSleep: () -> Void
    var onRename: (String) -> Void

    @State private var editingName = false
    @State private var draftName = ""

    private let shell = Color(red: 0xE6 / 255.0, green: 0xE6 / 255.0, blue: 0xE6 / 255.0)
    private let lcd = Color(red: 0xC8 / 255.0, green: 0xDC / 255.0, blue: 0xC4 / 255.0)
    private let lcdBorder = Color(red: 0x9B / 255.0, green: 0xB8 / 255.0, blue: 0x96 / 255.0)
    private let fpPink = Color(red: 0xE8 / 255.0, green: 0x91 / 255.0, blue: 0xB8 / 255.0)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let heartFill = Color(red: 1.0, green: 0.30, blue: 0.43)

    var body: some View {
        VStack(spacing: 10) {
            lcdBlock
            islandRow
            controlsRow
            Text("Live Pet")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(ink.opacity(0.35))
                .padding(.top, 2)
            footerBar
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(shell)
                .shadow(color: .black.opacity(0.12), radius: 8, y: -2)
        )
    }

    private var lcdBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                avatar
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    if editingName {
                        TextField("Name", text: $draftName)
                            .font(.headline.weight(.bold))
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
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(ink)
                                    .lineLimit(1)
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(ink.opacity(0.5))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Text("Age: \(store.pet.ageDays) Days")
                        .font(.caption.weight(.semibold))
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
        .padding(10)
        .background(lcd, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(lcdBorder, lineWidth: 2)
        )
    }

    private var islandRow: some View {
        HStack {
            Text("Dynamic Island")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ink)
            Spacer()
            Toggle(
                "",
                isOn: Binding(
                    get: { activityManager.isActivityActive },
                    set: { on in
                        lightHaptic()
                        if on {
                            activityManager.start(pet: store.pet)
                        } else {
                            activityManager.end()
                        }
                    }
                )
            )
            .labelsHidden()
            .tint(fpPink)
            .disabled(!activityManager.areActivitiesEnabled && !activityManager.isActivityActive)
        }
        .padding(.horizontal, 4)
    }

    private var controlsRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(spacing: 8) {
                pill("Pets", action: onPets)
                pill("Scenes", action: onScenes)
            }
            Spacer(minLength: 4)
            HStack(spacing: 16) {
                roundAction("F", accessibility: "Feed — select food", action: onFood, longPress: onClean)
                roundAction("P", accessibility: "Play — select game", action: onPlay, longPress: onSleep)
            }
        }
        .padding(.horizontal, 4)
    }

    private var footerBar: some View {
        HStack {
            Button {
                lightHaptic()
                onWidgets()
            } label: {
                Label("Widgets", systemImage: "square.grid.2x2.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(ink)
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                lightHaptic()
                onSettings()
            } label: {
                Label("Settings", systemImage: "gearshape.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(ink)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
        .padding(.horizontal, 6)
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
                .frame(width: 56, height: 56)
                .background(fpPink, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 2))
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
                scale: 0.55
            )
        }
        #else
        AnimatedPixelPetView(
            mood: store.pet.mood,
            pose: store.pet.pose,
            isSleeping: store.pet.isSleeping,
            speciesId: store.pet.petGlyph,
            growthStage: store.pet.growthStage,
            scale: 0.55
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
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
