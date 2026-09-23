import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Food sheet

struct SelectFoodSheet: View {
    @ObservedObject var store: PetStore
    var onPick: (InventoryItem) -> Void
    @Environment(\.dismiss) private var dismiss

    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    private let cellBorder = Color(red: 0xE8 / 255.0, green: 0xD4 / 255.0, blue: 0xC4 / 255.0)
    private let favoriteGold = Color(red: 0xE8 / 255.0, green: 0xC5 / 255.0, blue: 0x47 / 255.0)
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(store.foods) { item in
                        foodCell(item)
                    }
                }
                .padding(16)
            }
            .background(cream.ignoresSafeArea())
            .navigationTitle("Select Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private func foodCell(_ item: InventoryItem) -> some View {
        let isFavorite = store.pet.isFavoriteFood(item.id)
        return Button {
            PetSound.shared.play(.feed)
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            onPick(item)
            dismiss()
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.symbolName)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Color.orange)
                        .frame(height: 44)
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(favoriteGold)
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
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
    @Environment(\.dismiss) private var dismiss

    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    private let border = Color(red: 0xE8 / 255.0, green: 0xD4 / 255.0, blue: 0xC4 / 255.0)
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    gameCard(title: "Play Ball", icon: "tennisball.fill", stub: false, action: onPlayBall)
                    gameCard(title: "Follow the wand", icon: "wand.and.stars", stub: false, action: onFollowWand)
                    gameCard(title: "Hit the Island", icon: "sportscourt.fill", stub: false, action: onHitIsland)
                }
                .padding(16)
            }
            .background(cream.ignoresSafeArea())
            .navigationTitle("Play with \(petName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private func gameCard(title: String, icon: String, stub: Bool, action: @escaping () -> Void) -> some View {
        Button {
            PetSound.shared.play(.uiTick)
            
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            action()
            dismiss()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Color(red: 0x7E / 255.0, green: 0xC8 / 255.0, blue: 0xE3 / 255.0))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                    .multilineTextAlignment(.center)
                if stub {
                    Text("Coming soon")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
            .padding(8)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
    private let selectedBorder = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
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
                    if let id = pendingId ?? Optional(store.pet.id) {
                        store.setActivePet(id: id)
                        onSwitch()
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
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .padding(.top, 12)
            .background(cream.ignoresSafeArea())
            .navigationTitle("Pets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear { pendingId = store.pet.id }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private func petCard(_ p: Pet) -> some View {
        let selected = (pendingId ?? store.pet.id) == p.id
        return Button {
            pendingId = p.id
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            VStack(spacing: 8) {
                AnimatedPixelPetView(
                    mood: p.mood,
                    pose: .idle,
                    isSleeping: false,
                    speciesId: p.petGlyph,
                    growthStage: p.growthStage,
                    scale: 0.7
                )
                Text(p.name)
                    .font(.subheadline.weight(.bold))
                Text(p.petGlyph == "pip" ? "Pip" : p.growthStage.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.30, green: 0.70, blue: 0.40))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(selected ? Color(red: 1.0, green: 0.96, blue: 0.88) : Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? selectedBorder : Color(red: 0xE8 / 255.0, green: 0xD4 / 255.0, blue: 0xC4 / 255.0), lineWidth: selected ? 3 : 2)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var lockedPipCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Pip")
                .font(.subheadline.weight(.bold))
            Text("Grows with Nubby")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(red: 0xE8 / 255.0, green: 0xD4 / 255.0, blue: 0xC4 / 255.0), lineWidth: 2)
        )
        .accessibilityLabel("Pip locked — unlock after first Grow")
    }
}

// MARK: - Scenes sheet

struct ScenesSheet: View {
    @ObservedObject var store: PetStore
    @Environment(\.dismiss) private var dismiss

    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    private let coral = Color(red: 0xFA / 255.0, green: 0x85 / 255.0, blue: 0x6B / 255.0)
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(PetRoomScene.allCases) { scene in
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
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                            }
                            .padding(8)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(store.selectedScene == scene ? coral : Color(red: 0xE8 / 255.0, green: 0xD4 / 255.0, blue: 0xC4 / 255.0),
                                                  lineWidth: store.selectedScene == scene ? 3 : 2)
                            )
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
                .padding(16)
            }
            .background(cream.ignoresSafeArea())
            .navigationTitle("Scenes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
}

struct SceneThumbView: View {
    let scene: PetRoomScene

    var body: some View {
        RoomSceneView(scene: scene, mood: .content, firefliesUnlocked: 0, showFireflies: false) {
            EmptyView()
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Widgets gallery tip

struct WidgetsGallerySheet: View {
    @Environment(\.dismiss) private var dismiss

    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    private let border = Color(red: 0xE8 / 255.0, green: 0xD4 / 255.0, blue: 0xC4 / 255.0)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private let widgets: [(String, String, String)] = [
        ("Pet Feeling", "heart.fill", "Mood hearts on Home Screen"),
        ("Pet Clock", "clock.fill", "Time with your pet"),
        ("Pet Weather", "cloud.sun.fill", "Local weather peek"),
        ("Pet Day", "calendar", "Date + care streak"),
        ("Pet Note", "text.bubble.fill", "Daily message"),
        ("Pet Photo", "photo.fill", "Portrait widget")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(widgets, id: \.0) { title, icon, blurb in
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(Color(red: 0xE8 / 255.0, green: 0x91 / 255.0, blue: 0xB8 / 255.0))
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
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            .background(cream.ignoresSafeArea())
            .navigationTitle("Widgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Lightweight coming-soon toast for stub games.
struct ComingSoonBanner: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.78), in: Capsule())
    }
}
