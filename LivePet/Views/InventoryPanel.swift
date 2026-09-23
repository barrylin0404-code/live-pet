import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Always-visible horizontal inventory ribbon — 13-playable-home (≥4 cells).
struct InventoryPanel: View {
    @ObservedObject var store: PetStore
    var onFeed: () -> Void
    var onPlay: () -> Void
    var onClean: () -> Void

    private let favoriteGold = Color(red: 0xE8 / 255.0, green: 0xC5 / 255.0, blue: 0x47 / 255.0)
    private let cellBorder = Color(red: 0xE8 / 255.0, green: 0xD4 / 255.0, blue: 0xC4 / 255.0)

    private var ribbonItems: [InventoryItem] {
        var list: [InventoryItem] = []
        list.append(contentsOf: store.foods)
        list.append(contentsOf: store.toys)
        list.append(contentsOf: store.careItems)
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

    @ViewBuilder
    private func ribbonCell(_ item: InventoryItem) -> some View {
        let isFavorite = item.isFood
            ? store.pet.isFavoriteFood(item.id)
            : (item.isToy ? store.pet.isFavoriteToy(item.id) : false)
        let tint: Color = item.isFood ? .orange : (item.isToy ? Color(red: 0.45, green: 0.55, blue: 0.90) : .cyan)

        Button {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            if item.isFood {
                store.feed(itemID: item.id)
                onFeed()
            } else if item.isToy {
                store.play(itemID: item.id)
                onPlay()
            } else {
                store.clean()
                onClean()
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 2) {
                    Image(systemName: item.symbolName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(tint)
                    if item.isFood || item.isCare {
                        Text("×\(item.quantity)")
                            .font(.system(size: 9, weight: .bold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 52, height: 52)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isFavorite ? favoriteGold : cellBorder, lineWidth: isFavorite ? 2.5 : 2)
                )

                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(favoriteGold)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.name)
        .disabled(item.isFood && item.quantity <= 0)
    }
}
