import Foundation

/// One calendar-day snapshot of Feeling + Satiety for growth rolling averages.
struct DailyMeterSample: Codable, Hashable, Sendable {
    var dayStart: Date
    var moodScore: Int
    var satiety: Int

    init(dayStart: Date, moodScore: Int, satiety: Int) {
        self.dayStart = dayStart
        self.moodScore = max(0, min(100, moodScore))
        self.satiety = max(0, min(100, satiety))
    }
}
