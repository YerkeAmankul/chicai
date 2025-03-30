import SwiftUI
import _PhotosUI_SwiftUI

struct WardrobeView: View {
    
    @ObservedObject private var viewModel = WardrobeViewModel()
    @State private var showBottomSheet = false
    @State private var images: [UIImage]?
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var loadingCount = 0
    @State var isLoading = false
    @State private var startClassified = false
    @EnvironmentObject var coordinator: TabBarCoordinator
    
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text("Гардероб")
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .foregroundColor(Color("primary"))
                Spacer()
                if !isLoading {
                    Text("+")
                        .font(.system(size: 40))
                        .foregroundColor(Color("primary"))
                        .onTapGesture {
                            showBottomSheet = true
                        }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(Color("primary"))
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.categrories, id: \.text) { category in
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(viewModel.selectedCategory == category ? Color("primary") : Color.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1.5)
                            Text(category.text)
                                .foregroundColor(viewModel.selectedCategory == category ? .white : .black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .frame(minWidth: 60, maxHeight: 44)
                        .onTapGesture {
                            viewModel.selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.getItems(), id: \.fileName) { item in
                        VStack {
                            if let uiImage = UIImage(filename: item.fileName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(16)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .background(Color("background"))
                                    .background(Color.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.white)
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
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(images: $images)
            }
            .photosPicker(isPresented: $showGallery, selection: $selectedItems, matching: .images)
            .onChange(of: selectedItems) { _, _ in
                loadImages()
            }
            .onChange(of: images) { _, _ in
                startClassified = true
            }
            .fullScreenCover(isPresented: $startClassified) {
                let viewModel = ClassifyViewModel(coordinator: coordinator, images: images ?? [])
                ClassifyClothesView(viewModel: viewModel)
                    .environmentObject(coordinator)
            }
        }
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
}

extension UIImage {
    convenience init?(filename: String, scale: CGFloat = 1.0) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            let data = try Data(contentsOf: fileURL)
            self.init(data: data, scale: scale)
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }
}
