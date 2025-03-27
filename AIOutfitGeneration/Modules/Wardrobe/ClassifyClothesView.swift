import SwiftUI
import Lottie

struct AnimatedTextView: View {
    @State private var step = 1 {
        didSet {
            if step == 3 {
                showNextStep()
                coordinator.isEmptyWardrobe = false
            }
        }
    }
    @ObservedObject var coordinator: TabBarCoordinator
    
    let texts = [
        "🕵️‍♂️ Анализируем ткань...",
        "🎨 Распознаем цвет...",
        "🏷️ Определяем слой одежды..."
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
                                .font(.system(size: 20, weight: .medium, design: .monospaced))
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
                .onAppear {
                    showNextStep()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
    }

    private func showNextStep() {
        for i in 1...texts.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.5) {
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
