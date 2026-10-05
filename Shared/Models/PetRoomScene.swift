import Foundation

/// In-app room backdrop. Widget / Island stay pet-forward and ignore scene.
/// Wave 2–3 indoor ids preserved; Meadow Walk, Snow Porch, and Coral Shelf ship with plates.
public enum PetRoomScene: String, Codable, CaseIterable, Identifiable, Sendable {
    case sunNook
    case moonPorch
    case tideGlass = "tide_glass"
    case skylineDusk = "skyline_dusk"
    case meadowWalk = "meadow_walk"
    /// Holiday outdoor — snow-porch-plate.
    case snowPorch = "snow_porch"
    /// Clearer water / undersea — coral-shelf-plate.
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

    /// Free day-1 scenes shown in the Scenes sheet (all seven plates available).
    public var isAvailable: Bool {
        switch self {
        case .sunNook, .moonPorch, .tideGlass, .skylineDusk, .meadowWalk, .snowPorch, .coralShelf:
            return true
        }
    }

    /// Scenes sheet order: Sun | Moon | Meadow / Tide | Skyline | Snow / Coral.
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

    /// Ball rests just below the pet centerline so Meadow (~58%) and indoor (~62%) match.
    public var ballFloorYFraction: Double { petFeetYFraction + 0.08 }

    /// Walk / scoot speed multiplier for room roam (1 = Sun Nook). Meadow is denser; night and cold are calmer.
    public var roamPace: Double {
        switch self {
        case .meadowWalk: return 1.28
        case .tideGlass, .coralShelf: return 0.92
        case .moonPorch, .skylineDusk, .snowPorch: return 0.84
        case .sunNook: return 1.0
        }
    }

    /// Idle park linger after a short walk (1 = Sun Nook). Calm scenes rest longer between scoots.
    public var roamIdleHold: Double {
        switch self {
        case .meadowWalk: return 0.78
        case .tideGlass, .coralShelf: return 1.08
        case .moonPorch, .skylineDusk, .snowPorch: return 1.22
        case .sunNook: return 1.0
        }
    }

    /// Where a tired pet walks to nap (x fraction of the room), read off each plate:
    /// the sofa indoors, the rug where there is no sofa, the door on the porch, open sand undersea.
    public var restXFraction: Double {
        switch self {
        case .sunNook: return 0.39      // red sofa
        case .moonPorch: return 0.42    // violet sofa
        case .meadowWalk: return 0.28   // by the fence
        case .tideGlass: return 0.74    // rug under the porthole
        case .skylineDusk: return 0.52  // rug below the window
        case .snowPorch: return 0.26    // by the door
        case .coralShelf: return 0.50   // open sand between the kelp
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

    /// Assets.xcassets thumb. Meadow has a dedicated crop; others use the room plate.
    public var thumbImageName: String? {
        switch self {
        case .meadowWalk: return "thumb-meadow-walk"
        default: return plateImageName
        }
    }
}
