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
    
    func classifyClothing(in images: [UIImage]) async -> [Result<(String, UIImage), Error>] {
        guard let model = model else { return images.map { _ in .failure(NSError()) } }
        
        return await withTaskGroup(of: (Int, Result<(String, UIImage), Error>).self) { group in
            var results = [Result<(String, UIImage), Error>](repeating: .failure(NSError()), count: images.count)
            
            for (index, image) in images.enumerated() {
                guard let cgImage = image.cgImage else {
                    results[index] = .failure(NSError())
                    continue
                }
                group.addTask {
                    do {
                        let request = VNCoreMLRequest(model: model)
                        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                        try handler.perform([request])
                        
                        if let classifications = request.results as? [VNClassificationObservation],
                           let topResult = classifications.first {
                            return (index, .success((topResult.identifier, image)))
                        } else {
                            return (index, .failure(NSError()))
                        }
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            
            for await (index, result) in group {
                results[index] = result
            }
            
            return results
        }
    }
}


//class ClothingClassifier {
//    private var model: VNCoreMLModel?
//    
//    init?() {
//        guard let mlModel = try? MobileNetV2(configuration: MLModelConfiguration()).model,
//              let visionModel = try? VNCoreMLModel(for: mlModel) else {
//            print("Failed to load CoreML model")
//            return nil
//        }
//        self.model = visionModel
//    }
//    
//    func classifyClothing(in image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
//        guard let cgImage = image.cgImage, let model = model else { return }
//        
//        let request = VNCoreMLRequest(model: model) { request, error in
//            guard let results = request.results as? [VNClassificationObservation],
//                  let topResult = results.first else {
//                completion(.failure(NSError()))
//                return
//            }
//            
//            completion(.success(topResult.identifier))
//        }
//        
//        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//        try? handler.perform([request])
//    }
//}
