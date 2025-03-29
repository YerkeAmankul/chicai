import SwiftUI

struct WardrobeView: View {
    @State private var selectedCategory: String = "Все"
    let categories = ["Все", "Рубашки", "Брюки", "Обувь", "Аксессуары"]
        
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Гардероб")
                .font(.system(size: 30, weight: .bold, design: .default))
                .padding(.horizontal)
                .foregroundColor(Color("primary"))
                .padding(.top, 24)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedCategory == category ? Color("primary") : Color.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1.5)
                            Text(category)
                                .foregroundColor(selectedCategory == category ? .white : .black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .frame(minWidth: 60, maxHeight: 44)
                        .onTapGesture {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Garderob.shared.clothes, id: \.2) { item in
                        VStack {
                            Image(uiImage: item.2)
                                .resizable()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color("background"))
                                .background(Color.white)
                                .cornerRadius(8)
                            Text(item.0).foregroundColor(Color(cgColor: item.1))
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.white)
        
    }
}

struct WardrobeView_Previews: PreviewProvider {
    static var previews: some View {
        WardrobeView()
    }
}
