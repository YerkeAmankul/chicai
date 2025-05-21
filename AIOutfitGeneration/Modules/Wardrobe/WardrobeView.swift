import SwiftUI
import _PhotosUI_SwiftUI

struct WardrobeView: View {
    
    @ObservedObject private var viewModel = WardrobeViewModel()
    @State private var showBottomSheet = false
    @State private var showIAP = false
    @State private var showSortBottomSheet = false
    @State private var showEditBottomSheet = false
    @State private var images: [UIImage]?
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var loadingCount = 0
    @State var isLoading = false
    @State private var startClassified = false
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    private var maxFreeWardrobeCount: Int? {
        IAPManager.shared.isSubscribed ? nil : 10
    }
    
    @EnvironmentObject var coordinator: TabBarCoordinator
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text("Гардероб")
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .foregroundColor(Color("primary"))
                Spacer()
                if !isLoading {
                    HStack(alignment: .center) {
                        Image(uiImage: UIImage(named: "sort")!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Color("primary"))
                            .padding(.top, 4)
                            .frame(width: 26, height: 26)
                            .onTapGesture {
                                showSortBottomSheet = true
                            }
                        Text("+")
                            .font(.system(size: 40))
                            .foregroundColor(Color("primary"))
                            .onTapGesture {
                                if let maxFreeWardrobeCount {
                                    if viewModel.getItems().count < maxFreeWardrobeCount {
                                        showBottomSheet = true
                                    } else {
                                        showIAP = true
                                    }
                                } else {
                                    showBottomSheet = true
                                }
                            }
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
            itemsView(items: viewModel.getItems())
            .sheet(isPresented: $showBottomSheet) {
                BottomSheetView(onMakePhotot: {
                    showBottomSheet = false
                    showCamera = true
                }, onSelectFromGallery: {
                    selectedItems.removeAll()
                    showBottomSheet = false
                    showGallery = true
                })
                .presentationDetents([.fraction(0.3)])
            }
            .sheet(isPresented: $showSortBottomSheet) {
                BottomSheetSortView(sort: viewModel.sortByColor) { type in
                    showSortBottomSheet = false
                    viewModel.sortByColor = type
                }
                .presentationDetents([.fraction(0.26)])
            }
            .sheet(isPresented: $showEditBottomSheet) {
                EditItemView(onDeleteTapped: {
                    showEditBottomSheet = false
                    viewModel.onDeleteItem()
                    viewModel.editingItemFileName = nil
                    viewModel.selectedCategory = viewModel.selectedCategory
                }, onLayerChanged: { layer in
                    showEditBottomSheet = false
                    viewModel.onEditLayerItem(layer: layer)
                    viewModel.editingItemFileName = nil
                    viewModel.selectedCategory = viewModel.selectedCategory
                }, selectedLayer: viewModel.editingItemLayer)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(images: $images)
            }
            .photosPicker(
                isPresented: $showGallery,
                selection: $selectedItems,
                maxSelectionCount: maxFreeWardrobeCount == nil ? nil : (maxFreeWardrobeCount! - viewModel.getItems().count),
                matching: .images
            )
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
            .sheet(isPresented: $showIAP) {
                IAPView(manager: subscriptionManager)
                    .onAppear {
                        subscriptionManager.onSubscriptionSuccess = {
                            showIAP = false
                            showBottomSheet = true
                        }
                    }
            }
        }
    }
    
    func itemsView(items: [WardrobeItem]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items, id: \.fileName) { item in
                    VStack {
                        ZStack(alignment: .topTrailing) {
                            AsyncDownsampledImage(filePath: item.fileName, size: CGSize(width: 200, height: 200))
                                .id(item.fileName)
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color("background"))
                                .background(Color.white)
                                .cornerRadius(8)
                            Button(action: {
                                viewModel.editingItemFileName = item.fileName
                                showEditBottomSheet = true
                            }) {
                                Image(uiImage: UIImage(named: "editing")!.withRenderingMode(.alwaysTemplate))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(Color("secondary"))
                                    .padding(8)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.white)
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
