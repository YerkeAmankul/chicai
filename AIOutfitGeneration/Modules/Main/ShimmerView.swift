import SwiftUI

struct ShimmerRectangle: View {
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color("background"))
            .overlay(
                GeometryReader { geometry in
                    shimmer
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                        .onAppear {
                            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                isAnimating = true
                            }
                        }
                }
                .mask(RoundedRectangle(cornerRadius: 12))
            )
    }

    private var shimmer: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.4),
                Color.white.opacity(0.8),
                Color.white.opacity(0.4)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
