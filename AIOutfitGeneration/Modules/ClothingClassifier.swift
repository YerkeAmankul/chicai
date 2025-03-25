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
    
    func classifyClothing(in image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage, let model = model else { return }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                print("No classification result")
                return
            }
            
            completion(topResult.identifier)
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}
