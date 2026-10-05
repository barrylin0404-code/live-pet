import Foundation

/// Autonomous pet. Picks clips and walks. Views only render `x` and `player`.
public struct PetBrain: Equatable {
    public var x: CGFloat
    public var player: PetAnimPlayer
    public private(set) var foodX: CGFloat?
    public private(set) var feedReady: Bool
    public private(set) var napReady: Bool
    public private(set) var toyX: CGFloat?
    public private(set) var playReady: Bool

    private var wanderTarget: CGFloat?
    private var idleHold: Double
    private var commandedUntil: Double
    private var clock: Double
    private var moodHint: PetMood
    private var wasSleeping: Bool
    private var sleepPhase: Double
    private var toyPlayLeft: Double
    /// Taps inside a short window — 3+ → annoyed (sad sheet).
    private var petBurstCount: Int
    private var petBurstUntil: Double

    public init(x: CGFloat = 0.48) {
        self.x = x
        self.player = PetAnimPlayer(anim: .idle)
        self.foodX = nil
        self.feedReady = false
        self.napReady = false
        self.toyX = nil
        self.playReady = false
        self.wanderTarget = nil
        self.idleHold = 0.6
        self.commandedUntil = 0
        self.clock = 0
        self.moodHint = .content
        self.wasSleeping = false
        self.sleepPhase = 0
        self.toyPlayLeft = 0
        self.petBurstCount = 0
        self.petBurstUntil = 0
    }

    /// Drag: pickup, then held while the stroke continues, then drop.
    public mutating func reactGrab() {
        wanderTarget = nil
        if player.anim == .held {
            commandedUntil = max(commandedUntil, clock + 0.5)
            return
        }
        if player.anim != .pickup && player.anim != .drop {
            player.request(.pickup, force: true)
        }
        commandedUntil = max(commandedUntil, clock + 0.85)
    }

    public mutating func noticeFood(at fraction: CGFloat) {
        foodX = min(0.78, max(0.22, fraction))
        feedReady = false
        napReady = false
        toyX = nil
        playReady = false
        wanderTarget = nil
        // Brief eatNotice glance (aliases eat sheets) before walking over.
        player.request(.eatNotice, facingLeft: foodX! < x, force: true)
        commandedUntil = max(commandedUntil, clock + 0.35)
    }

    /// A toy on the floor. The pet walks to it, then plays, same as food.
    public mutating func noticeToy(at fraction: CGFloat) {
        toyX = min(0.78, max(0.22, fraction))
        playReady = false
        toyPlayLeft = 1.15
        napReady = false
        foodX = nil
        feedReady = false
        wanderTarget = nil
        let left = toyX! < x
        player.request(left ? .walkLeft : .walkRight, facingLeft: left, force: true)
    }

    /// Games and the wand set position. Tick will not wander while a hold is active.
    public mutating func hold(_ seconds: Double) {
        commandedUntil = max(commandedUntil, clock + seconds)
        wanderTarget = nil
    }

    /// Move to a point and walk there. Does not restart the walk clip if it is already playing.
    public mutating func place(at fraction: CGFloat, facingLeft: Bool) {
        x = min(0.88, max(0.12, fraction))
        wanderTarget = nil
        let walk: PetAnim = facingLeft ? .walkLeft : .walkRight
        player.request(walk, facingLeft: facingLeft, force: player.anim != walk)
    }

    public mutating func reactPet() {
        if clock > petBurstUntil {
            petBurstCount = 0
        }
        petBurstCount += 1
        petBurstUntil = clock + 1.35
        wanderTarget = nil
        if petBurstCount >= 3 {
            // nubby/pip have sad sheets — annoyedReaction maps there in the catalog.
            player.request(.annoyedReaction, force: true)
            commandedUntil = clock + 1.2
            petBurstCount = 0
            petBurstUntil = clock + 0.8
        } else {
            player.request(.petHappy, force: true)
            commandedUntil = clock + 1.1
        }
    }

    /// Double-tap: jump or curious glance — not another petHappy.
    /// Returns false while a jump or glance is still mid-clip, so it lands instead of
    /// snapping back to frame 0. A fresh double-tap right after landing chains cleanly.
    @discardableResult
    public mutating func reactDoubleTap() -> Bool {
        if (player.anim == .jump || player.anim == .curious),
           !player.finishedOneShot, clock < commandedUntil {
            return false
        }
        wanderTarget = nil
        petBurstCount = 0
        petBurstUntil = clock + 0.6
        if Bool.random() {
            // 5 frames @ 12 fps ≈ 0.42s, then a short landed beat before roaming.
            player.request(.jump, force: true)
            commandedUntil = clock + 0.75
        } else {
            // 6 frames @ 10 fps = 0.6s glance, then a short beat.
            player.request(.curious, force: true)
            commandedUntil = clock + 0.95
        }
        return true
    }

    public mutating func reactPlay() {
        player.request(.playing, force: true)
        commandedUntil = clock + 2.0
        wanderTarget = nil
    }

    public mutating func reactBath() {
        player.request(.bathStart, force: true)
        // Cover bathStart frames; later stages extend commandedUntil / resume below.
        commandedUntil = clock + 0.85
        wanderTarget = nil
        foodX = nil
        toyX = nil
    }

    /// After the Grow celebration closes: one happy beat, then the usual idle linger.
    public mutating func reactGrown() {
        guard !wasSleeping, foodX == nil, toyX == nil else { return }
        wanderTarget = nil
        player.request(.happy, force: true)
        commandedUntil = max(commandedUntil, clock + 1.25)
        idleHold = max(idleHold, 1.0)
    }

    public mutating func reactFavoriteFood() {
        // Burst on the happy sheet — not another eat cycle after the meal.
        player.request(.favoriteFoodReaction, force: true)
        commandedUntil = max(commandedUntil, clock + 1.35)
        idleHold = max(idleHold, 1.0)
        wanderTarget = nil
    }

    public mutating func reactSleep(on: Bool) {
        if on {
            // Start clip first when art exists; playback falls back to idle until sleepStart sheets ship.
            player.request(.sleepStart, force: true)
            wanderTarget = nil
            commandedUntil = clock + 0.9
            sleepPhase = 0
        } else {
            player.request(.wakeUp, force: true)
            commandedUntil = clock + 0.6
        }
    }

    /// True once, when the pet has reached food and finished the eat clip.
    public mutating func consumeFeedReady() -> Bool {
        if feedReady {
            feedReady = false
            foodX = nil
            return true
        }
        return false
    }

    /// True once, when a tired pet has reached the sofa and should be tucked in.
    public mutating func consumeNapReady() -> Bool {
        if napReady {
            napReady = false
            return true
        }
        return false
    }

    /// True once, after the pet has reached a dropped toy and finished playing with it.
    public mutating func consumePlayReady() -> Bool {
        if playReady {
            playReady = false
            toyX = nil
            return true
        }
        return false
    }

    public mutating func tick(dt: Double, sleeping: Bool, mood: PetMood = .content, roamPace: Double = 1.0) {
        moodHint = mood
        let pace = min(1.45, max(0.7, roamPace))
        let dt = min(0.05, max(0, dt))
        clock += dt
        player.advance(dt: dt)

        if sleeping {
            wasSleeping = true
            sleepPhase += dt
            if player.anim == .sleepStart {
                if player.finishedOneShot {
                    player.request(.sleeping, force: true)
                    sleepPhase = 0
                }
                return
            }
            if player.anim != .sleeping && player.anim != .sleepBreathing {
                player.request(.sleeping, force: true)
                sleepPhase = 0
            } else if player.anim == .sleeping && sleepPhase > 2.4 {
                player.request(.sleepBreathing, force: true)
            } else if player.anim == .sleepBreathing && sleepPhase > 5 {
                player.request(.sleeping, force: true)
                sleepPhase = 0
            }
            return
        }
        if wasSleeping {
            wasSleeping = false
            player.request(.wakeUp, force: true)
            commandedUntil = clock + 0.9
            wanderTarget = nil
        }

        if let food = foodX {
            // Hold the notice glance, then walk.
            if player.anim == .eatNotice && !player.finishedOneShot && clock < commandedUntil {
                return
            }
            let dx = food - x
            if abs(dx) > 0.03 {
                let dirLeft = dx < 0
                if player.anim != .walkToFood {
                    player.request(.walkToFood, facingLeft: dirLeft, force: true)
                }
                x += (dirLeft ? -1 : 1) * CGFloat(dt) * 0.16 * CGFloat(pace)
                x = min(0.82, max(0.18, x))
                return
            }
            x = food
            if player.anim != .eating && player.anim != .happy {
                player.request(.eating, force: true)
            } else if player.finishedOneShot && player.anim == .eating {
                feedReady = true
                player.request(.happy, force: true)
                // Linger on happy before tick resumes wander.
                commandedUntil = clock + 1.25
                idleHold = max(idleHold, 1.0)
            }
            return
        }

        if let toy = toyX {
            let dx = toy - x
            if abs(dx) > 0.03 {
                let left = dx < 0
                let walk: PetAnim = left ? .walkLeft : .walkRight
                if player.anim != walk {
                    player.request(walk, facingLeft: left, force: true)
                }
                x += (left ? -1 : 1) * CGFloat(dt) * 0.16 * CGFloat(pace)
                x = min(0.82, max(0.18, x))
                return
            }
            x = toy
            if player.anim != .playing {
                player.request(.playing, force: true)
            }
            toyPlayLeft -= dt
            if toyPlayLeft <= 0 {
                playReady = true
                toyX = nil
                player.request(.happy, force: true)
                // Snappy satisfied beat — resume roam sooner after Bounce / Ball drops.
                commandedUntil = clock + 0.85
                idleHold = max(idleHold, 0.65)
            }
            return
        }

        if clock < commandedUntil {
            if player.finishedOneShot && player.anim == .pickup {
                player.request(.held, force: true)
            } else if player.finishedOneShot && player.anim == .bathStart {
                player.request(.bathing, force: true)
                commandedUntil = clock + 1.6
            } else if player.finishedOneShot && player.anim == .wakeUp {
                player.request(.morningStretch, force: true)
                commandedUntil = clock + 0.8
            } else if player.finishedOneShot && player.anim == .sleepStart {
                player.request(.sleeping, force: true)
                commandedUntil = clock + 8
                sleepPhase = 0
            } else if player.finishedOneShot && player.anim == .wet {
                player.request(.shakeWater, force: true)
                commandedUntil = clock + 0.9
            } else if player.finishedOneShot && player.anim == .shakeWater {
                player.request(.bathHappy, force: true)
                commandedUntil = clock + 0.7
            } else if player.finishedOneShot && (player.anim == .happy
                                                || player.anim == .favoriteFoodReaction
                                                || player.anim == .loveReaction
                                                || player.anim == .bathHappy) {
                // Brief satisfied idle before chooseNext wanders again.
                player.request(.idle, force: true)
                idleHold = max(idleHold, 0.9)
            } else if player.finishedOneShot && player.anim != .held {
                player.request(.idle, force: true)
            }
            return
        }
        if player.anim == .held {
            player.request(.drop, force: true)
            commandedUntil = clock + 0.7
            return
        }
        // Bath chain must finish even if a stage's hold window expired mid-clip.
        // bathStart → bathing → wet → shakeWater → bathHappy → idle (+ idleHold).
        switch player.anim {
        case .bathStart:
            if player.finishedOneShot {
                player.request(.bathing, force: true)
                commandedUntil = clock + 1.6
            } else {
                commandedUntil = clock + 0.2
            }
            return
        case .bathing:
            player.request(.wet, force: true)
            commandedUntil = clock + 0.8
            return
        case .wet:
            if player.finishedOneShot {
                player.request(.shakeWater, force: true)
                commandedUntil = clock + 0.9
            } else {
                commandedUntil = clock + 0.2
            }
            return
        case .shakeWater:
            if player.finishedOneShot {
                player.request(.bathHappy, force: true)
                commandedUntil = clock + 0.7
            } else {
                commandedUntil = clock + 0.2
            }
            return
        case .bathHappy:
            if player.finishedOneShot {
                player.request(.idle, force: true)
                idleHold = max(idleHold, 0.9)
            } else {
                commandedUntil = clock + 0.2
            }
            return
        default:
            break
        }

        // Tired: walk to the sofa, then ask the app to tuck in. Food and care holds win.
        if moodHint == .sleepy, foodX == nil {
            let sofa: CGFloat = 0.39
            let dx = sofa - x
            if abs(dx) > 0.03 {
                let left = dx < 0
                player.request(left ? .walkLeft : .walkRight, facingLeft: left)
                x += (left ? -1 : 1) * CGFloat(dt) * 0.09 * CGFloat(pace)
                x = min(0.80, max(0.20, x))
                return
            }
            x = sofa
            if !napReady {
                napReady = true
                player.request(.idleYawn, force: true)
            }
            return
        }

        let running = player.anim == .runLeft || player.anim == .runRight
        let moving = running || player.anim == .walkRight || player.anim == .walkLeft || player.anim == .walkSlow
        if let target = wanderTarget, moving {
            let dx = target - x
            if abs(dx) < 0.025 {
                wanderTarget = nil
                player.request(.idle, force: true)
                // Shorter park so idle variety / short walks fire sooner (Shimeji density).
                idleHold = Double.random(in: 0.4...1.15)
                return
            }
            let left = dx < 0
            if running {
                player.request(left ? .runLeft : .runRight, facingLeft: left)
                x += (left ? -1 : 1) * CGFloat(dt) * 0.22 * CGFloat(pace)
            } else {
                player.request(left ? .walkLeft : .walkRight, facingLeft: left)
                x += (left ? -1 : 1) * CGFloat(dt) * 0.11 * CGFloat(pace)
            }
            x = min(0.80, max(0.20, x))
            return
        }

        // Low satiety / low mood: show hungry or sad without needing a tap.
        if foodX == nil, toyX == nil, clock >= commandedUntil {
            if moodHint == .hungry, player.anim != .hungry {
                player.request(.hungry, force: true)
                idleHold = 0.55
                wanderTarget = nil
                return
            }
            if moodHint == .low, player.anim != .sad {
                player.request(.sad, force: true)
                idleHold = 0.55
                wanderTarget = nil
                return
            }
        }

        if player.anim == .idle || player.finishedOneShot {
            idleHold -= dt
            if player.finishedOneShot {
                player.request(.idle, force: true)
            }
            if idleHold <= 0 {
                chooseNext()
            }
        }
    }

    /// Only reached after sleep / care / food / toy holds clear — never interrupts those.
    private mutating func chooseNext() {
        switch moodHint {
        case .hungry:
            player.request(.hungry, force: true)
            idleHold = 0.3
            return
        case .low:
            player.request(.sad, force: true)
            idleHold = 0.3
            return
        case .playful:
            // Commercial bar: playful pets scoot then play — not only stand-in-place.
            if Int.random(in: 0..<5) < 3 {
                let delta = CGFloat.random(in: 0.10...0.22) * (Bool.random() ? 1 : -1)
                let target = min(0.76, max(0.24, x + delta))
                wanderTarget = target
                let left = target < x
                if Int.random(in: 0..<3) == 0 {
                    player.request(left ? .runLeft : .runRight, facingLeft: left, force: true)
                } else {
                    player.request(left ? .walkLeft : .walkRight, facingLeft: left, force: true)
                }
                // After the short walk parks, chooseNext will fire playing.
                return
            }
            if Int.random(in: 0..<2) == 0 {
                player.request(.hop, force: true)
                idleHold = 0.08
            } else {
                player.request(.playing, force: true)
                commandedUntil = clock + 1.35
            }
            wanderTarget = nil
            return
        default:
            break
        }
        // ~40% short walks; rest denser idle flavors (blink/stretch/groom/yawn/curious/ear/tail/scratch).
        // Rare stays on idle — do not pick idleRare* here.
        let roll = Int.random(in: 0..<20)
        if roll < 8 {
            let delta = CGFloat.random(in: 0.07...0.20) * (Bool.random() ? 1 : -1)
            let target = min(0.76, max(0.24, x + delta))
            wanderTarget = target
            let left = target < x
            // Mostly walk; occasional short run.
            if Int.random(in: 0..<5) == 0 {
                player.request(left ? .runLeft : .runRight, facingLeft: left, force: true)
            } else {
                player.request(left ? .walkLeft : .walkRight, facingLeft: left, force: true)
            }
        } else if roll < 11 {
            player.request(.idleBlink, force: true)
            idleHold = 0.32
        } else if roll < 13 {
            player.request(Bool.random() ? .idleYawn : .idleStretch, force: true)
            idleHold = 0.12
        } else if roll < 15 {
            player.request(Bool.random() ? .idleGroom : .idleScratch, force: true)
            idleHold = 0.12
        } else if roll < 17 {
            let fidgets: [PetAnim] = [.idleEarMovement, .idleTailMovement, .idleCurious]
            player.request(fidgets.randomElement() ?? .idleCurious, force: true)
            idleHold = 0.12
        } else if roll < 18 {
            let looks: [PetAnim] = [.idleLookLeft, .idleLookRight, .idleLookUp, .idleLookDown]
            player.request(looks.randomElement() ?? .idleLookLeft, force: true)
            idleHold = 0.4
        } else if roll < 19 {
            switch Int.random(in: 0..<3) {
            case 0:
                player.request(.hop, force: true)
            case 1:
                player.request(.jump, force: true)
            default:
                let left = Bool.random()
                player.request(left ? .turnLeft : .turnRight, facingLeft: left, force: true)
            }
            idleHold = 0.1
        } else {
            let rests: [PetAnim] = [.idleSit, .idleLay, .idleBreathing]
            player.request(rests.randomElement() ?? .idleSit, force: true)
            idleHold = 0.22
        }
    }
}
