import SwiftUI
/// Feeling / Satiety / age card — shown in Scenes (More), not over the room plate.
struct StatusStripView: View {
    let pet: Pet

    // Cream card chrome — same family as Scenes / Shop / Inventory sheets (not mint LCD).
    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    private let creamBorder = Color(red: 0xE8 / 255.0, green: 0xD4 / 255.0, blue: 0xC4 / 255.0)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let ageInk = Color(red: 0.55, green: 0.45, blue: 0.33)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .padding(14)
        .background(Color.clear, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(creamBorder, lineWidth: 2)
        )
    }

    private var avatar: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 6.0)) { context in
            let frame = Int(context.date.timeIntervalSinceReferenceDate * 6)
            ClipPetView(
                speciesId: pet.petGlyph,
                anim: pet.isSleeping ? .sleeping : .idle,
                frame: frame,
                facingLeft: false,
                displaySize: 36,
                growthStage: pet.growthStage
            )
        }
    }

    /// Empty hearts when Feeling is 0 — never force a partial fill at rock bottom.
    private var filledHearts: Int {
        switch pet.moodScore {
        case 75...100: return 4
        case 50..<75: return 3
        case 25..<50: return 2
        case 1..<25: return 1
        case 0: return 0
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
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { i in
                PixelHeartView(filled: i < filledHearts, size: 18)
            }
        }
    }

    private var satietyRow: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Image(i < filledSatiety ? "satiety-bowl-full" : "satiety-bowl-empty")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }
        }
    }
}
