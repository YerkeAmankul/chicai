import SwiftUI

final class WardrobeViewModel: ObservableObject {
    @Published var selectedCategory: Layer = .all
    var categrories: [Layer] = [.all, .base, .mid, .outer, .material, .footwear, .accessory]
    var items: [String : ClothingItem] {
        guard selectedCategory != .all else {
            return [:]
        }
        return WardrobeFileManager.shared.getClothingData()?.items.filter { $0.value.layer.contains(selectedCategory) } ?? [:]
    }
    func getItems() -> [WardrobeItem] {
        let wardrobeItems = WardrobeFileManager.shared.read()
        guard selectedCategory != .all else {
            return wardrobeItems
        }
        return wardrobeItems.filter { item in
            item.item.layer.contains(selectedCategory)
        }
    }
}
