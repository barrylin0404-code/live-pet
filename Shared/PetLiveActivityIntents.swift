import ActivityKit
import AppIntents
import Foundation
import WidgetKit

/// Shared mutators for Dynamic Island Live Activity intents (iOS 17+).
/// Reads/writes App Group pet + inventory, then `Activity.update` with the right pose.
@available(iOS 17.0, iOSApplicationExtension 17.0, *)
enum PetIntentMutator {
    static func feed() async {
        var pet = loadPet() ?? Pet()
        var items = loadItems()
        if let index = items.firstIndex(where: { $0.isFood && $0.quantity > 0 }) {
            let item = items[index]
            items[index].quantity -= 1
            pet.feed(with: item)
            if items[index].quantity == 0 {
                items[index].quantity = 1
                pet.lastAction = "Ate \(item.name) · crumb restocked"
                pet.touch()
            }
        } else if let fallback = InventoryItem.catalog.first(where: \.isFood) {
            pet.feed(with: fallback)
        } else {
            pet.isSleeping = false
            pet.pose = .eat
            pet.satiety = min(100, pet.satiety + 20)
            pet.moodScore = min(100, pet.moodScore + 4)
            pet.lastAction = "Ate a snack"
            pet.touch()
        }
        persist(pet: pet, items: items)
        await pushActivity(pet: pet)
    }

    /// Play-lite Feeling bump (Island “Pet”).
    static func pet() async {
        var model = loadPet() ?? Pet()
        model.pet()
        persist(pet: model, items: nil)
        await pushActivity(pet: model)
    }

    /// Sleep / tuck-in (Island “Lull”).
    static func lull() async {
        var model = loadPet() ?? Pet()
        model.sleep()
        persist(pet: model, items: nil)
        await pushActivity(pet: model)
    }

    private static func loadPet() -> Pet? {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.petKey) else { return nil }
        return try? JSONDecoder().decode(Pet.self, from: data)
    }

    private static func loadItems() -> [InventoryItem] {
        if let data = AppGroup.defaults.data(forKey: AppGroup.inventoryKey),
           let saved = try? JSONDecoder().decode([InventoryItem].self, from: data) {
            return saved
        }
        return InventoryItem.catalog
    }

    private static func persist(pet: Pet, items: [InventoryItem]?) {
        if let data = try? JSONEncoder().encode(pet) {
            AppGroup.defaults.set(data, forKey: AppGroup.petKey)
        }
        if let items, let data = try? JSONEncoder().encode(items) {
            AppGroup.defaults.set(data, forKey: AppGroup.inventoryKey)
        }
        PetSnapshot(
            name: pet.name,
            petGlyph: pet.petGlyph,
            moodScore: pet.moodScore,
            satiety: pet.satiety,
            energy: pet.energy,
            moodRaw: pet.mood.rawValue,
            lastAction: pet.lastAction,
            lastUpdated: pet.lastUpdated,
            growthStage: pet.growthStage.rawValue,
            isSleeping: pet.isSleeping
        ).save()
    }

    private static func pushActivity(pet: Pet) async {
        let state = pet.activityState
        for activity in Activity<PetActivityAttributes>.activities {
            let stale = Date().addingTimeInterval(8 * 60 * 60)
            let content = ActivityContent(state: state, staleDate: stale)
            await activity.update(content)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
struct FeedPetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Feed"
    static var description = IntentDescription("Feed your pet from the Dynamic Island.")

    func perform() async throws -> some IntentResult {
        await PetIntentMutator.feed()
        return .result()
    }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
struct PetPetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pet"
    static var description = IntentDescription("Give a quick Feeling boost from the Dynamic Island.")

    func perform() async throws -> some IntentResult {
        await PetIntentMutator.pet()
        return .result()
    }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
struct LullPetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Lull"
    static var description = IntentDescription("Tuck your pet in from the Dynamic Island.")

    func perform() async throws -> some IntentResult {
        await PetIntentMutator.lull()
        return .result()
    }
}
