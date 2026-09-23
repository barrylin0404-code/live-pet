import Foundation
import SwiftUI

enum InventoryCategory: String, Codable, CaseIterable {
    case food
    case toy
    case care
}

/// Catalog + owned count for a single inventory item.
struct InventoryItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var name: String
    var category: InventoryCategory
    var symbolName: String
    var quantity: Int
    var satietyBoost: Int
    var moodBoost: Int
    var energyDelta: Int

    var isFood: Bool { category == .food }
    var isToy: Bool { category == .toy }
    var isCare: Bool { category == .care }

    /// Free forever — food auto-refills; toys are reusable; no IAP / rate-gate.
    static let catalog: [InventoryItem] = [
        // Food set from 14-video-parity-chrome (auto-refill)
        InventoryItem(id: "sprout", name: "Sprout", category: .food, symbolName: "leaf.fill", quantity: 99, satietyBoost: 16, moodBoost: 6, energyDelta: 2),
        InventoryItem(id: "cherries", name: "Cherries", category: .food, symbolName: "carrot.fill", quantity: 99, satietyBoost: 18, moodBoost: 8, energyDelta: 1),
        InventoryItem(id: "cupcake", name: "Cupcake", category: .food, symbolName: "cup.and.saucer.fill", quantity: 99, satietyBoost: 24, moodBoost: 10, energyDelta: 2),
        InventoryItem(id: "fish", name: "Fish", category: .food, symbolName: "fish.fill", quantity: 99, satietyBoost: 22, moodBoost: 6, energyDelta: 2),
        InventoryItem(id: "biscuit", name: "Biscuit", category: .food, symbolName: "circle.fill", quantity: 99, satietyBoost: 20, moodBoost: 5, energyDelta: 1),
        InventoryItem(id: "berry", name: "Berry", category: .food, symbolName: "circle.hexagongrid.fill", quantity: 99, satietyBoost: 14, moodBoost: 12, energyDelta: 0),
        // Toys
        InventoryItem(id: "bounce_block", name: "Bounce Block", category: .toy, symbolName: "square.fill", quantity: 1, satietyBoost: 0, moodBoost: 22, energyDelta: -12),
        InventoryItem(id: "twinkle_ball", name: "Twinkle Ball", category: .toy, symbolName: "circle.fill", quantity: 1, satietyBoost: 0, moodBoost: 18, energyDelta: -10),
        InventoryItem(id: "soft_square", name: "Soft Square", category: .toy, symbolName: "seal.fill", quantity: 1, satietyBoost: 0, moodBoost: 14, energyDelta: -6),
        // Care
        InventoryItem(id: "bubble_soap", name: "Bubble Soap", category: .care, symbolName: "drop.fill", quantity: 2, satietyBoost: 0, moodBoost: 2, energyDelta: 0)
    ]
}
