import Vision
import CoreML
import UIKit

class ClothingClassifier {
    private var model: VNCoreMLModel?
    
    init?() {
        guard let mlModel = try? MobileNetV2(configuration: MLModelConfiguration()).model,
              let visionModel = try? VNCoreMLModel(for: mlModel) else {
            print("Failed to load CoreML model")
            return nil
        }
        self.model = visionModel
    }
    
    func classifyClothing(in images: [UIImage]) async -> [Result<(ClothingItem, UIImage), ErrorImage>] {
        guard let model = model,
              let clothingDataBase = WardrobeFileManager.shared.getClothingData()?.items
        else { return images.map { _ in .failure(ErrorImage(image: nil)) } }
        let arrayOfkeys = clothingDataBase.keys.map { $0 }

        return await withTaskGroup(of: (Int, Result<(ClothingItem, UIImage), ErrorImage>).self) { group in
            var results = [Result<(ClothingItem, UIImage), ErrorImage>](repeating: .failure(ErrorImage(image: nil)), count: images.count)
            
            for (index, image) in images.enumerated() {
                let viewModel = await ImageAnalysisViewModel()
                guard let detectedObjects = try? await viewModel.analyzeImage(image),
                      let extractedImage = try? await viewModel.interaction.image(for: detectedObjects) else {
                    
                    results[index] = .failure(ErrorImage(image: nil))
                    continue
                }
                
                guard let cgImage = extractedImage.cgImage else {
                    results[index] = .failure(ErrorImage(image: nil))
                    continue
                }
                group.addTask {
                    do {
                        let request = VNCoreMLRequest(model: model)
                        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                        try handler.perform([request])
                        
                        if let classifications = request.results as? [VNClassificationObservation] {
                            var topResult: VNClassificationObservation?
                            for classification in classifications.prefix(10) {
                                if arrayOfkeys.contains(where: { classification.identifier.lowercased().contains($0.lowercased()) }) {
                                    topResult = classification
                                    break
                                }
                            }
                            print("classifications.prefix(10):\(classifications.prefix(10))")
                            if let topResult = topResult {
                                if let item = clothingDataBase.first(where: { database in
                                    return topResult.identifier.lowercased().contains(database.key.lowercased())
                                })?.value {
                                    return (index, .success((item, extractedImage)))
                                } else {
                                    return (index, .failure(ErrorImage(image: extractedImage)))
                                }
                            } else {
                                return (index, .failure(ErrorImage(image: extractedImage)))
                            }
                        } else {
                            return (index, .failure(ErrorImage(image: extractedImage)))
                        }
                    } catch {
                        return (index, .failure(ErrorImage(image: extractedImage)))
                    }
                }
            }
            for await (index, result) in group {
                results[index] = result
            }
            
            return results
        }
    }
    
    struct ErrorImage: Error {
        let image: UIImage?
    }
}
