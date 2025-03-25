import SwiftUI

struct TagsView: View {
    let tags: [String]
    @Binding var selectedTag: String?

    var body: some View {
        FlowLayoutView(items: tags) { tag in
            tagItemView(tag)
                .onTapGesture {
                    toggleSelection(tag)
                }
                .animation(.easeInOut, value: selectedTag)
        }
        .padding()
    }
    
    private func tagItemView(_ tag: String) -> some View {
        let isSelected = selectedTag == tag
        return Text(tag)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color("primary") : Color.white)
            .foregroundColor(isSelected ? Color.white : Color("primary"))
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.gray, lineWidth: 1)
            )
            .cornerRadius(16)
            .animation(.easeInOut, value: selectedTag)
    }
    
    private func toggleSelection(_ tag: String) {
        if selectedTag == tag {
            selectedTag = nil
        } else {
            selectedTag = tag
        }
    }
}

struct FlowLayoutView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in
            createWrappedLayout(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func createWrappedLayout(in geometry: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var currentRow: [Data.Element] = []
        var rows: [[Data.Element]] = []

        for item in items {
            let itemWidth: CGFloat = estimatedTextWidth(for: item) + 32
            if width + itemWidth > geometry.size.width {
                rows.append(currentRow)
                currentRow = []
                width = 0
                height += 49
            }
            currentRow.append(item)
            width += itemWidth + 8
        }
        rows.append(currentRow)

        DispatchQueue.main.async {
            totalHeight = height + 49
        }

        return VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                }
            }
        }
    }

    private func estimatedTextWidth(for text: Data.Element) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 17, weight: .medium)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (String(describing: text) as NSString).size(withAttributes: attributes)
        return size.width
    }
}
