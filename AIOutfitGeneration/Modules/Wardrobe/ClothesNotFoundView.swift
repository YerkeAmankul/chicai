import SwiftUI
import Lottie

struct ClothesNotFoundView: View {
    
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    let items = Array(1...10).map { "Item \($0)" }
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: TabBarCoordinator
    
    var body: some View {
        VStack {
            LottieView {
                try await makeThumbnailAnimation()
            }
            .looping()
            .frame(width: UIScreen.main.bounds.width / 2.2, height: UIScreen.main.bounds.width / 2.2)
            .padding(.top, 20)
            Text("Ой, наш ИИ немного запутался – среди загруженных фото есть те, что не про одежду")
                .foregroundColor(Color("primary"))
                .font(.system(size: 16, weight: .regular, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        Text("")
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(Color("background"))
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            Spacer()
            Button(action: close) {
                Text("Закрыть")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("primary"))
                    .cornerRadius(12)
                    .shadow(radius: 4)
            }
            .padding()
        }
        .background(Color.white)
    }
    
    private func close() {
        coordinator.isEmptyWardrobe = false
//        coordinator.goToRoot = true
    }
 
    private func makeThumbnailAnimation() async throws -> LottieAnimationSource? {
        try await DotLottieFile.named("not_found").animationSource
    }
}

struct ClothesNotFoundView_Previews: PreviewProvider {
    static var previews: some View {
        ClothesNotFoundView()
    }
}
