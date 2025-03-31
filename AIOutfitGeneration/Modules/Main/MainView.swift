import SwiftUI
import Lottie

struct MainView: View {
    @State private var isPresented = false
    @ObservedObject private var viewModel = MainViewModel()
        
    var body: some View {
        VStack {
            ZStack {
                LottieView {
                    try await makeThumbnailAnimation()
                }
                .looping()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                Text("Кто сегодня вы? Кэжуал, элегантность или что-то смелее? Узнаем!")
                    .foregroundColor(Color("primary"))
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 250)
            }
            Spacer()
            TagsView(tags: viewModel.categrories, selectedTag: $viewModel.selectedCategory)
                .background(Color("background"))
                .cornerRadius(16)
                .padding(.horizontal)
            Spacer()
            Button(action: generateOutfit) {
                Text("Лук дня")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("primary"))
                    .cornerRadius(12)
                    .shadow(radius: 4)
            }
            .padding()
            .sheet(isPresented: $isPresented) {
                if let selectedCategory = viewModel.selectedCategory {
                    OutfitView(viewModel: OutfitViewModel(event: selectedCategory))
                }
            }
        }
        .background(Color.white)
    }
    
    private func generateOutfit() {
        isPresented = true
    }
    
    private func makeThumbnailAnimation() async throws -> LottieAnimationSource? {
        try await DotLottieFile.named("loading").animationSource
    }
}
