import Foundation

/// App-fetched weather snapshot stored in the App Group for widgets to render only.
/// Widgets never call WeatherKit or prompt for location.
struct WeatherCache: Codable, Hashable, Sendable {
    /// SF Symbol name, e.g. `sun.max.fill`, `cloud.rain.fill`.
    var conditionSymbol: String
    /// Short human label, e.g. "Sunny", "Rain".
    var conditionLabel: String
    /// Celsius when known; nil means hide temperature (no fake °).
    var temperatureC: Double?
    /// Fahrenheit when known; preferred for US-facing UI when present.
    var temperatureF: Double?
    var fetchedAt: Date
    /// False = empty / stub with no usable observation.
    var hasObservation: Bool

    var displayTemperature: String? {
        guard hasObservation else { return nil }
        if let temperatureF {
            return "\(Int(temperatureF.rounded()))°"
        }
        if let temperatureC {
            let f = temperatureC * 9 / 5 + 32
            return "\(Int(f.rounded()))°"
        }
        return nil
    }

    static func load(from defaults: UserDefaults = AppGroup.defaults) -> WeatherCache? {
        guard let data = defaults.data(forKey: AppGroup.weatherCacheKey) else { return nil }
        return try? JSONDecoder().decode(WeatherCache.self, from: data)
    }

    func save(to defaults: UserDefaults = AppGroup.defaults) {
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: AppGroup.weatherCacheKey)
        }
    }

    /// Soft empty cache — widget shows cozy line only, never a blank card.
    static var empty: WeatherCache {
        WeatherCache(
            conditionSymbol: "cloud",
            conditionLabel: "Outside",
            temperatureC: nil,
            temperatureF: nil,
            fetchedAt: .now,
            hasObservation: false
        )
    }

    /// Sample used when WeatherKit / location unavailable (dev + Linux scaffold).
    static var sample: WeatherCache {
        WeatherCache(
            conditionSymbol: "sun.max.fill",
            conditionLabel: "Sunny",
            temperatureC: 22,
            temperatureF: 72,
            fetchedAt: .now,
            hasObservation: true
        )
    }
}

enum WeatherCozyTip {
    /// Original cozy line keyed by mood band + rough condition.
    static func line(moodBand: String, conditionLabel: String, petName: String) -> String {
        let cond = conditionLabel.lowercased()
        let rainy = cond.contains("rain") || cond.contains("storm") || cond.contains("drizzle")
        let snowy = cond.contains("snow") || cond.contains("flurr")
        let cloudy = cond.contains("cloud") || cond.contains("fog") || cond.contains("overcast")
        let sunny = cond.contains("sun") || cond.contains("clear") || cond.contains("fair")

        switch moodBand {
        case "hungry":
            if rainy { return "Rainy snack weather — \(petName) is thinking crumbs." }
            return "Snack break weather — \(petName) is peckish."
        case "sleepy":
            if rainy || cloudy { return "Cozy nap skies — soft lights, soft yawns." }
            return "Drowsy hour — a quiet tuck-in sounds perfect."
        case "low":
            return "Gentle day — \(petName) could use a little care."
        case "playful":
            if sunny { return "Sun Nook weather — perfect for a stroll." }
            if rainy { return "Puddle-watch weather — bounce indoors today." }
            return "Playful skies — a quick game would sparkle."
        case "happy":
            if sunny { return "Bright and warm — \(petName) feels sunny too." }
            if snowy { return "Soft snow hush — warm hearts inside." }
            return "Good weather for hanging out together."
        default:
            if sunny { return "Sun Nook weather — perfect for a stroll." }
            if rainy { return "Rain on the window — tea and pets." }
            if snowy { return "Snow-quiet day — stay snug." }
            if cloudy { return "Soft cloud cover — easy care day." }
            return "Nice day to check in on \(petName)."
        }
    }
}
