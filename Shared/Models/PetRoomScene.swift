import Foundation

/// In-app room backdrop. Widget / Island stay pet-forward and ignore scene.
public enum PetRoomScene: String, Codable, CaseIterable, Identifiable, Sendable {
    case sunNook
    case moonPorch

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sunNook: return "Sun Nook"
        case .moonPorch: return "Moon Porch"
        }
    }
}
