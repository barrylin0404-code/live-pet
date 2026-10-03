import Foundation

/// Autonomous pet. Picks clips and walks. Views only render `x` and `player`.
public struct PetBrain: Equatable {
    public var x: CGFloat
    public var player: PetAnimPlayer
    public private(set) var foodX: CGFloat?
    public private(set) var feedReady: Bool

    private var wanderTarget: CGFloat?
    private var idleHold: Double
    private var commandedUntil: Double
    private var clock: Double

    public init(x: CGFloat = 0.48) {
        self.x = x
        self.player = PetAnimPlayer(anim: .idle)
        self.foodX = nil
        self.feedReady = false
        self.wanderTarget = nil
        self.idleHold = 0.6
        self.commandedUntil = 0
        self.clock = 0
    }

    public mutating func noticeFood(at fraction: CGFloat) {
        foodX = min(0.78, max(0.22, fraction))
        feedReady = false
        wanderTarget = nil
        player.request(.walkToFood, facingLeft: foodX! < x, force: true)
    }

    public mutating func reactPet() {
        player.request(.petHappy, force: true)
        commandedUntil = clock + 1.1
        wanderTarget = nil
    }

    public mutating func reactPlay() {
        player.request(.playExcited, force: true)
        commandedUntil = clock + 1.4
        wanderTarget = nil
    }

    public mutating func reactBath() {
        player.request(.bathing, force: true)
        commandedUntil = clock + 1.2
    }

    public mutating func reactSleep(on: Bool) {
        if on {
            player.request(.sleeping, force: true)
            wanderTarget = nil
            commandedUntil = clock + 8
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

    public mutating func tick(dt: Double, sleeping: Bool) {
        let dt = min(0.05, max(0, dt))
        clock += dt
        player.advance(dt: dt)

        if sleeping {
            if player.anim != .sleeping && player.anim != .sleepBreathing {
                player.request(.sleeping, force: true)
            }
            return
        }

        if let food = foodX {
            let dx = food - x
            if abs(dx) > 0.03 {
                let dirLeft = dx < 0
                if player.anim != .walkToFood {
                    player.request(.walkToFood, facingLeft: dirLeft, force: true)
                }
                x += (dirLeft ? -1 : 1) * CGFloat(dt) * 0.16
                x = min(0.82, max(0.18, x))
                return
            }
            x = food
            if player.anim != .eating && player.anim != .eatFinish && player.anim != .happy {
                player.request(.eating, force: true)
            } else if player.finishedOneShot {
                if player.anim == .eating {
                    player.request(.eatFinish, force: true)
                } else if player.anim == .eatFinish {
                    feedReady = true
                    player.request(.happy, force: true)
                    commandedUntil = clock + 0.9
                }
            }
            return
        }

        if clock < commandedUntil {
            if player.finishedOneShot { player.request(.idle, force: true) }
            return
        }

        let moving = player.anim == .walkRight || player.anim == .walkLeft || player.anim == .walkSlow
        if let target = wanderTarget, moving {
            let dx = target - x
            if abs(dx) < 0.025 {
                wanderTarget = nil
                player.request(.idle, force: true)
                idleHold = Double.random(in: 0.7...1.8)
                return
            }
            let left = dx < 0
            player.request(left ? .walkLeft : .walkRight, facingLeft: left)
            x += (left ? -1 : 1) * CGFloat(dt) * 0.11
            x = min(0.80, max(0.20, x))
            return
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

    private mutating func chooseNext() {
        let roll = Int.random(in: 0..<10)
        if roll < 4 {
            let target = CGFloat.random(in: 0.24...0.76)
            wanderTarget = target
            let left = target < x
            player.request(left ? .walkLeft : .walkRight, facingLeft: left, force: true)
        } else if roll < 6 {
            player.request(.idleBlink, force: true)
            idleHold = 0.4
        } else if roll < 8 {
            player.request(Bool.random() ? .idleLookLeft : .idleLookRight, force: true)
            idleHold = 0.5
        } else if roll == 8 {
            player.request(.idleYawn, force: true)
            idleHold = 0.4
        } else {
            player.request(.idleGroom, force: true)
            idleHold = 0.4
        }
    }
}
