import SwiftUI
import DominantColors
import VisionKit

final class ClassifyViewModel: ObservableObject {
    @Published var isCloseNotFound: Bool = false
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
            var imagesForExtract: [(String, UIImage)] = []
            for result in results ?? [] {
                switch result {
                case let .success(item):
                    imagesForExtract.append(item)
                case .failure:
                    areThereImagesNotFound = true
                }
            }
            extractImage(images: imagesForExtract)
        }
    }
    
    private func extractImage(images: [(String, UIImage)]) {
        Task { @MainActor in
            await withTaskGroup(of: (String, UIImage)?.self) { group in
                for image in images {
                    let viewModel = ImageAnalysisViewModel()
                    group.addTask {
                        do {
                            let detectedObjects = try await viewModel.analyzeImage(image.1)
                            let extractedImage = try await viewModel.interaction.image(for: detectedObjects)
                            return (image.0, extractedImage)
                        } catch {
                            return nil
                        }
                    }
                }
                var extractedImages: [(String, UIImage)] = []
                for await extractedImage in group {
                    if let extractedImage {
                        extractedImages.append(extractedImage)
                    }
                }
                extractColor(images: extractedImages)
            }
        }
    }
    
    private func extractColor(images: [(String, UIImage)]) {
        images.forEach { item in
            guard let image = item.1.cgImage else {
                return
            }
            if let cgColor = try? DominantColors.dominantColors(image: image, algorithm: .CIE94).first {
                Garderob.shared.clothes.append((item.0, cgColor, UIImage(cgImage: image)))
                coordinator.isEmptyWardrobe = false
            }
        }
        if areThereImagesNotFound == true {
            isCloseNotFound = true
        }
    }
}

class Garderob {
    static let shared = Garderob()
    var clothes: [(String, CGColor, UIImage)] = []
    private init() {}
}

extension ClassifyViewModel {
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
    
}
