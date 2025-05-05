import SwiftUI
import Lottie

struct OutfitView: View {

    @ObservedObject var viewModel: OutfitViewModel
    @Environment(\.dismiss) var dismiss
    @State var isOutfitGenerated = false
    
    private let itemHeight: CGFloat = (UIScreen.main.bounds.height - 200) / 2
    private let itemWidth: CGFloat = (UIScreen.main.bounds.width - 32) / 2
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            if viewModel.selectedCombination.isEmpty {
                VStack {
                    LottieView {
                        try await makeThumbnailAnimation()
                    }
                    .looping()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                    Text(viewModel.wetherOn ? "ChicAI изучает погоду, подбирает цвета и балансирует стиль. Что получится? Смелый эксперимент или безупречная классика? Скоро узнаем!" : "ChicAI подбирает цвета и балансирует стиль. Что получится? Смелый эксперимент или безупречная классика? Скоро узнаем!")
                        .foregroundColor(Color("primary"))
                        .font(.system(size: 16, weight: .regular, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }.padding()
            } else {
                GeometryReader { proxy in
                    combinationView(items: viewModel.selectedCombination, itemSize: CGSize(width: itemWidth, height: itemHeight))
                        .frame(maxWidth: .infinity, maxHeight: proxy.size.height, alignment: .top)
                        .background(Color("background"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                }
                VStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.2), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 10)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.combinations.indices, id: \.self) { index in
                                let item = viewModel.combinations[index]
                                combinationView(items: item, itemSize: CGSize(width: 100, height: 100))
                                    .frame(width: UIScreen.main.bounds.width/2.3, height: UIScreen.main.bounds.width/2.3)
                                    .background(Color("background"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .onTapGesture {
                                        viewModel.selectedIndex = index
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(viewModel.selectedIndex == index ? Color("primary") : Color.clear, lineWidth: 1.5)
                                    ).padding(1)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 200)
                }
            }
        }
        .background(Color.white)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if !isOutfitGenerated {
                    viewModel.generateOutfit()
                    isOutfitGenerated = true
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.presentEmptyView, onDismiss: {
            dismiss()
        }) {
            EmptyWardrobeView(text: viewModel.notEnoughItemsForCombination?.text, showCloseButton: true)
        }
    }
    
    private func combinationView(items: [WardrobeItem], itemSize: CGSize) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .center) {
                if let baseImage = items.first(where: { $0.item.layer.first == .base })?.fileName {
                    AsyncDownsampledImage(filePath: baseImage, size: itemSize).id(baseImage)
                }
                if let baseImage = items.first(where: { $0.item.layer.first == .material })?.fileName {
                    AsyncDownsampledImage(filePath: baseImage, size: itemSize).id(baseImage)
                }
                if let baseImage = items.first(where: { $0.item.layer.first == .footwear })?.fileName {
                    AsyncDownsampledImage(filePath: baseImage, size: itemSize).id(baseImage)
                }
            }
            if items.first(where: { $0.item.layer.first == .mid })?.fileName != nil ||
                items.first(where: { $0.item.layer.first == .outer })?.fileName != nil ||
                items.first(where: { $0.item.layer.first == .accessory })?.fileName != nil {
                VStack(alignment: .center) {
                    HStack(alignment: .center) {
                        if let baseImage = items.first(where: { $0.item.layer.first == .mid })?.fileName {
                            AsyncDownsampledImage(filePath: baseImage, size: itemSize).id(baseImage)
                        }
                        if let baseImage = items.first(where: { $0.item.layer.first == .outer })?.fileName {
                            AsyncDownsampledImage(filePath: baseImage, size: itemSize).id(baseImage)
                        }
                    }
                    if let baseImage = items.first(where: { $0.item.layer.first == .accessory })?.fileName {
                        AsyncDownsampledImage(filePath: baseImage, size: itemSize).id(baseImage)
                    }
                }
            }
        }.padding()
    }
        
    private func makeThumbnailAnimation() async throws -> LottieAnimationSource? {
        try await DotLottieFile.named("classifing").animationSource
    }
    
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
}
