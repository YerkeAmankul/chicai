import SwiftUI
import DominantColors
import VisionKit

final class ClassifyViewModel: ObservableObject {
    @Published var isCloseNotFound: Bool = false
    var isCloseNotFoundImages: [UIImage] = []
    let coordinator: TabBarCoordinator
    private let images: [UIImage]
    private var areThereImagesNotFound: Bool = false
    private let clothingClassifier = ClothingClassifier()
    
    init(coordinator: TabBarCoordinator, images: [UIImage]) {
        self.images = images
        self.coordinator = coordinator
    }
    
    func startClassification() {
        Task {
            let results = await clothingClassifier?.classifyClothing(in: images)
            var imagesForExtractColor: [(ClothingItem, UIImage)] = []
            for result in results ?? [] {
                switch result {
                case let .success(item):
                    imagesForExtractColor.append(item)
                case let .failure(error):
                    if let image = error.image {
                        isCloseNotFoundImages.append(image)
                    }
                    areThereImagesNotFound = true
                }
            }
//            extractImage(images: imagesForExtract)
            extractColor(images: imagesForExtractColor)
        }
    }
    
//    private func extractImage(images: [(ClothingItem, UIImage)]) {
//        Task { @MainActor in
//            await withTaskGroup(of: (ClothingItem, UIImage)?.self) { group in
//                for image in images {
//                    let viewModel = ImageAnalysisViewModel()
//                    group.addTask {
//                        do {
//                            let detectedObjects = try await viewModel.analyzeImage(image.1)
//                            let extractedImage = try await viewModel.interaction.image(for: detectedObjects)
//                            return (image.0, extractedImage)
//                        } catch {
//                            return nil
//                        }
//                    }
//                }
//                var extractedImages: [(ClothingItem, UIImage)] = []
//                for await extractedImage in group {
//                    if let extractedImage {
//                        extractedImages.append(extractedImage)
//                    }
//                }
//                extractColor(images: extractedImages)
//            }
//        }
//    }
    
    private func extractColor(images: [(ClothingItem, UIImage)]) {
        var wardrobeItems: [WardrobeItem] = []
        images.forEach { item in
            guard let image = item.1.cgImage,
                  let fileName = WardrobeFileManager.shared.saveImage(image: item.1)
            else {
                return
            }
            if let cgColor = try? DominantColors.dominantColors(image: image, algorithm: .CIE94).first?.toHexString() {
                wardrobeItems.append(.init(item: item.0, color: cgColor, fileName: fileName))
            }
        }
        WardrobeFileManager.shared.writeIfPossible(items: wardrobeItems)
        if areThereImagesNotFound == true {
            isCloseNotFound = true
        } else {
            coordinator.isEmptyWardrobe = false
        }
    }
}

@MainActor
class ImageAnalysisViewModel: NSObject, ObservableObject {
    let analyzer = ImageAnalyzer()
    let interaction = ImageAnalysisInteraction()
    var loadedImageView: UIImageView?
    
    func analyzeImage(_ image: UIImage) async throws -> Set<ImageAnalysisInteraction.Subject> {
        let configuration = ImageAnalyzer.Configuration([.visualLookUp])
        let analysis = try await analyzer.analyze(image, configuration: configuration)
        interaction.analysis = analysis
        let detectedSubjects = await interaction.subjects
        return detectedSubjects
    }
}

extension CGColor {
    func toHexString() -> String? {
        guard let components = self.components, components.count >= 3 else { return nil }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
