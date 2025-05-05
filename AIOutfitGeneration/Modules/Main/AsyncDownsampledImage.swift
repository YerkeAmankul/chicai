import SwiftUI

struct AsyncDownsampledImage: View {
    let filePath: String
    let size: CGSize

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .interpolation(Image.Interpolation.low)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
                    .frame(width: size.width, height: size.height)
            }
        }
        .onAppear {
            if image == nil {
                loadDownsampledImageAsync(from: filePath, to: size) { loadedImage in
                    self.image = loadedImage
                }
            }
        }
    }
    
    private func loadDownsampledImageAsync(from filePath: String, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsPath.appendingPathComponent(filePath)
            let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
            
            guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, imageSourceOptions) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
            let downsampleOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
            ] as CFDictionary
            
            guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let uiImage = UIImage(cgImage: downsampledImage)
            DispatchQueue.main.async { completion(uiImage) }
        }
    }
}
