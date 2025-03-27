import SwiftUI
import _PhotosUI_SwiftUI
import Lottie

struct EmptyWardrobeView: View {
    @State private var showBottomSheet = false
    @State private var images: [UIImage]?
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var loadingCount = 0
    @State var isLoading = false
    @State private var startClassified = false
    @ObservedObject var coordinator: TabBarCoordinator

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
                if !isLoading {
                    Text("Добавить в гардероб")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("primary"))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(Color.white)
                        .scaleEffect(1.2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("primary"))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }
            }
            .padding()
            .sheet(isPresented: $showBottomSheet) {
                BottomSheetView(onMakePhotot: {
                    showBottomSheet = false
                    showCamera = true
                }, onSelectFromGallery: {
                    showBottomSheet = false
                    showGallery = true
                })
                .presentationDetents([.fraction(0.18)])
            }
            .sheet(isPresented: $showCamera) {
                CameraView(images: $images)
            }
            .photosPicker(isPresented: $showGallery, selection: $selectedItems, matching: .images)
            .onChange(of: selectedItems) { _, _ in
                loadImages()
            }
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $startClassified) {
            AnimatedTextView(coordinator: coordinator)
        }
    }
    
    func loadImages() {
        images = []
        loadingCount = selectedItems.count
        isLoading = true
        
        for item in selectedItems {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    images?.append(uiImage)
                }
                loadingCount -= 1
                if loadingCount == 0 {
                    isLoading = false
                    startClassified = true
                }
            }
        }
    }
    
    private func add() {
        showBottomSheet = true
    }
    
    private func makeThumbnailAnimation() async throws -> LottieAnimationSource? {
        try await DotLottieFile.named("empty").animationSource
    }
}

extension EmptyWardrobeView {
    struct BottomSheetView: View {
        var onMakePhotot: () -> Void
        var onSelectFromGallery: () -> Void
        var body: some View {
            VStack(alignment: .leading) {
                Text("Сделать снимок")
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primary)
                    .onTapGesture {
                        onMakePhotot()
                    }
                Divider().background(Color.tertiary)
                Text("Выбрать из галереи")
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primary)
                    .onTapGesture {
                        onSelectFromGallery()
                    }
                Spacer()
            }
            .padding(24)
            .background(Color.white)
        }
    }
}
