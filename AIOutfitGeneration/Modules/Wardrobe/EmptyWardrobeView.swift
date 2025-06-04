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
    @EnvironmentObject var coordinator: TabBarCoordinator
    var text: String? = nil
    var showCloseButton: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            ZStack {
                LottieView {
                    try await makeThumbnailAnimation()
                }
                .looping()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                Text(text ?? String(localized: "Гардероб ждёт первых вещей! Добавьте их, и мы создадим лук дня."))
                    .foregroundColor(Color("primary"))
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, UIScreen.main.bounds.width + 100)
            }
            Spacer()
            buttons
            .sheet(isPresented: $showBottomSheet) {
                BottomSheetView(onMakePhotot: {
                    showBottomSheet = false
                    showCamera = true
                }, onSelectFromGallery: {
                    showBottomSheet = false
                    showGallery = true
                })
                .presentationDetents([.fraction(0.3)])
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(images: $images)
            }
            .photosPicker(isPresented: $showGallery, selection: $selectedItems, maxSelectionCount: 10, matching: .images)
            .onChange(of: selectedItems) { _, _ in
                loadImages()
            }
            .onChange(of: images) { _, _ in
                startClassified = true
            }
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $startClassified) {
            let viewModel = ClassifyViewModel(coordinator: coordinator, images: images ?? [])
            ClassifyClothesView(viewModel: viewModel)
                .environmentObject(coordinator)
        }
    }
    
    var buttons: some View {
        VStack(spacing: 8) {
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
            if showCloseButton {
                Button(action: close) {
                    Text("Закрыть")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(Color("primary"))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("background"))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    
    func close() {
        dismiss()
    }
    
    func loadImages() {
        var internalImages:[UIImage] = []
        loadingCount = selectedItems.count
        isLoading = true
        
        for item in selectedItems {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    internalImages.append(uiImage)
                }
                loadingCount -= 1
                if loadingCount == 0 {
                    isLoading = false
                    images = internalImages
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

struct BottomSheetView: View {
    var onMakePhotot: () -> Void
    var onSelectFromGallery: () -> Void
    var body: some View {
        VStack(alignment: .leading) {
            Text("Старайтесь размещать одежду ближе к центру — так система точнее её распознает")
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(Color("primary"))
                .padding(.bottom, 16)
            Text("Сделать снимок")
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color("primary"))
                .contentShape(Rectangle())
                .onTapGesture {
                    onMakePhotot()
                }
            Divider().background(Color.tertiary)
            Text("Выбрать из галереи")
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color("primary"))
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelectFromGallery()
                }
            Spacer()
        }
        .padding(24)
        .background(Color.white)
    }
}

struct BottomSheetSortView: View {
    let sort: Sort
    var onSortTapped: (Sort) -> Void
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Sort.fromWhiteToBlack.text)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color("primary"))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSortTapped(.fromWhiteToBlack)
                    }
                Spacer()
                if sort == .fromWhiteToBlack {
                    Image(systemName: "checkmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color("primary"))
                        .frame(width: 20, height: 15)
                }
            }
            Divider().background(Color.tertiary)
            HStack {
                Text(Sort.similarity.text)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color("primary"))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSortTapped(.similarity)
                    }
                Spacer()
                if sort == .similarity {
                    Image(systemName: "checkmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color("primary"))
                        .frame(width: 20, height: 15)
                }
            }
            Divider().background(Color.tertiary)
            HStack {
                Text(Sort.none.text)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color("primary"))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSortTapped(.none)
                    }
                Spacer()
                if sort == .none {
                    Image(systemName: "checkmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color("primary"))
                        .frame(width: 20, height: 15)
                }
            }
            Spacer()
        }
        .padding(24)
        .background(Color.white)
    }
}

extension BottomSheetSortView {
    enum Sort {
        case fromWhiteToBlack
        case similarity
        case none
        
        var text: String {
            switch self {
            case .fromWhiteToBlack:
                return String(localized: "От светлого к темному")
            case .similarity:
                return String(localized: "Похожие цвета")
            case .none:
                return String(localized: "Без сортировки")
            }
        }
    }
}
