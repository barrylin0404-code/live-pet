import ActivityKit
import AppIntents
import Foundation
import WidgetKit

/// Shared mutators for Dynamic Island Live Activity intents (iOS 17+).
/// Reads/writes App Group pet + inventory, then `Activity.update` with the right pose.
@available(iOS 17.0, iOSApplicationExtension 17.0, *)
enum PetIntentMutator {
    /// Island Feed serves the active pet's favorite (Nubby fish, Pip berry) — same free
    /// auto-refill as the app ribbon, so the Island never shows a "restocked" chore.
    static func feed() async {
        var pet = loadPet() ?? Pet()
        var items = loadItems()
        let favoriteIndex = items.firstIndex(where: { $0.isFood && $0.id == pet.favoriteFoodId })
        if let index = favoriteIndex ?? items.firstIndex(where: { $0.isFood && $0.pixelSpriteName != nil }) {
            let item = items[index]
            items[index].quantity = max(98, items[index].quantity)
            pet.feed(with: item)
        } else if let fallback = InventoryItem.catalog.first(where: { $0.id == pet.favoriteFoodId })
                    ?? InventoryItem.catalog.first(where: \.isFood) {
            pet.feed(with: fallback)
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

    /// Catch up time away first — an Island tap must not stamp `lastUpdated` and erase the
    /// decay the app would have applied on return.
    private static func loadPet() -> Pet? {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.petKey),
              var pet = try? JSONDecoder().decode(Pet.self, from: data) else { return nil }
        pet.applyOfflineDecay()
        return pet
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
        // Mirror into the roster too — cold launch picks the active pet out of `petsKey`.
        if let data = AppGroup.defaults.data(forKey: AppGroup.petsKey),
           var roster = try? JSONDecoder().decode([Pet].self, from: data),
           let idx = roster.firstIndex(where: { $0.id == pet.id }) {
            roster[idx] = pet
            if let out = try? JSONEncoder().encode(roster) {
                AppGroup.defaults.set(out, forKey: AppGroup.petsKey)
            }
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
    static var title: LocalizedStringResource = "Sleep"
    static var description = IntentDescription("Tuck your pet in from the Dynamic Island.")

    func perform() async throws -> some IntentResult {
        await PetIntentMutator.lull()
        return .result()
    }
}
