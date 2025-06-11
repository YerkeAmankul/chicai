import SwiftUI
import CoreLocation

final class OutfitViewModel: ObservableObject {
    
    private let event: Event
    let wetherOn: Bool
    
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

    init(event: Event, wetherOn: Bool) {
        self.event = event
        self.wetherOn = wetherOn
    }
    
    func generateOutfit() {
        if wetherOn {
            getWeather { [weak self] response in
                self?.generate(weather: response)
            }
        } else {
            generate(weather: nil)
        }
    }
    
    private func generate(weather: OutfitViewModel.WeatherMap?) {
        guard let weather else {
            let layerCombinations = findCombinations(requiredLayers: [.base, .material], optionalLayers: [.footwear, .mid, .outer], from: wardrobe)
            guard !layerCombinations.isEmpty else {
                notEnoughItemsForCombination = .combination
                return
            }
            combinations = filterCompatibleCombinations(combinations: layerCombinations)
            guard !combinations.isEmpty else {
                notEnoughItemsForCombination = .compatible
                return
            }
            
            selectedIndex = 0
            return
        }
        let weathers = getWeatherArray(response: weather)
        let clothesFilteredWeather = getClothesFilteredByWeather(weathers: weathers)
        let layers = getLayers(weathers: weathers, event: event)
        guard !clothesFilteredWeather.isEmpty else {
            notEnoughItemsForCombination = .weather
            return
        }
        let clothesFilterdByLayers = getClothesFilteredByLayer(
            layers: layers.required + layers.optional,
            wardrobe: clothesFilteredWeather)
        guard !clothesFilteredWeather.isEmpty else {
            notEnoughItemsForCombination = .layer
            return
        }
        let clothesFilterdByEvent = getClothesFilteredByEvent(
            event: event,
            wardrobe: clothesFilterdByLayers
        )
        guard !clothesFilterdByEvent.isEmpty else {
            notEnoughItemsForCombination = .event
            return
        }
        let layerCombinations = findCombinations(requiredLayers: layers.required, optionalLayers: layers.optional, from: clothesFilterdByEvent)
        guard !layerCombinations.isEmpty else {
            notEnoughItemsForCombination = .combination
            return
        }
        combinations = filterCompatibleCombinations(combinations: layerCombinations)
        guard !combinations.isEmpty else {
            notEnoughItemsForCombination = .compatible
            return
        }
        
        selectedIndex = 0
    }
    
    private func filterCompatibleCombinations(combinations: [[WardrobeItem]]) -> [[WardrobeItem]] {
        return combinations
            .filter { combination in
                guard combination.count > 1 else { return false }
                for i in 0..<combination.count {
                    for j in (i + 1)..<combination.count {
                        let score = colorCompatibility(hex1: combination[i].color, hex2: combination[j].color).score
                        if score.rawValue < OutfitViewModel.CombinationScore.carefful.rawValue {
                            return false
                        }
                    }
                }
                return true
            }
            .map { combination in
                combination.sorted { item1, item2 in
                    let score1 = combination.reduce(0) { $0 + colorCompatibility(hex1: item1.color, hex2: $1.color).score.rawValue }
                    let score2 = combination.reduce(0) { $0 + colorCompatibility(hex1: item2.color, hex2: $1.color).score.rawValue }
                    return score1 < score2
                }
            }
    }
 
    private func findCombinations(
        requiredLayers: [Layer],
        optionalLayers: [Layer],
        from items: [WardrobeItem]
    ) -> [[WardrobeItem]] {
        var uniqueCombinations: Set<Set<String>> = []
        var validCombinations: [[WardrobeItem]] = []
        func backtrack(index: Int, currentItems: [WardrobeItem], currentLayers: [Layer]) {
            let sortedCurrentLayers = currentLayers.sorted(by: { $0.rawValue < $1.rawValue })
            let sortedRequiredLayers = requiredLayers.sorted(by: { $0.rawValue < $1.rawValue })

            if sortedRequiredLayers.allSatisfy({ sortedCurrentLayers.contains($0) }) {
                let fileNameSet = Set(currentItems.map { $0.fileName })
                if uniqueCombinations.insert(fileNameSet).inserted {
                    validCombinations.append(currentItems)
                }
            }
            guard index < items.count else { return }
            
            let item = items[index]
            let newLayers = item.item.layer
            
            if !newLayers.contains(where: { currentLayers.contains($0) }) || newLayers.contains(where: { optionalLayers.contains($0) }) {
                backtrack(index: index + 1, currentItems: currentItems + [item], currentLayers: currentLayers + newLayers)
            }

            backtrack(index: index + 1, currentItems: currentItems, currentLayers: currentLayers)
        }
        
        backtrack(index: 0, currentItems: [], currentLayers: [])
        return validCombinations
    }
    
    private func getClothesFilteredByWeather(weathers: [Weather]) -> [WardrobeItem] {
        let items = wardrobe.filter({ item in
            if item.item.layer.contains(.base) ||
                item.item.layer.contains(.material) ||
               item.item.layer.contains(.footwear) {
                return true
            }
            return item.item.weather.contains(where: weathers.contains)
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
    
    private func getLayers(weathers: [Weather], event: Event) -> (required: [Layer], optional: [Layer]) {
        var outfit: Set<Layer> = [.base, .material]
        var optionalOutfit: Set<Layer> = [.footwear]
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
        
        if event == .formal {
            optionalOutfit.insert(.accessory)
        }
        
        return (required: Array(outfit), optional: Array(optionalOutfit))
    }
    
    private func colorCompatibility(hex1: String, hex2: String) -> (score: CombinationScore, description: String) {
        guard let color1 = hexToRGB(hex1), let color2 = hexToRGB(hex2),
              let hue1 = getColorProperties(from: color1)?.hue,
              let hue2 = getColorProperties(from: color2)?.hue else {
            return (.bad, "Ошибка в обработке цветов")
        }
        
        let angleDifference = abs(hue1 - hue2)
        let minDifference = min(angleDifference, 360 - angleDifference)
        
        switch minDifference {
        case 0...20: return (.perfect, "Идеально: монохромный стиль")
        case 21...50: return (.good, "Отличное сочетание: аналогичные оттенки")
        case 51...90: return (.controversial, "Спорное сочетание: может выглядеть ярко")
        case 91...130: return (.normal, "Контрастное, но стильное сочетание")
        case 131...180: return (.carefful, "Сильный контраст: нужно подбирать осторожно")
        default: return (.bad, "Плохая совместимость: резкий конфликт цветов")
        }
    }
    
    private func hexToRGB(_ hex: String) -> UIColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        
        guard hexSanitized.count == 6,
              let rgbValue = UInt32(hexSanitized, radix: 16) else {
            return nil
        }
        
        return UIColor(
            red: CGFloat((rgbValue >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgbValue >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgbValue & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
    
    private func getColorProperties(from color: UIColor) -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat)? {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        
        guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return nil
        }
        
        return (hue * 360, saturation, brightness)
    }

    private func getWeather(onCompletion: @escaping (WeatherMap) -> Void) {
        locationManager.requestLocation { [weak self] (result: Result<CLLocationCoordinate2D, Error>) in
            guard let self else { return }
            switch result {
            case let .success(location):
                let apiLink = "https://api.openweathermap.org/data/2.5/weather?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(weatherAPIKey)&units=metric"
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
            case .failure:
                DispatchQueue.main.async {
                    self.generate(weather: nil)
                }
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
        case compatible
        
        var text: String {
            switch self {
            case .weather, .layer:
                return String(localized: "У вас нет одежды для такой погоды. Добавьте её, и мы создадим лук дня")
            case .event:
                return String(localized: "Ваш гардероб ждёт обновления! У вас нет одежды для этого события. Добавьте её, и мы подберём стильный лук")
            case .combination:
                return String(localized: "Для идеального лука не хватает деталей! У вас нет необходимых вещей для комбинации. Добавьте их, и мы закончим ваш лук")
            case .compatible:
                return String(localized: "Ваш лук почти готов, но не хватает вещей, сочетающихся по цвету! Добавьте подходящие элементы, и мы завершим идеальный лук")
            }
        }
    }
    
    enum CombinationScore: Int {
        case bad // Плохая совместимость: резкий конфликт цветов
        case controversial // Спорное сочетание: может выглядеть ярко
        case carefful // Сильный контраст: нужно подбирать осторожно
        case normal // Контрастное, но стильное сочетание
        case good // Отличное сочетание: аналогичные оттенки
        case perfect // Идеально: монохромный стиль
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
