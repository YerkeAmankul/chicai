//import SwiftUI
//import VisionKit
//import Vision
//import PhotosUI
//
//struct ContentView1: View {
//    
//    @State private var userPickedImages: [UIImage] = []
//    @State private var userPickedImageItems: [PhotosPickerItem] = []
//    
//    /* Stores detected objects and extracted images per image */
//    @State private var detectedObjectsPerImage: [UIImage: Set<ImageAnalysisInteraction.Subject>] = [:]
//    @State private var extractedObjectsPerImage: [UIImage: UIImage] = [:]
//    
//    /* Each image needs its own ImageAnalysisViewModel */
//    @State private var imageViewModels: [UIImage: ImageAnalysisViewModel] = [:]
//    
//    /* Error Handling */
//    @State private var errorMessage: String?
//    
//    var body: some View {
//        ScrollView {
//            VStack {
//                
//                /* Image Picker */
//                PhotosPicker(selection: $userPickedImageItems, maxSelectionCount: 5, matching: .images) {
//                    Image(systemName: "photo")
//                }
//                .onChange(of: userPickedImageItems) { _, newValue in
//                    Task { @MainActor in
//                        do {
//                            userPickedImages.removeAll()
//                            detectedObjectsPerImage.removeAll()
//                            extractedObjectsPerImage.removeAll()
//                            imageViewModels.removeAll()
//                            
//                            for item in newValue {
//                                if let loadedImageData = try await item.loadTransferable(type: Data.self),
//                                   let loadedImage = UIImage(data: loadedImageData) {
//                                    userPickedImages.append(loadedImage)
//                                    imageViewModels[loadedImage] = ImageAnalysisViewModel() // Assign unique ViewModel
//                                }
//                            }
//                            
//                            // Process images in parallel
//                            await withTaskGroup(of: (UIImage, Set<ImageAnalysisInteraction.Subject>, UIImage?).self) { group in
//                                for image in userPickedImages {
//                                    if let viewModel = imageViewModels[image] {
//                                        group.addTask {
//                                            do {
//                                                let detectedObjects = try await viewModel.analyzeImage(image)
//                                                let extractedImage = try await viewModel.interaction.image(for: detectedObjects)
//                                                return (image, detectedObjects, extractedImage)
//                                            } catch {
//                                                return (image, [], nil)
//                                            }
//                                        }
//                                    }
//                                }
//                                
//                                for await (image, detectedObjects, extractedImage) in group {
//                                    detectedObjectsPerImage[image] = detectedObjects
//                                    extractedObjectsPerImage[image] = extractedImage
//                                }
//                            }
//                        } catch {
//                            self.errorMessage = error.localizedDescription
//                        }
//                    }
//                }
//                
//                /* Display Selected Images and Extracted Objects */
//                ForEach(userPickedImages, id: \.cgImage) { image in
//                    if let viewModel = imageViewModels[image] { // Get correct ViewModel
//                        VStack {
////
//                            if let extractedImage = extractedObjectsPerImage[image] {
//                                Text("Extracted Objects").font(.headline)
//                                Image(uiImage: extractedImage)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .padding()
//                                    .background(RoundedRectangle(cornerRadius: 10).foregroundStyle(.teal))
//                                    .frame(height: 300)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
//@MainActor
//class ImageAnalysisViewModel: NSObject, ObservableObject {
//    let analyzer = ImageAnalyzer()
//    let interaction = ImageAnalysisInteraction()
//    var loadedImageView: UIImageView?
//    
//    func analyzeImage(_ image: UIImage) async throws -> Set<ImageAnalysisInteraction.Subject> {
//        let configuration = ImageAnalyzer.Configuration([.visualLookUp])
//        let analysis = try await analyzer.analyze(image, configuration: configuration)
//        interaction.analysis = analysis
//        let detectedSubjects = await interaction.subjects
//        return detectedSubjects
//    }
//}
