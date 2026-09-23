import Foundation

/// Original cozy daily lines for PetDailyMessageWidget.
/// Pick stably by dayOfYear + petName.hash — never competitor quotes.
enum DailyMessages {
    static let lines: [String] = [
        "Keep smiling — I'm rooting for you!",
        "Tiny steps still count. I saw that.",
        "You're the cozy part of my day.",
        "Water break? I'll wait right here.",
        "Whatever's heavy, we can share it.",
        "Sun Nook thinking of you — soft thoughts only.",
        "A snack and a stretch fix more than you'd think.",
        "You showed up. That's already enough.",
        "I'm proud of the quiet wins today.",
        "Blink once if you need a hug. Blinking for you.",
        "The day can be uneven; we stay gentle.",
        "Your pace is perfect. Slow is still forward.",
        "Leave a little kindness for yourself too.",
        "If plans wobble, we'll invent a softer one.",
        "Thanks for checking in — I missed your face.",
        "Cozy reminder: rest is productive.",
        "You're doing better than the loud voices say.",
        "I'll keep the window seat warm for you.",
        "One deep breath, then another. I've got time.",
        "Home is wherever we hang out — even for a minute."
    ]

    static func message(for date: Date = .now, petName: String) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let seed = day &+ petName.hashValue
        let idx = abs(seed) % lines.count
        return lines[idx]
    }
}
