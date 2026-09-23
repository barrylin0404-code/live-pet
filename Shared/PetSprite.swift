import Foundation

enum PetSprite {
    static func avatarName(speciesId: String, growthStage: GrowthStage) -> String {
        if speciesId == "pip" { return "pip-idle-0" }
        switch growthStage {
        case .kit: return "nubby-kit-idle-0"
        case .nubbyPlus: return "nubby-nubby_plus-idle-0"
        case .nubby: return "nubby-idle-0"
        }
    }

    static func lockMonoName(speciesId: String, growthStage: GrowthStage, compact: Bool) -> String {
        if speciesId == "pip" {
            return compact ? "lock-pip-mono-compact" : "lock-pip-mono"
        }
        if growthStage == .nubbyPlus {
            return compact ? "lock-nubby-plus-mono-compact" : "lock-nubby-plus-mono"
        }
        return compact ? "lock-nubby-mono-compact" : "lock-nubby-mono"
    }

    static func islandCropName(speciesId: String, growthStage: GrowthStage) -> String {
        if speciesId == "pip" { return "island-pip-compact" }
        if growthStage == .nubbyPlus { return "island-nubby-plus-compact" }
        return "island-compact-crop"
    }
}
