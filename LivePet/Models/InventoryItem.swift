import Foundation
import SwiftUI

enum InventoryCategory: String, Codable, CaseIterable {
    case food
    case toy
}

/// Catalog + owned count for a single inventory item.
struct InventoryItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var name: String
    var category: InventoryCategory
    var symbolName: String
    var quantity: Int
    /// How much satiety this food restores (foods only).
    var satietyBoost: Int
    /// How much mood this toy restores (toys only).
    var moodBoost: Int
    /// Energy cost to use (toys cost energy; foods may restore a little).
    var energyDelta: Int

    var isFood: Bool { category == .food }
    var isToy: Bool { category == .toy }

    static let catalog: [InventoryItem] = [
        InventoryItem(
            id: "crumb_cake",
            name: "Crumb Cake",
            category: .food,
            symbolName: "cup.and.saucer.fill",
            quantity: 3,
            satietyBoost: 28,
            moodBoost: 4,
            energyDelta: 2
        ),
        InventoryItem(
            id: "berry_cube",
            name: "Berry Cube",
            category: .food,
            symbolName: "cube.fill",
            quantity: 2,
            satietyBoost: 18,
            moodBoost: 8,
            energyDelta: 0
        ),
        InventoryItem(
            id: "glow_pellet",
            name: "Glow Pellet",
            category: .food,
            symbolName: "circle.hexagongrid.fill",
            quantity: 2,
            satietyBoost: 12,
            moodBoost: 12,
            energyDelta: 4
        ),
        InventoryItem(
            id: "bounce_block",
            name: "Bounce Block",
            category: .toy,
            symbolName: "square.fill",
            quantity: 1,
            satietyBoost: 0,
            moodBoost: 22,
            energyDelta: -12
        ),
        InventoryItem(
            id: "twinkle_ball",
            name: "Twinkle Ball",
            category: .toy,
            symbolName: "circle.fill",
            quantity: 1,
            satietyBoost: 0,
            moodBoost: 18,
            energyDelta: -10
        ),
        InventoryItem(
            id: "soft_square",
            name: "Soft Square",
            category: .toy,
            symbolName: "seal.fill",
            quantity: 1,
            satietyBoost: 0,
            moodBoost: 14,
            energyDelta: -6
        )
    ]
}
