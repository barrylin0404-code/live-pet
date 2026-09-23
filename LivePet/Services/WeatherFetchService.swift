import Foundation
import WidgetKit
#if canImport(CoreLocation)
import CoreLocation
#endif
#if canImport(WeatherKit)
import WeatherKit
#endif

/// Fetches weather in the **app** and writes `WeatherCache` to the App Group.
/// Widgets only render the cache — they never prompt for location or call WeatherKit.
///
/// Mac enablement: add WeatherKit capability + entitlement
/// `com.apple.developer.weatherkit` on the LivePet app target (see README).
@MainActor
final class WeatherFetchService: NSObject, ObservableObject {
    static let shared = WeatherFetchService()

    @Published private(set) var lastCache: WeatherCache?
    @Published private(set) var statusMessage: String = ""

    #if canImport(CoreLocation)
    private let locationManager = CLLocationManager()
    #endif

    #if canImport(CoreLocation)
    private var pendingContinuation: CheckedContinuation<CLLocation?, Never>?
    #endif

    override init() {
        super.init()
        #if canImport(CoreLocation)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        #endif
        lastCache = WeatherCache.load()
    }

    /// Request When-In-Use if needed, fetch, write App Group, reload widgets.
    func refresh(forceSampleIfUnavailable: Bool = true) async {
        #if canImport(WeatherKit) && canImport(CoreLocation)
        let location = await requestLocation()
        if let location {
            do {
                let cache = try await fetchWeatherKit(at: location)
                persist(cache)
                statusMessage = "Weather updated"
                return
            } catch {
                statusMessage = "WeatherKit unavailable — using fallback"
            }
        } else {
            statusMessage = "Location unavailable — using fallback"
        }
        #else
        statusMessage = "WeatherKit not linked — writing sample cache"
        #endif

        if let existing = WeatherCache.load(), existing.hasObservation {
            lastCache = existing
            WidgetCenter.shared.reloadAllTimelines()
            return
        }
        if forceSampleIfUnavailable {
            persist(.sample)
        } else {
            persist(.empty)
        }
    }

    func persist(_ cache: WeatherCache) {
        cache.save()
        lastCache = cache
        WidgetCenter.shared.reloadAllTimelines()
    }

    #if canImport(WeatherKit) && canImport(CoreLocation)
    private func fetchWeatherKit(at location: CLLocation) async throws -> WeatherCache {
        let service = WeatherService.shared
        let weather = try await service.weather(for: location)
        let current = weather.currentWeather
        let c = current.temperature.converted(to: .celsius).value
        let f = current.temperature.converted(to: .fahrenheit).value
        let symbol = current.symbolName
        let label = Self.conditionLabel(current.condition)
        return WeatherCache(
            conditionSymbol: symbol.isEmpty ? "cloud" : symbol,
            conditionLabel: label,
            temperatureC: c,
            temperatureF: f,
            fetchedAt: .now,
            hasObservation: true
        )
    }

    private static func conditionLabel(_ condition: WeatherCondition) -> String {
        // Keep the switch SDK-tolerant; @unknown default covers new cases.
        switch condition {
        case .clear, .mostlyClear: return "Clear"
        case .cloudy, .mostlyCloudy, .partlyCloudy: return "Cloudy"
        case .rain, .drizzle: return "Rain"
        case .snow, .flurries: return "Snow"
        case .thunderstorms: return "Thunderstorms"
        case .foggy, .haze: return "Fog"
        case .breezy, .windy: return "Windy"
        case .hot: return "Hot"
        case .cold: return "Cold"
        default: return "Outside"
        }
    }
    #endif

    #if canImport(CoreLocation)
    private func requestLocation() async -> CLLocation? {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Brief wait for the permission sheet; caller may retry.
            try? await Task.sleep(nanoseconds: 800_000_000)
        case .denied, .restricted:
            return nil
        default:
            break
        }
        if let loc = locationManager.location {
            return loc
        }
        return await withCheckedContinuation { cont in
            pendingContinuation = cont
            locationManager.requestLocation()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                if let pending = self.pendingContinuation {
                    self.pendingContinuation = nil
                    pending.resume(returning: self.locationManager.location)
                }
            }
        }
    }
    #endif
}

#if canImport(CoreLocation)
extension WeatherFetchService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            pendingContinuation?.resume(returning: locations.last)
            pendingContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            pendingContinuation?.resume(returning: nil)
            pendingContinuation = nil
        }
    }
}
#endif
