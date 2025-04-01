import SwiftUI
import Lottie

struct OutfitView: View {

    @ObservedObject var viewModel: OutfitViewModel
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
                    Text("ChicAI изучает погоду, подбирает цвета и балансирует стиль. Что получится? Смелый эксперимент или безупречная классика? Скоро узнаем!")
                        .foregroundColor(Color("primary"))
                        .font(.system(size: 16, weight: .regular, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }.padding()
            } else {
                GeometryReader { proxy in
                    combinationView(items: viewModel.selectedCombination)
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
                                combinationView(items: item)
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
            viewModel.generateOutfit()
        }
        .fullScreenCover(isPresented: $viewModel.presentEmptyView) {
            EmptyWardrobeView(text: viewModel.notEnoughItemsForCombination?.text)
        }
    }
    
    private func combinationView(items: [WardrobeItem]) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .center) {
                if let baseImage = items.first(where: { $0.item.layer.first == .base })?.fileName,
                   let uiImage = UIImage(filename: baseImage) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                if let baseImage = items.first(where: { $0.item.layer.first == .material })?.fileName,
                   let uiImage = UIImage(filename: baseImage) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                if let baseImage = items.first(where: { $0.item.layer.first == .footwear })?.fileName,
                   let uiImage = UIImage(filename: baseImage) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            if items.first(where: { $0.item.layer.first == .mid })?.fileName != nil ||
                items.first(where: { $0.item.layer.first == .outer })?.fileName != nil ||
                items.first(where: { $0.item.layer.first == .accessory })?.fileName != nil {
                VStack(alignment: .center) {
                    HStack(alignment: .center) {
                        if let baseImage = items.first(where: { $0.item.layer.first == .mid })?.fileName,
                           let uiImage = UIImage(filename: baseImage) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        if let baseImage = items.first(where: { $0.item.layer.first == .outer })?.fileName,
                           let uiImage = UIImage(filename: baseImage) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                    if let baseImage = items.first(where: { $0.item.layer.first == .accessory })?.fileName,
                       let uiImage = UIImage(filename: baseImage) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
            }
        }.padding()
    }
    
    private func makeThumbnailAnimation() async throws -> LottieAnimationSource? {
        try await DotLottieFile.named("classifing").animationSource
    }
}
