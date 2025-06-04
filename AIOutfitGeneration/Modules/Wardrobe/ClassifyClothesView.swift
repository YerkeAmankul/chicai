import SwiftUI
import Lottie

struct ClassifyClothesView: View {
    
    @State private var isStartClassify: Bool = false
    @State private var step = 1 {
        didSet {
            if step == 3 {
                if !isStartClassify {
                    viewModel.startClassification()
                    self.isStartClassify = true
                }
                showNextStep()
            }
        }
    }
    @ObservedObject private var viewModel: ClassifyViewModel
    
    init(viewModel: ClassifyViewModel) {
        self.viewModel = viewModel
    }
    
    let texts = [
        String(localized: "🕵️‍♂️ Анализируем ткань..."),
        String(localized: "🎨 Распознаем цвет..."),
        String(localized: "🏷️ Определяем слой одежды...")
    ]
    
    var body: some View {
        ZStack {
            Color.white // Ensures complete opacity
                .ignoresSafeArea()
            VStack {
                LottieView {
                    try await makeThumbnailAnimation()
                }
                .looping()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<texts.count, id: \.self) { index in
                        if step > index {
                            Text(texts[index])
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .bottom)
                                            .combined(with: .opacity)
                                            .combined(with: .scale(scale: 0.9, anchor: .bottom)),
                                        removal: .opacity
                                    )
                                )
                        }
                    }
                }
                .frame(height: 200)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: step)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }.fullScreenCover(isPresented: $viewModel.isCloseNotFound) {
            ClothesNotFoundView(images: viewModel.isCloseNotFoundImages)
                .environmentObject(viewModel.coordinator)
        }.task {
            showNextStep()
        }
    }

    private func showNextStep() {
        for i in 1...texts.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1) {
                withAnimation {
                    step = i
                }
            }
        }
    }
    
    private func makeThumbnailAnimation() async throws -> LottieAnimationSource? {
        try await DotLottieFile.named("classifing").animationSource
    }
}
