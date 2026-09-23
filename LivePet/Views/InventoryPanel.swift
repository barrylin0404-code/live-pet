import SwiftUI

struct InventoryPanel: View {
    @ObservedObject var store: PetStore
    var onChanged: () -> Void

    private let favoriteGold = Color(red: 0xE8 / 255.0, green: 0xC5 / 255.0, blue: 0x47 / 255.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Inventory")
                .font(.headline)

            Text("Food")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(store.foods) { item in
                    InventoryButton(
                        item: item,
                        tint: .orange,
                        isFavorite: store.pet.isFavoriteFood(item.id),
                        favoriteGold: favoriteGold
                    ) {
                        store.feed(itemID: item.id)
                        onChanged()
                    }
                    .disabled(item.quantity <= 0)
                }
            }

            Text("Toys")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(store.toys) { item in
                    InventoryButton(
                        item: item,
                        tint: .indigo,
                        showQuantity: false,
                        isFavorite: store.pet.isFavoriteToy(item.id),
                        favoriteGold: favoriteGold
                    ) {
                        store.play(itemID: item.id)
                        onChanged()
                    }
                }
            }

            if !store.careItems.isEmpty {
                Text("Care")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Soap is optional — Clean on Pet Home always works free.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(store.careItems) { item in
                        InventoryButton(item: item, tint: .cyan, favoriteGold: favoriteGold) {
                            store.clean()
                            onChanged()
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct InventoryButton: View {
    let item: InventoryItem
    var tint: Color
    var showQuantity: Bool = true
    var isFavorite: Bool = false
    var favoriteGold: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.symbolName)
                        .font(.title3)
                        .foregroundStyle(tint)
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(favoriteGold)
                            .offset(x: 6, y: -4)
                    }
                }
                Text(item.name)
                    .font(.caption2)
                    .lineLimit(1)
                if showQuantity {
                    Text("×\(item.quantity)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isFavorite ? favoriteGold : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.bordered)
    }
}
