import SwiftUI

struct WardrobeView: View {
    @State private var selectedCategory: String = "Все"
    let categories = ["Все", "Рубашки", "Брюки", "Обувь", "Аксессуары"]
    
    let items = Array(1...10).map { "Item \($0)" } // Dummy data
    
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var filteredItems: [String] {
        selectedCategory == "Все" ? items : items.filter { _ in Bool.random() }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Гардероб")
                .font(.system(size: 30, weight: .bold, design: .default))
                .padding(.horizontal)
                .foregroundColor(Color("primary"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedCategory == category ? Color("primary") : Color.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 4)
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
                    ForEach(filteredItems, id: \.self) { item in
                        Text("")
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color("background"))
                            .background(Color.white)
                            .cornerRadius(8)
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
