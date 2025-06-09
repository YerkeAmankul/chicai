import SwiftUI
import Lottie
import StoreKit

struct IAPView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var showTexts = false
    @ObservedObject private var manager: SubscriptionManager
    
    init(manager: SubscriptionManager) {
        self.manager = manager
    }
        
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color("primary"))
                }
            }
            Text("Ваш стиль — без ограничений")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(Color("primary"))
                .padding(.bottom, 8)
                .opacity(showTexts ? 1 : 0)
                .offset(y: showTexts ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showTexts)
            Text("Откройте полный доступ и добавляйте всё, что нравится. Получайте образы, которые вдохновляют. Каждый день")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color("primary"))
                .padding(.bottom, 8)
                .opacity(showTexts ? 1 : 0)
                .offset(y: showTexts ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: showTexts)
            Text("* Добавляйте неограниченно одежду в гардероб")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color("primary"))
                .padding(.leading, 8)
                .opacity(showTexts ? 1 : 0)
                .offset(y: showTexts ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: showTexts)
            Text("* Смотрите все образы, созданные ИИ")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color("primary"))
                .padding(.leading, 8)
                .opacity(showTexts ? 1 : 0)
                .offset(y: showTexts ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: showTexts)
            Spacer()
            LottieView {
                try await makeThumbnailAnimation()
            }
            .looping()
            .opacity(showTexts ? 1 : 0)
            .offset(y: showTexts ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.7), value: showTexts)
            Spacer()
            if manager.products.isEmpty {
                Button(action: {}) {
                    HStack {
                        Text("Месячная подписка")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color("primary"))
                .cornerRadius(12)
                .shadow(radius: 4)
                .opacity(showTexts ? 1 : 0)
                .offset(y: showTexts ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(1), value: showTexts)
                Button(action: {}) {
                    HStack {
                        Text("Годовая подписка")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color("primary"))
                .cornerRadius(12)
                .shadow(radius: 4)
                .opacity(showTexts ? 1 : 0)
                .offset(y: showTexts ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(1.3), value: showTexts)
                Button(action: {}) {
                    Text("Восстановить")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(Color("primary"))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("tertiary"))
                        .cornerRadius(12)
                        .shadow(radius: 1)
                }
                .opacity(showTexts ? 1 : 0)
                .offset(y: showTexts ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(1.6), value: showTexts)
            } else {
                ForEach(manager.products, id: \.id) { product in
                    VStack(alignment: .center) {
                        Button(action: {
                            subscription(product: product)
                        }) {
                            Text(product.id == SubscriptionManager.monthlyID ? String(localized: "Месячная подписка") + " \(product.displayPrice)" : String(localized: "Годовая подписка") + " \(product.displayPrice)")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color("primary"))
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                    }
                }
                Button(action: restore) {
                    Text("Восстановить")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(Color("primary"))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("tertiary"))
                        .cornerRadius(12)
                        .shadow(radius: 1)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .onAppear {
            manager.fetchSubscription()
            showTexts = true
        }
        .alert(item: $manager.occuredError) { error in
            Alert(
                title: Text(""),
                message: Text(error.message),
                dismissButton: .default(Text("Ок")))
        }
    }
    
    private func makeThumbnailAnimation() async throws -> LottieAnimationSource? {
        try await DotLottieFile.named("iap").animationSource
    }
    
    private func restore() {
        Task {
            await manager.restorePurchases()
        }
    }
    
    private func subscription(product: Product) {
        Task {
            await manager.purchase(product)
        }
    }
}
