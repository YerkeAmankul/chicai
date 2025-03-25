import SwiftUI
import Lottie

struct EmptyWardrobeView: View {
    @State var isLoading = false

    var body: some View {
        VStack {
            ZStack {
                LottieView {
                    try await makeThumbnailAnimation()
                }
                .looping()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                Text("Гардероб ждёт первых вещей! Добавьте их, и мы создадим лук дня.")
                    .foregroundColor(Color("primary"))
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, UIScreen.main.bounds.width + 100)
            }
            Spacer()
            Button(action: add) {
                Text("Добавить в гардероб")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("primary"))
                    .cornerRadius(12)
                    .shadow(radius: 4)
            }
            .padding()
        }.background(Color.white)
    }
    
    private func add() {
        print("Генерируем лук дня...")
    }
    
    private func makeThumbnailAnimation() async throws -> LottieAnimationSource? {
        try await DotLottieFile.named("empty").animationSource
    }
}

struct EmptyWardrobeView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyWardrobeView()
    }
}
