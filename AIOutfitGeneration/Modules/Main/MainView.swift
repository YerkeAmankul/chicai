import SwiftUI
import CoreLocation
import Lottie

struct MainView: View {
    @State private var isPresented = false
    @ObservedObject private var viewModel = MainViewModel()
    @State private var isWetherOn = true
    
    init() {
        if CLLocationManager().authorizationStatus != .notDetermined {
            isWetherOn = CLLocationManager().authorizationStatus == .authorizedWhenInUse || CLLocationManager().authorizationStatus == .authorizedAlways
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
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
                    }.padding(.top, -100)
                    Spacer()
                    TagsView(tags: viewModel.categrories, selectedTag: $viewModel.selectedCategory)
                        .background(Color("background"))
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
            }
            VStack(spacing: 0) {
                HStack {
                    Text("С учетом текущей погоды")
                        .foregroundColor(Color("primary"))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Toggle("", isOn: $isWetherOn)
                        .onChange(of: isWetherOn) { oldValue, newValue in
                            if newValue {
                                if CLLocationManager().authorizationStatus != .notDetermined {
                                    if !(CLLocationManager().authorizationStatus == .authorizedWhenInUse || CLLocationManager().authorizationStatus == .authorizedAlways) {
                                        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                                            if UIApplication.shared.canOpenURL(appSettings) {
                                                UIApplication.shared.open(appSettings)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: 60)
                }.padding([.leading, .trailing, .top])
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
                        OutfitView(viewModel: OutfitViewModel(event: selectedCategory, wetherOn: isWetherOn))
                    }
                }
            }.background(Color.white)
        }
        .background(Color.white)
        .onAppear {
            if CLLocationManager().authorizationStatus != .notDetermined {
                isWetherOn = CLLocationManager().authorizationStatus == .authorizedWhenInUse || CLLocationManager().authorizationStatus == .authorizedAlways
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
