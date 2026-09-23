import SwiftUI

struct InventoryPanel: View {
    @ObservedObject var store: PetStore
    var onChanged: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Inventory")
                .font(.headline)

            Text("Food")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(store.foods) { item in
                    InventoryButton(item: item, tint: .orange) {
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
                    InventoryButton(item: item, tint: .indigo, showQuantity: false) {
                        store.play(itemID: item.id)
                        onChanged()
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: item.symbolName)
                    .font(.title3)
                    .foregroundStyle(tint)
                Text(item.name)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                if showQuantity {
                    Text("×\(item.quantity)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("Use")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.bordered)
    }
}
