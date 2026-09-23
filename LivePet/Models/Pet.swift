import Foundation
import SwiftUI

/// In-app pet state mirrored into the Live Activity content state.
struct Pet: Identifiable, Equatable {
    let id: UUID
    var name: String
    var speciesEmoji: String
    var mood: PetMood
    var hunger: Int
    var energy: Int
    var lastAction: String

    init(
        id: UUID = UUID(),
        name: String = "Pixel",
        speciesEmoji: String = "🐱",
        mood: PetMood = .happy,
        hunger: Int = 40,
        energy: Int = 80,
        lastAction: String = "Ready to play"
    ) {
        self.id = id
        self.name = name
        self.speciesEmoji = speciesEmoji
        self.mood = mood
        self.hunger = max(0, min(100, hunger))
        self.energy = max(0, min(100, energy))
        self.lastAction = lastAction
    }

    var activityState: PetActivityAttributes.ContentState {
        .init(
            mood: mood,
            hunger: hunger,
            energy: energy,
            lastAction: lastAction
        )
    }

    mutating func feed() {
        hunger = max(0, hunger - 25)
        energy = min(100, energy + 5)
        mood = hunger < 30 ? .happy : .content
        lastAction = "Fed \(name)"
    }

    mutating func play() {
        energy = max(0, energy - 15)
        hunger = min(100, hunger + 10)
        mood = energy > 20 ? .playful : .sleepy
        lastAction = "Played with \(name)"
    }

    mutating func rest() {
        energy = min(100, energy + 30)
        mood = energy > 70 ? .content : .sleepy
        lastAction = "\(name) rested"
    }

    mutating func tick() {
        hunger = min(100, hunger + 2)
        energy = max(0, energy - 1)
        if hunger > 70 {
            mood = .hungry
        } else if energy < 25 {
            mood = .sleepy
        } else if mood == .hungry || mood == .sleepy {
            mood = .content
        }
        lastAction = "\(name) is hanging out"
    }
}
