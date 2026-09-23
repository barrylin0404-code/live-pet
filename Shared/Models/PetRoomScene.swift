import Foundation

/// In-app room backdrop. Widget / Island stay pet-forward and ignore scene.
/// Wave 2 ids preserved (`sunNook`, `moonPorch`); Wave 3 adds Tide Glass + Skyline Dusk.
public enum PetRoomScene: String, Codable, CaseIterable, Identifiable, Sendable {
    case sunNook
    case moonPorch
    case tideGlass = "tide_glass"
    case skylineDusk = "skyline_dusk"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sunNook: return "Sun Nook"
        case .moonPorch: return "Moon Porch"
        case .tideGlass: return "Tide Glass"
        case .skylineDusk: return "Skyline Dusk"
        }
    }
}
