import UIKit

final class WardrobeFileManager {
    static let shared = WardrobeFileManager()
    
    private init() {}
    
    func writeIfPossible(items: [WardrobeItem]) {
        let wardrobeItems: [WardrobeItem] = read() + items
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(wardrobeItems)
            let fileURL = getDocumentsDirectory().appendingPathComponent("wardrove_items.json")
            try jsonData.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write JSON data: \(error.localizedDescription)")
        }
    }
    
    func editItem(fileName: String, layer: Layer) {
        var items = read()
        if let editingItemIndex = items.firstIndex(where: { $0.fileName == fileName }) {
            items[editingItemIndex].item.layer = [layer]
            do {
                let encoder = JSONEncoder()
                let jsonData = try encoder.encode(items)
                let fileURL = getDocumentsDirectory().appendingPathComponent("wardrove_items.json")
                try jsonData.write(to: fileURL, options: .atomic)
            } catch {
                print("Failed to write JSON data: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteItem(fileName: String) {
        var items = read()
        if let editingItemIndex = items.firstIndex(where: { $0.fileName == fileName }) {
            items.remove(at: editingItemIndex)
            do {
                let encoder = JSONEncoder()
                let jsonData = try encoder.encode(items)
                let fileURL = getDocumentsDirectory().appendingPathComponent("wardrove_items.json")
                try jsonData.write(to: fileURL, options: .atomic)
                let photoURL = getDocumentsDirectory().appendingPathComponent(fileName)
                try FileManager.default.removeItem(at: photoURL)
            } catch {
                print("Failed to write JSON data: \(error.localizedDescription)")
            }
        }
    }
    
    func read() -> [WardrobeItem] {
        let fileURL = getDocumentsDirectory().appendingPathComponent("wardrove_items.json")
        
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let items = try decoder.decode([WardrobeItem].self, from: jsonData)
            return items
        } catch {
            return []
        }
    }
    
    func saveImage(image: UIImage) -> String? {
        guard let data = image.pngData() else { return nil }
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = UUID().uuidString + ".png"
        let fileURL = documentsPath.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL, options: .atomic)
            return filename
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getClothingData() -> ClothingData? {
        if let path = Bundle.main.path(forResource: "clothing_data", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoder = JSONDecoder()
                let clothingData = try decoder.decode(ClothingData.self, from: data)
                return clothingData
            } catch {
                print("Error decoding JSON: \(error)")
                return nil
            }
        }
        return nil
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
