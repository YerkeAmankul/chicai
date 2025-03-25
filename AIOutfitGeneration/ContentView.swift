//
//  ContentView.swift
//  AIOutfitGeneration
//
//  Created by Yerkebulan Amankul on 18.03.2025.
//

import SwiftUI
import UIKit
import DominantColors
import VisionKit
import Vision
import PhotosUI

struct ContentView: View {
    
    @State private var colors: [CGColor] = []
    
    var body: some View {
        ObjectExtraction()
//        VStack {
//            Text("Colors")
//            ForEach(colors, id: \.complementaryColor) {
//                Color(cgColor: $0).frame(width: .infinity, height: 44)
//            }
//        }
//        .padding()
//        .onAppear {
//            
//        }
    }
    
//    func fetchColors() {
//        if let image = UIImage(named: "jeand") {
//            do {
//                
//                let dominantColors = try image.dominantColors()
//                let contrastColors = ContrastColors(colors: dominantColors.map({ $0.cgColor }))
//
//                let backgroundColor = contrastColors?.background
//                let primaryColor = contrastColors?.primary
//                let secondaryColor = contrastColors?.secondary
//                
//                colors = [backgroundColor!, primaryColor!, secondaryColor!]
//            } catch {}
//        }
//    }
}

struct ObjectExtraction: View {
    
    @State private var userPickedImage: UIImage?
    @State private var userPickedImageItem: [PhotosPickerItem] = []
    
    /* image analysis result */
    @State private var detectedObjects: Set<ImageAnalysisInteraction.Subject> = []
    
    /* code related to image extraction */
    @StateObject private var viewModel = ImageAnalysisViewModel()
    @State private var extractedObjectImage: UIImage?
    @State private var imageForAllSelectedObjects: UIImage?
    
    /* code related to error reporting */
    @State private var errorMessage: String?
    
    var body: some View {
        
        ScrollView {
            VStack {
                
                /* image picker */
                PhotosPicker(
                    selection: $userPickedImageItem,
                    maxSelectionCount: 1,
                    matching: .images) {
                        Image(systemName: "photo")
                    }
                    .onChange(of: userPickedImageItem) { _, newValue in
                        Task { @MainActor in
                            do {
                                // load the image
                                guard let loadedImageData = try await newValue.first?.loadTransferable(type: Data.self),
                                      let loadedImage = UIImage(data: loadedImageData) else { return }
                                self.userPickedImage = loadedImage
                                // analyze this image
                                self.detectedObjects = try await self.viewModel.analyzeImage(loadedImage)
                            } catch {
                                self.errorMessage = error.localizedDescription
                            }
                        }
                    }
                /* */
                
                if let userPickedImage {
                    VStack {
                        Text("Image picked")
                            .font(.headline)
                        ObjectPickableImageView(imageObject: userPickedImage)
                            .scaledToFit()
                            .cornerRadius(20)
                            .frame(height: 350)
                            .environmentObject(viewModel)
                            .onTapGesture { tappedLocation in
                                Task { @MainActor in
                                    if let tappedSubject = await self.viewModel.interaction.subject(at: tappedLocation) {
                                        // select or de-select it
                                        if self.viewModel.interaction.highlightedSubjects.contains(tappedSubject) {
                                            self.viewModel.interaction.highlightedSubjects.remove(tappedSubject)
                                        } else {
                                            self.viewModel.interaction.highlightedSubjects.insert(tappedSubject)
                                        }
                                    }
                                }
                            }
                    }
                }
                
                HStack {
                    
                    if let extractedObjectImage {
                        VStack {
                            Text("Single object")
                                .font(.headline)
                            Image(uiImage: extractedObjectImage)
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundStyle(.teal)
                                }
                                .frame(height: 300)
                        }
                    }
                    
                    if let imageForAllSelectedObjects {
                        VStack {
                            Text("All objects")
                                .font(.headline)
                            Image(uiImage: imageForAllSelectedObjects)
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundStyle(.teal)
                                }
                                .frame(height: 300)
                            ForEach(fetchColors(image: imageForAllSelectedObjects), id: \.complementaryColor) {
                                Color(cgColor: $0).frame(width: .infinity, height: 44)
                            }
                        }
                    }
                    
                    
                }
                .padding()
                
                Text("Detected objects count")
                    .font(.headline)
                
                Text("\(self.detectedObjects.count)")
                
                LazyVGrid(columns: [
                    .init(.flexible()),
                    .init(.flexible())
                ]) {
                    ForEach(self.detectedObjects.sorted(by: { one, two in
                        return one.bounds.minX < two.bounds.minX
                    }), id: \.hashValue) { object in
                        VStack(alignment: .leading) {
                            Text("Position: x \(object.bounds.origin.x) y \(object.bounds.origin.y)")
                            Text("Size: width \(object.bounds.width) height \(object.bounds.height)")
                            Text("Object hash: \(object.hashValue)")
                            // highlight
                            Button("Select") {
                                self.viewModel.interaction.highlightedSubjects.insert(object)
                                // generate an image with all currently highlighted objects
                                Task { @MainActor in
                                    do {
                                        try await generateImageForAllSelectedObjects()
                                    } catch {
                                        self.errorMessage = error.localizedDescription
                                    }
                                }
                            }
                            // extract this to an image
                            Button("Extract") {
                                Task { @MainActor in
                                    if let objectImage = try? await object.image {
                                        self.extractedObjectImage = objectImage
                                    }
                                }
                            }
                            // remove selection
                            Button("Un-select") {
                                self.viewModel.interaction.highlightedSubjects.remove(object)
                                // generate an image with all currently highlighted objects
                                Task { @MainActor in
                                    do {
                                        try await generateImageForAllSelectedObjects()
                                    } catch {
                                        self.errorMessage = error.localizedDescription
                                    }
                                }
                            }
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(Color(uiColor: .systemGroupedBackground))
                        }
                    }
                }
                
                Text("Long press on an object within the image to copy.")
                
            }
        }
        .alert(item: $errorMessage) { message in
            Alert(title: Text("Error while analyzing objects within the image"), message: Text(message))
        }
        
    }
    
    func generateImageForAllSelectedObjects() async throws {
        let allSubjectsImage = try await self.viewModel.interaction.image(for: self.viewModel.interaction.highlightedSubjects)
        self.imageForAllSelectedObjects = allSubjectsImage
    }
    
    func fetchColors(image: UIImage) -> [CGColor] {
        do {
            
            let dominantColors = try DominantColors.dominantColors(uiImage: image, algorithm: .CIEDE2000, maxCount: 3, sorting: .frequency)
            return dominantColors.map { $0.cgColor }
        } catch {
            return []
        }
    }
    
}

extension String: Identifiable {
    public var id: String { return self }
}

//#Preview {
//    ObjectExtraction()
//}

@MainActor
class ImageAnalysisViewModel: NSObject, ObservableObject {
    let analyzer = ImageAnalyzer()
    let interaction = ImageAnalysisInteraction()
    var loadedImageView: UIImageView?
    
    func analyzeImage(_ image: UIImage) async throws -> Set<ImageAnalysisInteraction.Subject> {
        let configuration = ImageAnalyzer.Configuration([.visualLookUp])
        let analysis = try await analyzer.analyze(image, configuration: configuration)
        interaction.analysis = analysis
        let detectedSubjects = await interaction.subjects
        return detectedSubjects
    }
}

@MainActor
struct ObjectPickableImageView: UIViewRepresentable {
    
    var imageObject: UIImage
    
    @EnvironmentObject var viewModel: ImageAnalysisViewModel
    
    func makeUIView(context: Context) -> CustomizedUIImageView {
        let imageView = CustomizedUIImageView()
        
        // configure the view with image object and analyzer interaction
        imageView.image = imageObject
        imageView.contentMode = .scaleAspectFit
        viewModel.interaction.preferredInteractionTypes = [.imageSubject]
        imageView.addInteraction(viewModel.interaction)
        
        viewModel.loadedImageView = imageView
        
        return imageView
    }
    
    func updateUIView(_ uiView: CustomizedUIImageView, context: Context) { }
    
}

class CustomizedUIImageView: UIImageView {
    override var intrinsicContentSize: CGSize {
        .zero
    }
}
