import SwiftUI

final class WardrobeViewModel: ObservableObject {
    @Published var selectedCategory: Layer = .all
    @Published var sortByColor: BottomSheetSortView.Sort = .none
    var editingItemFileName: String?
    var editingItemLayer: Layer? {
        getItems().first(where: { $0.fileName == editingItemFileName })?.item.layer.first
    }

    var categrories: [Layer] {
        let allLayers: [Layer] = [.all, .base, .mid, .outer, .material, .footwear, .accessory]
        var layers = Array(Set(WardrobeFileManager.shared.read().map { $0.item.layer }.flatMap { $0 }))
        layers.sort {
            guard let firstIndex = allLayers.firstIndex(of: $0),
                  let secondIndex = allLayers.firstIndex(of: $1) else {
                return false
            }
            return firstIndex < secondIndex
        }
       return [.all] + layers
    }
    var items: [String : ClothingItem] {
        guard selectedCategory != .all else {
            return [:]
        }
        return WardrobeFileManager.shared.getClothingData()?.items.filter { $0.value.layer.contains(selectedCategory) } ?? [:]
    }
    
    func getItems() -> [WardrobeItem] {
        let wardrobeItems = WardrobeFileManager.shared.read()
        guard selectedCategory != .all else {
            if sortByColor != .none {
                return sortByColor == .fromWhiteToBlack ? sortWardrobeItemsFromWhiteToBlack(wardrobeItems) : sortWardrobeItemsByColorSimilarity(wardrobeItems)
            }
            return wardrobeItems
        }
        let items = wardrobeItems.filter { item in
            item.item.layer.contains(selectedCategory)
        }
        if sortByColor != .none {
            return sortByColor == .fromWhiteToBlack ? sortWardrobeItemsFromWhiteToBlack(wardrobeItems) : sortWardrobeItemsByColorSimilarity(wardrobeItems)
        }
        return items
    }
    
    func onDeleteItem() {
        guard let editingItemFileName else { return }
        WardrobeFileManager.shared.deleteItem(fileName: editingItemFileName)
    }
    
    func onEditLayerItem(layer: Layer) {
        guard let editingItemFileName else { return }
        WardrobeFileManager.shared.editItem(fileName: editingItemFileName, layer: layer)
    }
    
    private func colorFromHex(_ hex: String) -> UIColor {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexFormatted.hasPrefix("#") {
            hexFormatted.remove(at: hexFormatted.startIndex)
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)

        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0

        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    private func luminance(of color: UIColor) -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b
    }

    private func sortWardrobeItemsFromWhiteToBlack(_ items: [WardrobeItem]) -> [WardrobeItem] {
        return items.sorted {
            luminance(of: colorFromHex($0.color)) > luminance(of: colorFromHex($1.color))
        }
    }
    
    private func sortWardrobeItemsByColorSimilarity(_ items: [WardrobeItem]) -> [WardrobeItem] {
        guard let first = items.first else { return [] }
        
        var sorted: [WardrobeItem] = [first]
        var remaining = Array(items.dropFirst())
        
        while !remaining.isEmpty {
            let lastColor = colorFromHex(sorted.last!.color)
            let next = remaining.min(by: {
                colorDistance(from: lastColor, to: colorFromHex($0.color)) <
                    colorDistance(from: lastColor, to: colorFromHex($1.color))
            })!
            sorted.append(next)
            remaining.removeAll { $0.fileName == next.fileName } // or use full object comparison
        }
        
        return sorted
    }

    private  func colorDistance(from: UIColor, to: UIColor) -> CGFloat {
        let (r1, g1, b1) = colorComponents(from)
        let (r2, g2, b2) = colorComponents(to)
        return sqrt(pow(r1 - r2, 2) + pow(g1 - g2, 2) + pow(b1 - b2, 2))
    }
    
    private func colorComponents(_ color: UIColor) -> (CGFloat, CGFloat, CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }
    
}
