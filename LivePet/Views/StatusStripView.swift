import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Premium Feeling hearts + Satiety slots + age — Wave 1 Reviewer gate / 08-premium-chrome.
struct StatusStripView: View {
    let pet: Pet

    private let mint = Color(red: 0.91, green: 0.96, blue: 0.89)
    private let mintBorder = Color(red: 0.77, green: 0.85, blue: 0.75)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let ageInk = Color(red: 0.55, green: 0.45, blue: 0.33)
    private let heartFill = Color(red: 1.0, green: 0.30, blue: 0.43)
    private let heartEmpty = Color(red: 1.0, green: 0.70, blue: 0.76)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                avatar
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(pet.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(ink)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text("\(pet.ageDays) DAYS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ageInk)
                    .accessibilityLabel("\(pet.ageDays) days old")
            }

            HStack(spacing: 8) {
                Text("Feeling")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ink)
                    .frame(width: 52, alignment: .leading)
                heartRow
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Feeling, \(pet.moodScore) percent, \(filledHearts) of 4 hearts")

            HStack(spacing: 8) {
                Text("Satiety")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ink)
                    .frame(width: 52, alignment: .leading)
                satietyRow
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Satiety, \(pet.satiety) percent, \(filledSatiety) of 3")
        }
        .padding(12)
        .background(mint.opacity(0.95), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(mintBorder, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var avatar: some View {
        #if canImport(UIKit)
        let avatar = PetSprite.avatarName(speciesId: pet.petGlyph, growthStage: pet.growthStage)
        if UIImage(named: avatar) != nil {
            Image(avatar)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            AnimatedPixelPetView(
                mood: pet.mood,
                pose: pet.pose,
                isSleeping: pet.isSleeping,
                speciesId: pet.petGlyph,
                growthStage: pet.growthStage,
                scale: 0.38
            )
        }
        #else
        AnimatedPixelPetView(
            mood: pet.mood,
            pose: pet.pose,
            isSleeping: pet.isSleeping,
            speciesId: pet.petGlyph,
                growthStage: pet.growthStage,
                scale: 0.38
        )
        #endif
    }

    private var filledHearts: Int {
        switch pet.moodScore {
        case 75...100: return 4
        case 50..<75: return 3
        case 25..<50: return 2
        case 1..<25: return 1
        default: return 0
        }
    }

    private var filledSatiety: Int {
        switch pet.satiety {
        case 67...100: return 3
        case 34..<67: return 2
        case 1..<34: return 1
        default: return 0
        }
    }

    private var heartRow: some View {
        HStack(spacing: 5) {
            ForEach(0..<4, id: \.self) { i in
                Image(systemName: i < filledHearts ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundStyle(i < filledHearts ? heartFill : heartEmpty)
            }
        }
    }

    private var satietyRow: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i < filledSatiety ? Color.orange : Color.orange.opacity(0.25))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.orange.opacity(0.55), lineWidth: 1.5)
                    )
            }
        }
    }
}
