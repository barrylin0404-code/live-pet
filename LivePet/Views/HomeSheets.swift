import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Food sheet

struct SelectFoodSheet: View {
    @ObservedObject var store: PetStore
    var onPick: (InventoryItem) -> Void
    var onClose: (() -> Void)? = nil

    private let cream = Color(red: 0xF7 / 255.0, green: 0xF0 / 255.0, blue: 0xE6 / 255.0)
    private let stroke = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
    /// Food cells match outer chrome / Scenes hub — ink stroke, clear fill (no beige leftover).
    private let cellBorder = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
    private let favoriteGold = Color(red: 0xE8 / 255.0, green: 0xC5 / 255.0, blue: 0x47 / 255.0)
    private let columns = [
        GridItem(.fixed(96), spacing: 10),
        GridItem(.fixed(96), spacing: 10),
        GridItem(.fixed(96), spacing: 10)
    ]

    /// Favorite food first — same lead as the inventory ribbon.
    private var foodsFavoriteFirst: [InventoryItem] {
        store.foods.filter { $0.pixelSpriteName != nil }.sorted { a, b in
            let af = store.pet.isFavoriteFood(a.id)
            let bf = store.pet.isFavoriteFood(b.id)
            if af != bf { return af && !bf }
            return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Select Food")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                Spacer(minLength: 0)
                Button {
                    PetSound.shared.play(.uiTick)
                    onClose?()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(foodsFavoriteFirst) { item in
                    foodCell(item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: 340)
        .background(cream, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(stroke, lineWidth: 2.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.bottom, 120) // keep console silhouette readable
    }

    private func foodGlyph(_ item: InventoryItem) -> some View {
        Image(item.pixelSpriteName ?? "prop-fish")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 40, height: 40)
    }

    private func foodCell(_ item: InventoryItem) -> some View {
        let isFavorite = store.pet.isFavoriteFood(item.id)
        return Button {
            PetSound.shared.play(.feed)
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            onPick(item)
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    foodGlyph(item)
                        .frame(height: 44)
                    if isFavorite {
                        Image("prop-star")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .offset(x: 6, y: -4)
                    }
                }
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                    .lineLimit(1)
                Text("×∞")
                    .font(.system(size: 11, weight: .bold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 96, height: 110)
            .background(Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isFavorite ? favoriteGold : cellBorder, lineWidth: isFavorite ? 2.5 : 2)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("\(item.name), unlimited")
    }
}


// MARK: - Play / games sheet

struct SelectGameSheet: View {
    var petName: String
    var onPlayBall: () -> Void
    var onFollowWand: () -> Void
    var onHitIsland: () -> Void
    var onClose: (() -> Void)? = nil

    private let cream = Color(red: 0xF7 / 255.0, green: 0xF0 / 255.0, blue: 0xE6 / 255.0)
    private let stroke = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
    /// Play rows match Food / Scenes ink stroke (no beige leftover).
    private let border = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)


    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Play with \(petName)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Button {
                    PetSound.shared.play(.uiTick)
                    onClose?()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            VStack(spacing: 10) {
                gameRow(title: "Play Ball", pixel: "prop-ball", action: onPlayBall)
                gameRow(title: "Follow the wand", pixel: "prop-wand", action: onFollowWand)
                gameRow(title: "Hit the Island", pixel: "prop-island", action: onHitIsland)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: 340)
        .background(cream, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(stroke, lineWidth: 2.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.bottom, 120)
    }

    private func gameGlyph(icon: String?, pixel: String?) -> some View {
        Image(pixel ?? "prop-ball")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 40, height: 40)
    }

    private func gameRow(title: String, icon: String? = nil, pixel: String? = nil, action: @escaping () -> Void) -> some View {
        Button {
            PetSound.shared.play(.uiTick)
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            action()
        } label: {
            HStack(spacing: 12) {
                gameGlyph(icon: icon, pixel: pixel)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(border, lineWidth: 2)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}


// MARK: - Pets sheet

struct PetsSheet: View {
    @ObservedObject var store: PetStore
    var onSwitch: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var pendingId: UUID?

    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let selectedBorder = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Pets")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ink)
                Spacer(minLength: 0)
                Button {
                    PetSound.shared.play(.uiTick)
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ink)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            VStack(spacing: 16) {
                Text("Choose who hangs out")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(store.pets) { p in
                        petCard(p)
                    }
                    if store.pipUnlocked == false || !store.pets.contains(where: { $0.petGlyph == "pip" }) {
                        lockedPipCard
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    // Same pet: just close — don't reset the room brain mid-walk.
                    if let id = pendingId, id != store.pet.id {
                        PetSound.shared.play(.meow)
                        store.setActivePet(id: id)
                        onSwitch()
                    } else {
                        PetSound.shared.play(.uiTick)
                    }
                    dismiss()
                } label: {
                    Text("Use this pet")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.29, green: 0.25, blue: 0.21), in: Capsule())
                }
                .buttonStyle(PressScaleButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .background(cream.ignoresSafeArea())
        .onAppear { pendingId = store.pet.id }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private func petCard(_ p: Pet) -> some View {
        let selected = (pendingId ?? store.pet.id) == p.id
        return Button {
            pendingId = p.id
            PetSound.shared.play(.uiTick)
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            VStack(spacing: 8) {
                TimelineView(.animation(minimumInterval: 1.0 / 6.0)) { context in
                    let tick = Int(context.date.timeIntervalSinceReferenceDate * 6)
                    // Same sleep-breath / happy one-shot as StatusStrip + Home widgets.
                    let shown = WidgetMoodClip.clip(mood: p.mood, isSleeping: p.isSleeping, tick: tick)
                    ClipPetView(
                        speciesId: p.petGlyph,
                        anim: shown.anim,
                        frame: shown.frame,
                        facingLeft: false,
                        displaySize: 72,
                        growthStage: p.growthStage
                    )
                }
                .frame(height: 72)
                Text(p.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ink)
                Text((p.petGlyph == "pip" ? "Pip" : p.growthStage.displayName) + (p.isSleeping ? " · napping" : ""))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? selectedBorder : Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0), lineWidth: selected ? 3 : 2)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var lockedPipCard: some View {
        VStack(spacing: 8) {
            TimelineView(.animation(minimumInterval: 1.0 / 6.0)) { context in
                let frame = Int(context.date.timeIntervalSinceReferenceDate * 6)
                ClipPetView(speciesId: "pip", anim: .idle, frame: frame, facingLeft: false, displaySize: 72)
            }
            .frame(height: 72)
            Text("Pip")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ink)
            Text("Grows with Nubby")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0), lineWidth: 2)
        )
        // Dim so locked Pip does not read as selectable next to Nubby.
        .opacity(0.55)
        .accessibilityLabel("Pip, grows with Nubby")
    }
}

// MARK: - Scenes sheet

struct ScenesSheet: View {
    @ObservedObject var store: PetStore
    var onPets: (() -> Void)? = nil
    var onWidgets: (() -> Void)? = nil
    var onShop: (() -> Void)? = nil
    var onInventory: (() -> Void)? = nil
    var onSettings: (() -> Void)? = nil
    @EnvironmentObject private var activityManager: PetLiveActivityManager
    @Environment(\.dismiss) private var dismiss

    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let stroke = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
    private let coral = Color(red: 0xFA / 255.0, green: 0x85 / 255.0, blue: 0x6B / 255.0)
    /// Three columns — Sun/Moon/Meadow, Tide/Skyline/Snow, Coral (+ next empty).
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Scenes")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ink)
                Spacer(minLength: 0)
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ink)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ScrollView {
                // Feeling + Satiety + age — console meters live here (More), not on the room plate.
                StatusStripView(pet: store.pet)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(PetRoomScene.availableInDisplayOrder) { scene in
                        Button {
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                            store.setScene(scene)
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                SceneThumbView(scene: scene)
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                Text(scene.displayName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                            }
                            .padding(8)
                            .background(Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(store.selectedScene == scene ? coral : stroke,
                                                  lineWidth: store.selectedScene == scene ? 3 : 2)
                            )
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
                .padding(16)

                VStack(spacing: 10) {
                    if let onPets {
                        scenesLinkRow("Pets", pixel: nil, action: onPets)
                    }
                    if let onWidgets {
                        scenesLinkRow("Widgets", pixel: nil, action: onWidgets)
                    }
                    if let onShop {
                        scenesLinkRow("Shop", pixel: "prop-fish", action: onShop)
                    }
                    if let onInventory {
                        scenesLinkRow("Inventory", pixel: "prop-ball", action: onInventory)
                    }

                    Toggle(
                        "Dynamic Island",
                        isOn: Binding(
                            get: { activityManager.isActivityActive },
                            set: { on in
                                PetSound.shared.play(.uiTick)
                                if on {
                                    activityManager.start(pet: store.pet)
                                } else {
                                    activityManager.end()
                                }
                            }
                        )
                    )
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                    .tint(coral)
                    .disabled(!activityManager.areActivitiesEnabled && !activityManager.isActivityActive)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(stroke, lineWidth: 2)
                    )

                    if let onSettings {
                        scenesLinkRow("Sound and name", pixel: nil, action: onSettings)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(cream.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private func scenesLinkRow(_ title: String, pixel: String?, action: @escaping () -> Void) -> some View {
        Button {
            PetSound.shared.play(.uiTick)
            action()
        } label: {
            HStack(spacing: 12) {
                if let pixel {
                    Image(pixel)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 2)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

struct SceneThumbView: View {
    let scene: PetRoomScene

    var body: some View {
        Image(scene.thumbImageName ?? scene.plateImageName ?? "sun-nook-plate")
            .interpolation(.none)
            .resizable()
            .scaledToFill()
            .allowsHitTesting(false)
    }
}

// MARK: - Inventory (pixel goods only)

struct InventorySheet: View {
    @ObservedObject var store: PetStore
    var onFood: (InventoryItem) -> Void
    var onToy: (InventoryItem) -> Void
    /// Bubble Soap — same bath path as the ribbon (dock ctrl-bath).
    var onClean: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    // Match Food / Play / Scenes — ink stroke, not beige leftover.
    private let border = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let favoriteGold = Color(red: 0xE8 / 255.0, green: 0xC5 / 255.0, blue: 0x47 / 255.0)

    /// Favorites lead — same order family as the ribbon / Food sheet. Soap trails toys.
    private var items: [InventoryItem] {
        let raw = store.foods.filter { $0.pixelSpriteName != nil }
            + store.toys.filter { $0.pixelSpriteName != nil }
            + store.careItems.filter { $0.pixelSpriteName != nil }
        return raw.sorted { a, b in
            let af = a.isFood ? store.pet.isFavoriteFood(a.id)
                : (a.isToy ? store.pet.isFavoriteToy(a.id) : false)
            let bf = b.isFood ? store.pet.isFavoriteFood(b.id)
                : (b.isToy ? store.pet.isFavoriteToy(b.id) : false)
            if af != bf { return af && !bf }
            // Foods, then toys, then care — favorites already floated up within type.
            let rank: (InventoryItem) -> Int = { $0.isFood ? 0 : ($0.isToy ? 1 : 2) }
            if rank(a) != rank(b) { return rank(a) < rank(b) }
            return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Inventory")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ink)
                Spacer(minLength: 0)
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ink)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], spacing: 10) {
                    ForEach(items) { item in
                        cell(item)
                    }
                }
                .padding(.horizontal, 16)
                Text("Owned goods with pixel art. Soap never runs out.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            }
        }
        .background(cream.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private func cell(_ item: InventoryItem) -> some View {
        let isFavorite = item.isFood
            ? store.pet.isFavoriteFood(item.id)
            : (item.isToy ? store.pet.isFavoriteToy(item.id) : false)
        return Button {
            PetSound.shared.play(.uiTick)
            if item.isFood {
                onFood(item)
            } else if item.isToy {
                onToy(item)
            } else {
                onClean?()
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    Image(item.pixelSpriteName ?? "prop-fish")
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    Text(item.name)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ink)
                        .lineLimit(1)
                    if item.isFood {
                        Text("×\(item.quantity)")
                            .font(.system(size: 10, weight: .bold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    } else if item.isCare {
                        Text("×∞")
                            .font(.system(size: 10, weight: .bold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(isFavorite ? favoriteGold : border, lineWidth: isFavorite ? 2.5 : 2)
                )
                if isFavorite {
                    Image("prop-star")
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .offset(x: -4, y: 4)
                }
            }
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(item.isFood && item.quantity <= 0)
    }
}

// MARK: - Shop (free pixel goods only)

struct ShopSheet: View {
    @ObservedObject var store: PetStore
    var onFood: (InventoryItem) -> Void
    var onPlayBall: () -> Void
    var onFollowWand: () -> Void
    var onSoftSquare: () -> Void
    var onBounceBlock: () -> Void
    var onHitIsland: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    // Match Food / Play / Scenes — ink stroke, not beige leftover.
    private let border = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
    private let favoriteGold = Color(red: 0xE8 / 255.0, green: 0xC5 / 255.0, blue: 0x47 / 255.0)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)

    /// Favorite food first — same lead as the inventory ribbon / Select Food.
    private var foodsFavoriteFirst: [InventoryItem] {
        store.foods.filter { $0.pixelSpriteName != nil }.sorted { a, b in
            let af = store.pet.isFavoriteFood(a.id)
            let bf = store.pet.isFavoriteFood(b.id)
            if af != bf { return af && !bf }
            return false
        }
    }

    /// Favorite toy rows first, then the other pixel toys, then wand / Island games.
    private var toyRowsFavoriteFirst: [(title: String, sprite: String, toyId: String?, action: () -> Void)] {
        let toys: [(String, String, String, () -> Void)] = [
            ("Play Ball", "prop-ball", "twinkle_ball", onPlayBall),
            ("Soft Square", "prop-soft", "soft_square", onSoftSquare),
            ("Bounce Block", "prop-bounce", "bounce_block", onBounceBlock)
        ]
        let sorted = toys.sorted { a, b in
            let af = store.pet.isFavoriteToy(a.2)
            let bf = store.pet.isFavoriteToy(b.2)
            if af != bf { return af && !bf }
            return false
        }
        var rows: [(title: String, sprite: String, toyId: String?, action: () -> Void)] =
            sorted.map { (title: $0.0, sprite: $0.1, toyId: $0.2, action: $0.3) }
        rows.append((title: "Follow the wand", sprite: "prop-wand", toyId: nil, action: onFollowWand))
        rows.append((title: "Hit the Island", sprite: "prop-island", toyId: nil, action: onHitIsland))
        return rows
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Shop")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ink)
                Spacer(minLength: 0)
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ink)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(foodsFavoriteFirst) { item in
                        row(
                            title: item.name,
                            sprite: item.pixelSpriteName ?? "prop-fish",
                            isFavorite: store.pet.isFavoriteFood(item.id)
                        ) {
                            onFood(item)
                        }
                    }
                    // Toys with pixel art — Soft Square / Bounce Block / ball (wand + island are games).
                    ForEach(Array(toyRowsFavoriteFirst.enumerated()), id: \.offset) { _, rowInfo in
                        row(
                            title: rowInfo.title,
                            sprite: rowInfo.sprite,
                            isFavorite: rowInfo.toyId.map { store.pet.isFavoriteToy($0) } ?? false,
                            action: rowInfo.action
                        )
                    }
                }
                .padding(.horizontal, 16)
                Text("Free. No upgrade.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            }
        }
        .background(cream.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private func row(title: String, sprite: String, isFavorite: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            PetSound.shared.play(.uiTick)
            action()
        } label: {
            HStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(sprite)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                    if isFavorite {
                        Image("prop-star")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .offset(x: 6, y: -4)
                    }
                }
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ink)
                Spacer()
                Text("Free")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ink.opacity(0.55))
            }
            .padding(12)
            .background(Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isFavorite ? favoriteGold : border, lineWidth: isFavorite ? 2.5 : 2)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(isFavorite ? "\(title), favorite, free" : "\(title), free")
    }
}

// MARK: - Widgets gallery tip

struct WidgetsGallerySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PetStore

    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    // Match Food / Play / Scenes — ink stroke, not beige leftover.
    private let border = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private let widgets: [(String, String)] = [
        ("Live Pet", "Your pet at home"),
        ("Pet Clock", "Time with your pet"),
        ("Pet Weather", "Local weather peek"),
        ("Pet Day", "Date + care streak"),
        ("Pet Note", "Daily message"),
        ("Pet Photo", "Portrait widget")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Widgets")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ink)
                Spacer(minLength: 0)
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ink)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(widgets, id: \.0) { title, blurb in
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack {
                                Image("home-widget-plate")
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFill()
                                    .frame(height: 56)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                TimelineView(.animation(minimumInterval: 1.0 / 6.0)) { context in
                                    let frame = Int(context.date.timeIntervalSinceReferenceDate * 6)
                                    ClipPetView(
                                        speciesId: store.pet.petGlyph,
                                        anim: .idle,
                                        frame: frame,
                                        facingLeft: false,
                                        displaySize: 44,
                                        growthStage: store.pet.growthStage
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            Text(title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(ink)
                            Text(blurb)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(border, lineWidth: 2)
                        )
                    }
                }
                .padding(16)

                Text("Long-press Home Screen → + → search “Live Pet” → add a widget. Free forever — no Upgrade tab.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .background(cream.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
}



// MARK: - Info / how-to (room [i] — never a paywall)

struct InfoHowToSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let cream = Color(red: 0xF7 / 255.0, green: 0xF0 / 255.0, blue: 0xE6 / 255.0)
    private let stroke = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("How to play")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ink)
                Spacer(minLength: 0)
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ink)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Live Pet is free forever — no Upgrade, Unlock, or IAP.")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(ink)
                    labelRow("Feed", "Pick food from the dock — your pet walks over and eats.")
                    labelRow("Play", "Play Ball, Follow the wand, or Hit the Island.")
                    labelRow("Inventory", "Tap fish, berry, Soft Square, Bounce Block, or ball above the dock — they land in the room.")
                    labelRow("Island", "Turn on Dynamic Island from More.")
                    Text("Bath and Sleep are on the dock — Sleep toggles wake. Shake only sleeps when awake.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(cream.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
    }

    private func labelRow(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(red: 0xE8 / 255.0, green: 0x91 / 255.0, blue: 0xB8 / 255.0), in: Capsule())
            Text(body)
                .font(.subheadline)
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
