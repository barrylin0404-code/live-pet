import AVFoundation
import Foundation

/// Shared SFX for Live Pet (main app target only — not the widget extension).
///
/// Eng API — call from care / ball / Island hooks (MainActor-safe; failures ignored):
/// ```
/// PetSound.shared.play(.uiTick)      // crisp tick on button presses
/// PetSound.shared.play(.eatCrunch)   // rapid 3-beat munch on feed consume
/// PetSound.shared.play(.meow)        // happy meow with floating heart / Island ambient
/// PetSound.shared.play(.ballBoing)   // cartoon spring when user taps ball
/// PetSound.shared.play(.heartPop)    // short pop with heart feedback
/// PetSound.shared.play(.play)        // play game start / playDefault
/// PetSound.shared.play(.pet)         // petting / pet tap soft
/// PetSound.shared.play(.ballHit)     // pet hits ball / catch orb
/// PetSound.shared.play(.sleep)       // tuck-in
/// PetSound.shared.play(.clean)       // clean / bubbles
/// PetSound.shared.play(.islandStart) // Live Activity start
/// PetSound.shared.isEnabled          // App Group livepet.v1.sfxEnabled (default true)
/// ```
/// AVAudioSession category `.ambient` so SFX mixes with Music.
///
/// Island ambient meow: schedule from the main app while the Live Activity is active
/// (`PetLiveActivityManager`). ActivityKit widget extensions cannot reliably play
/// AVAudioPlayer — do not call PetSound from LivePetWidget.
enum PetSoundEvent: String, CaseIterable {
    /// Crisp high-pitched UI tick (button presses).
    case uiTick
    /// Rapid 3-beat munch on feed consume.
    case eatCrunch
    /// Happy meow (heart / Island ambient).
    case meow
    /// Cartoon spring boing when user taps ball.
    case ballBoing
    /// Short pop with floating heart.
    case heartPop
    case play
    case pet
    case ballHit
    case sleep
    case clean
    case islandStart

    // Eng / ContentView compatibility aliases (same CAF as primary cases).
    case uiTap
    case feed
    case ballBounce
    case heart

    var fileName: String {
        switch self {
        case .uiTick, .uiTap: return "sfx_ui_tick"
        case .eatCrunch, .feed: return "sfx_eat_crunch"
        case .meow: return "sfx_meow"
        case .ballBoing, .ballBounce: return "sfx_ball_boing"
        case .heartPop, .heart: return "sfx_heart_pop"
        case .play: return "sfx_play"
        case .pet: return "sfx_pet"
        case .ballHit: return "sfx_ball_hit"
        case .sleep: return "sfx_sleep"
        case .clean: return "sfx_clean"
        case .islandStart: return "sfx_island_start"
        }
    }
}

@MainActor
final class PetSound {
    static let shared = PetSound()

    private static let enabledKey = "livepet.v1.sfxEnabled"
    private var players: [PetSoundEvent: AVAudioPlayer] = [:]
    private var didConfigureSession = false

    var isEnabled: Bool {
        get {
            let defaults = AppGroup.defaults
            if defaults.object(forKey: Self.enabledKey) == nil { return true }
            return defaults.bool(forKey: Self.enabledKey)
        }
        set {
            AppGroup.defaults.set(newValue, forKey: Self.enabledKey)
        }
    }

    private init() {
        preload()
    }

    func play(_ event: PetSoundEvent) {
        guard isEnabled else { return }
        configureSessionIfNeeded()
        guard let player = players[event] else { return }
        player.currentTime = 0
        player.play()
    }

    private func configureSessionIfNeeded() {
        guard !didConfigureSession else { return }
        didConfigureSession = true
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            // Best-effort polish — ignore session failures.
        }
    }

    private func preload() {
        for event in PetSoundEvent.allCases {
            guard let url = Bundle.main.url(forResource: event.fileName, withExtension: "caf")
                    ?? Bundle.main.url(forResource: event.fileName, withExtension: "wav") else {
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = 0.85
                players[event] = player
            } catch {
                // Missing / corrupt asset — skip quietly.
            }
        }
    }
}
