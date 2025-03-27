import SwiftUI
import Lottie

struct MainView: View {
    @State private var isPresented = false
    @State var selectedCategory: String?
    private let categories = ["Повседневный", "Формальный", "Рабочый", "Домашний", "Религиозный", "Традиционный/Культурный"]
        
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
            TagsView(tags: categories, selectedTag: $selectedCategory)
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
                OutfitView()
            }
        }
        .background(Color.white)
        .onAppear {
            if selectedCategory == nil {
                selectedCategory = categories.first
            }
        }
    }
    
    private func generateOutfit() {
        isPresented = true
    }
    
    private func makeThumbnailAnimation() async throws -> LottieAnimationSource? {
        try await DotLottieFile.named("loading").animationSource
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
