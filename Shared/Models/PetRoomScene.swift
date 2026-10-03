import Foundation

/// In-app room backdrop. Widget / Island stay pet-forward and ignore scene.
/// Wave 2–3 indoor ids preserved; pass 18 adds Meadow Walk (+ Snow/Coral stubs).
public enum PetRoomScene: String, Codable, CaseIterable, Identifiable, Sendable {
    case sunNook
    case moonPorch
    case tideGlass = "tide_glass"
    case skylineDusk = "skyline_dusk"
    case meadowWalk = "meadow_walk"
    /// Placeholder — Holiday outdoor; not in sheet until art ships.
    case snowPorch = "snow_porch"
    /// Placeholder — clearer water / undersea; not in sheet until art ships.
    case coralShelf = "coral_shelf"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sunNook: return "Sun Nook"
        case .moonPorch: return "Moon Porch"
        case .tideGlass: return "Tide Glass"
        case .skylineDusk: return "Skyline Dusk"
        case .meadowWalk: return "Meadow Walk"
        case .snowPorch: return "Snow Porch"
        case .coralShelf: return "Coral Shelf"
        }
    }

    /// Free day-1 scenes shown in the Scenes sheet. Stubs stay false until designed.
    public var isAvailable: Bool {
        switch self {
        case .sunNook, .moonPorch, .tideGlass, .skylineDusk, .meadowWalk, .snowPorch, .coralShelf:
            return true
        }
    }

    /// Scenes sheet 2×3 order: Sun | Moon | Meadow / Tide | Skyline | (empty).
    public static var availableInDisplayOrder: [PetRoomScene] {
        [.sunNook, .moonPorch, .meadowWalk, .tideGlass, .skylineDusk, .snowPorch, .coralShelf]
    }

    /// Pet feet Y as fraction of room height. Meadow sits slightly higher (outdoor path).
    public var petFeetYFraction: Double {
        switch self {
        case .meadowWalk: return 0.58
        default: return 0.62
        }
    }

    /// Pixel plate for this room. Each room uses its own plate.
    public var plateImageName: String? {
        switch self {
        case .sunNook: return "sun-nook-plate"
        case .moonPorch: return "moon-porch-plate"
        case .tideGlass: return "tide-glass-plate"
        case .skylineDusk: return "skyline-dusk-plate"
        case .meadowWalk: return "meadow-walk-plate"
        case .snowPorch: return "snow-porch-plate"
        case .coralShelf: return "coral-shelf-plate"
        }
    }

    /// Optional Assets.xcassets thumb (nearest-neighbor at display time).
    public var thumbImageName: String? {
        switch self {
        case .meadowWalk: return "thumb-meadow-walk"
        default: return nil
        }
    }
}
