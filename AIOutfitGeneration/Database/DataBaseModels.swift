struct WardrobeItem: Codable {
    var item: ClothingItem
    let color: String
    let fileName: String
}

struct ClothingItem: Codable {
    let season: [Season]
    let weather: [Weather]
    let event: [Event]
    var layer: [Layer]
}

struct ClothingData: Codable {
    let items: [String: ClothingItem]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawItems = try container.decode([[String: ClothingItem]].self, forKey: .items)
        
        var itemsDict = [String: ClothingItem]()
        for item in rawItems {
            if let (key, value) = item.first {
                itemsDict[key] = value
            }
        }
        self.items = itemsDict
    }

    enum CodingKeys: String, CodingKey {
        case items
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { return nil }
    init?(intValue: Int) { return nil }
}

enum Season: String, Codable {
    case spring
    case summer
    case fall
    case winter
}

enum Weather: String, Codable {
    case hot
    case warm
    case moderate
    case cold
    case rainy
}

enum Event: String, Codable {
    case casual
    case formal
    case workwear
    case sport
    case religious
    case cultural
    case home
    
    var text: String {
        switch self {
        case .casual:
            return String(localized: "Повседневный")
        case .formal:
            return String(localized: "Официальный")
        case .workwear:
            return String(localized: "Рабочий стиль")
        case .sport:
            return String(localized: "Спортивный")
        case .religious:
            return "Религиозный"
        case .cultural:
            return "Культурный"
        case .home:
            return String(localized: "Домашний")
        }
    }
}

enum Layer: String, Codable, Equatable {
    case all
    case base
    case mid
    case outer
    case accessory
    case footwear
    case material
    
    enum CodingKeys: String, CodingKey {
        case base, mid, outer, accessory, footwear, material
    }
    
    var text: String {
        switch self {
        case .all:
            return String(localized: "Все")
        case .base:
            return String(localized: "Базовый слой")
        case .mid:
            return String(localized: "Средний слой")
        case .outer:
            return String(localized: "Верхний слой")
        case .accessory:
            return String(localized: "Аксессуар")
        case .footwear:
            return String(localized: "Обувь")
        case .material:
            return String(localized: "Низ")
        }
    }
}
