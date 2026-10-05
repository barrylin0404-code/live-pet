import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Always-visible horizontal inventory ribbon — 13-playable-home (≥4 cells).
struct InventoryPanel: View {
    @ObservedObject var store: PetStore
    /// Foods leave the ribbon so ContentView can drop props and walk-to-eat.
    var onFood: (InventoryItem) -> Void
    /// Toys leave the ribbon so ContentView can drop props / start games.
    var onToy: (InventoryItem) -> Void
    var onClean: () -> Void

    private let favoriteGold = Color(red: 0xE8 / 255.0, green: 0xC5 / 255.0, blue: 0x47 / 255.0)
    private let cellBorder = Color(red: 0xE8 / 255.0, green: 0xD4 / 255.0, blue: 0xC4 / 255.0)

    private var ribbonItems: [InventoryItem] {
        var list: [InventoryItem] = []
        list.append(contentsOf: store.foods.filter { $0.pixelSpriteName != nil })
        list.append(contentsOf: store.toys.filter { $0.pixelSpriteName != nil })
        // Care without pixel art (bubble_soap) stays internal — bath dock uses ctrl-bath.
        list.append(contentsOf: store.careItems.filter { $0.pixelSpriteName != nil })
        return list
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ribbonItems) { item in
                    ribbonCell(item)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .frame(minHeight: 64)
        }
        .frame(height: 64)
        .accessibilityLabel("Inventory")
    }

    private func inventoryGlyph(_ item: InventoryItem) -> some View {
        Image(item.pixelSpriteName ?? "prop-fish")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 28, height: 28)
    }

    @ViewBuilder
    private func ribbonCell(_ item: InventoryItem) -> some View {
        let isFavorite = item.isFood
            ? store.pet.isFavoriteFood(item.id)
            : (item.isToy ? store.pet.isFavoriteToy(item.id) : false)
        Button {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            if item.isFood {
                onFood(item)
            } else if item.isToy {
                onToy(item)
            } else {
                // Bath lives in ContentView.performClean (sound + brain) — do not double-call store.clean.
                onClean()
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 2) {
                    inventoryGlyph(item)
                    if item.isFood || item.isCare {
                        Text("×\(item.quantity)")
                            .font(.system(size: 9, weight: .bold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 52, height: 52)
                .background(Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isFavorite ? favoriteGold : cellBorder, lineWidth: isFavorite ? 2.5 : 2)
                )

                if isFavorite {
                    Image("prop-star")
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.name)
        .disabled(item.isFood && item.quantity <= 0)
    }
}
