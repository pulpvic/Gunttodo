import Foundation

@MainActor
final class WeatherStore: ObservableObject {
    static let shared = WeatherStore()

    @Published private(set) var summary = "米兰天气"

    private var loadedCity: String?

    private init() {}

    func refreshIfNeeded(city: String) async {
        let city = normalizedCity(city)
        guard loadedCity != city else { return }
        await refresh(city: city)
    }

    func refresh(city rawCity: String) async {
        let city = normalizedCity(rawCity)
        loadedCity = city
        summary = "\(city)天气"

        do {
            let location = try await geocode(city: city)
            let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(location.latitude)&longitude=\(location.longitude)&current=temperature_2m,weather_code&timezone=\(location.encodedTimeZone)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let temperature = Int(response.current.temperature2M.rounded())
            summary = "\(city) \(temperature)° \(weatherText(for: response.current.weatherCode))"
        } catch {
            summary = "\(city)天气"
        }
    }

    private func geocode(city: String) async throws -> WeatherLocation {
        if let known = knownLocation(for: city) {
            return known
        }

        let query = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(query)&count=1&language=en&format=json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: data)
        guard let result = response.results?.first else {
            throw URLError(.cannotFindHost)
        }

        return WeatherLocation(
            latitude: result.latitude,
            longitude: result.longitude,
            timeZone: result.timezone ?? "Europe/Rome"
        )
    }

    private func knownLocation(for city: String) -> WeatherLocation? {
        switch city.lowercased() {
        case "米兰", "milan", "milano":
            return WeatherLocation(latitude: 45.4642, longitude: 9.1900, timeZone: "Europe/Rome")
        case "罗马", "rome", "roma":
            return WeatherLocation(latitude: 41.9028, longitude: 12.4964, timeZone: "Europe/Rome")
        default:
            return nil
        }
    }

    private func normalizedCity(_ city: String) -> String {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "米兰" : trimmed
    }

    private func weatherText(for code: Int) -> String {
        switch code {
        case 0: "晴"
        case 1, 2: "少云"
        case 3: "多云"
        case 45, 48: "雾"
        case 51, 53, 55, 56, 57: "毛雨"
        case 61, 63, 65, 66, 67: "雨"
        case 71, 73, 75, 77: "雪"
        case 80, 81, 82: "阵雨"
        case 85, 86: "阵雪"
        case 95, 96, 99: "雷雨"
        default: "天气"
        }
    }
}

private struct WeatherLocation {
    let latitude: Double
    let longitude: Double
    let timeZone: String

    var encodedTimeZone: String {
        timeZone.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Europe%2FRome"
    }
}

private struct OpenMeteoGeocodingResponse: Decodable {
    let results: [OpenMeteoGeocodingResult]?
}

private struct OpenMeteoGeocodingResult: Decodable {
    let latitude: Double
    let longitude: Double
    let timezone: String?
}

private struct OpenMeteoResponse: Decodable {
    let current: OpenMeteoCurrent
}

private struct OpenMeteoCurrent: Decodable {
    let temperature2M: Double
    let weatherCode: Int

    enum CodingKeys: String, CodingKey {
        case temperature2M = "temperature_2m"
        case weatherCode = "weather_code"
    }
}
