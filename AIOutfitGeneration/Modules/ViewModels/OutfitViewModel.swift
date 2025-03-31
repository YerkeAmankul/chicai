import SwiftUI
import CoreLocation

final class OutfitViewModel: ObservableObject {
    
    private let event: Event
    
    private let weatherAPIKey = "a22a49228a176fdce8892bccd40a879b"
    private let wardrobe = WardrobeFileManager.shared.read()
    private var locationManager = LocationManager()
    @Published var notEnoughItemsForCombination: NotEnoughItemsForCombination? {
        didSet {
            presentEmptyView = true
        }
    }
    @Published var presentEmptyView: Bool = false
    @Published var combinations: [[WardrobeItem]] = []
    @Published var selectedIndex: Int? {
        didSet {
            selectedCombination = combinations[safe: (selectedIndex ?? 0)] ?? []
        }
    }
    @Published var selectedCombination: [WardrobeItem] = []

    init(event: Event) {
        self.event = event
    }
    
    func generateOutfit() {
        getWeather { [weak self] response in
            guard let self else { return }
            let weathers = getWeatherArray(response: response)
            let clothesFilteredWeather = getClothesFilteredByWeather(weathers: weathers)
            let layers = getLayers(weathers: weathers, event: event)
            guard !clothesFilteredWeather.isEmpty else {
                notEnoughItemsForCombination = .weather
                return
            }
            let clothesFilterdByLayers = getClothesFilteredByLayer(
                layers: layers,
                wardrobe: clothesFilteredWeather)
            guard !clothesFilteredWeather.isEmpty else {
                notEnoughItemsForCombination = .layer
                return
            }
            let clothesFilterdByEvent = getClothesFilteredByEvent(
                event: event,
                wardrobe: clothesFilterdByLayers
            )
            guard !clothesFilteredWeather.isEmpty else {
                notEnoughItemsForCombination = .event
                return
            }
            combinations = findCombinations(for: layers, from: clothesFilterdByEvent)
            guard !combinations.isEmpty else {
                notEnoughItemsForCombination = .combination
                return
            }
            selectedIndex = 0
        }
    }
    
    private func findCombinations(for requiredLayers: [Layer], from items: [WardrobeItem]) -> [[WardrobeItem]] {
        var validCombinations: [[WardrobeItem]] = []
        
        func backtrack(index: Int, currentItems: [WardrobeItem], currentLayers: [Layer]) {
            let sortedCurrentLayers = currentLayers.sorted(by: { $0.rawValue < $1.rawValue })
            let sortedRequiredLayers = requiredLayers.sorted(by: { $0.rawValue < $1.rawValue })
            
            if sortedCurrentLayers == sortedRequiredLayers {
                validCombinations.append(currentItems)
                return
            }
            guard index < items.count else { return }
            
            let item = items[index]
            let newLayers = item.item.layer
            
            if !newLayers.contains(where: { currentLayers.contains($0) }) {
                backtrack(index: index + 1, currentItems: currentItems + [item], currentLayers: currentLayers + newLayers)
            }
            
            backtrack(index: index + 1, currentItems: currentItems, currentLayers: currentLayers)
        }
        
        backtrack(index: 0, currentItems: [], currentLayers: [])
        return validCombinations
    }
    
    private func getClothesFilteredByWeather(weathers: [Weather]) -> [WardrobeItem] {
        let items = wardrobe.filter({ item in
            item.item.weather.contains(where: weathers.contains)
        })
        return items
    }
    
    private func getClothesFilteredByLayer(
        layers: [Layer],
        wardrobe: [WardrobeItem]
    ) -> [WardrobeItem] {
        let items = wardrobe.filter({ item in
            item.item.layer.contains(where: layers.contains)
        })
        return items
    }
    
    private func getClothesFilteredByEvent(
        event: Event,
        wardrobe: [WardrobeItem]
    ) -> [WardrobeItem] {
        let items = wardrobe.filter({ item in
            item.item.event.contains(event)
        })
        return items
    }
    
    private func getWeatherArray(response: OutfitViewModel.WeatherMap) -> [Weather] {
        var weathers: Set<Weather> = []
        response.weather.forEach { weather in
            switch weather.main {
            case .clear, .clouds:
                switch response.main.temp {
                case ..<10:
                    weathers.insert(.cold)
                case 10..<20:
                    weathers.insert(.moderate)
                case 20..<25:
                    weathers.insert(.warm)
                default:
                    weathers.insert(.hot)
                }
            case .rain:
                weathers.insert(.rainy)
            case .drizzle, .thunderstorm, .snow, .mist:
                weathers.insert(.cold)
            }
        }
        return Array(weathers)
    }
    
    private func getLayers(weathers: [Weather], event: Event) -> [Layer] {
        var outfit: Set<Layer> = [.base, .material]
//        var outfit: Set<Layer> = [.base, .footwear, .material]
        var needsMid = false
        var needsOuter = false
        
        for weather in weathers {
            switch weather {
            case .moderate:
                needsMid = true
            case .cold, .rainy:
                needsMid = true
                needsOuter = true
            default:
                break
            }
        }
        
        if needsMid {
            outfit.insert(.mid)
        }
        if needsOuter {
            outfit.insert(.outer)
        }
        
//        if event == .formal {
//            outfit.insert(.accessory)
//        }
        
        return Array(outfit)
    }

    private func getWeather(onCompletion: @escaping (WeatherMap) -> Void) {
        locationManager.requestLocation { [weak self] (result: Result<CLLocationCoordinate2D, Error>) in
            guard let self else { return }
            switch result {
            case let .success(location):
                let apiLink = "https://api.openweathermap.org/data/2.5/weather?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(weatherAPIKey)"
                guard let url = URL(string: apiLink) else { return }
                
                URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data else { return }
                    
                    do {
                        let weatherResponse = try JSONDecoder().decode(WeatherMap.self, from: data)
                        DispatchQueue.main.async {
                            onCompletion(weatherResponse)
                        }
                    } catch {
                        print("Error decoding data: \(error.localizedDescription)")
                    }
                }.resume()
            case let .failure(failure):
                print(failure)
            }
        }
    }
}

extension OutfitViewModel {
    
    struct WeatherMap: Codable {
        let weather: [WeatherMain]
        let main: Main
        
        struct Main: Codable {
            let temp: Double
            let feels_like: Double
            let temp_min: Double
            let temp_max: Double
            let pressure: Int
            let humidity: Int
        }
        
        struct WeatherMain: Codable {
            let main: Main
            enum Main: String, Codable {
                case clear = "Clear"
                case clouds = "Clouds"
                case rain = "Rain"
                case drizzle = "Drizzle"
                case thunderstorm = "Thunderstorm"
                case snow = "Snow"
                case mist = "Mist"
            }
        }
    }
    
    enum NotEnoughItemsForCombination {
        case weather
        case layer
        case event
        case combination
        
        var text: String {
            switch self {
            case .weather, .layer:
                return "У вас нет одежды для такой погоды. Добавьте её, и мы создадим лук дня"
            case .event:
                return "Ваш гардероб ждёт обновления! У вас нет одежды для этого события. Добавьте её, и мы подберём стильный лук"
            case .combination:
                return "Для идеального образа не хватает деталей! У вас нет необходимых вещей для комбинации. Добавьте их, и мы закончим ваш лук"
            }
        }
    }

}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
    
    func chunks(ofCount count: Int) -> [[Element]] {
        precondition(!isEmpty, "Count must be greater than 0")

        var result: [[Element]] = []

        var currentIndex = startIndex

        while currentIndex < endIndex {
            let endIndex = index(currentIndex, offsetBy: count, limitedBy: self.endIndex) ?? self.endIndex
            let chunk = Array(self[currentIndex..<endIndex])
            result.append(chunk)
            currentIndex = endIndex
        }

        return result
    }
}
