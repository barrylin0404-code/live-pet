import Foundation

/// Nubby growth line. User copy: Grow / All grown — never "Evolve".
public enum GrowthStage: String, Codable, Hashable, CaseIterable, Sendable {
    case kit
    case nubby
    case nubbyPlus = "nubby_plus"

    public var displayName: String {
        switch self {
        case .kit: return "Little Nubby"
        case .nubby: return "Nubby"
        case .nubbyPlus: return "Big Nubby"
        }
    }

    /// Visual scale fallback when stage sheets are missing (~72% kit, slight bump for plus).
    public var bodyScaleMultiplier: Double {
        switch self {
        case .kit: return 0.72
        case .nubby: return 1.0
        case .nubbyPlus: return 1.08
        }
    }

    public var next: GrowthStage? {
        switch self {
        case .kit: return .nubby
        case .nubby: return .nubbyPlus
        case .nubbyPlus: return nil
        }
    }
}
