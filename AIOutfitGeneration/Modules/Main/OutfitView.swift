import SwiftUI

struct OutfitView: View {
    private let images: [String] = ["image1", "image2", "image3", "image4"]
    @State private var selectedImage: String

    init() {
        self._selectedImage = State(initialValue: images.first ?? "")
    }

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Image(selectedImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .shadow(radius: 5)
                .background(Color("background"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            Spacer()
            Text("Рекомендуемые аксессуары: Серебряные украшения")
                .foregroundColor(Color("primary"))
                .font(.system(size: 16, weight: .regular, design: .monospaced))
                .padding()
            Spacer()
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.2), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 10)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(images, id: \.self) { image in
                            Image(image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width/2.3, height: UIScreen.main.bounds.width/2.3)
                                .shadow(radius: 3)
                                .background(Color("background"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .onTapGesture {
                                    selectedImage = image
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedImage == image ? Color("primary") : Color.clear, lineWidth: 1.5)
                                ).padding(1)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 200)
            }
        }.background(Color.white)
    }
}
