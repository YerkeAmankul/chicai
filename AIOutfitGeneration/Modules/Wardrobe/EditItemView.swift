import SwiftUI

struct EditItemView: View {
    
    var onDeleteTapped: () -> Void
    var onLayerChanged: (Layer) -> Void
    
    var layers: [Layer] = [.base, .mid, .outer, .material, .footwear, .accessory]
    
    @State var selectedLayer: Layer?
    @State var isLayerChanged: Bool = false
    @State var sureToDelete: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Выберите один из вариантов, чтобы сменить тип одежды")
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Color("primary"))
                TagsView(tags: layers, selectedTag: $selectedLayer)
                    .background(Color("background"))
                    .cornerRadius(16)
                    .padding(.bottom)
                if isLayerChanged {
                    Button(action: saveChanges) {
                        Text("Сохранить")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("primary"))
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }.padding(.bottom)
                }
                Divider().background(Color.tertiary)
                if sureToDelete {
                    VStack(spacing: 8) {
                        Text("Вы действительно хотите удалить этот элемент из своего гардероба?")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Color("primary"))
                            .padding(.bottom, 16)
                        HStack(spacing: 16) {
                            Button(action: saveChanges) {
                                Text("Да")
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color("primary"))
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        onDeleteTapped()
                                    }
                            }.padding(.bottom)
                            Button(action: saveChanges) {
                                Text("Нет")
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color("primary"))
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color("background"))
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        sureToDelete = false
                                    }
                            }.padding(.bottom)
                        }
                    }.padding(.vertical, 16)
                } else {
                    Text("Удалить")
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.red)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            sureToDelete = true
                        }
                }
                Spacer()
            }
            .padding(24)
            .background(Color.white)
            .onChange(of: selectedLayer) { newValue, oldValue in
                isLayerChanged = true
            }
        }
    }
    
    private func saveChanges() {
        guard let selectedLayer else { return }
        onLayerChanged(selectedLayer)
    }
    
    struct TagsView: View {
        let tags: [Layer]
        @Binding var selectedTag: Layer?

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
        
        private func tagItemView(_ tag: Layer) -> some View {
            let isSelected = selectedTag == tag
            return Text(tag.text)
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
       
        private func toggleSelection(_ tag: Layer) {
            if selectedTag == tag {
                selectedTag = nil
            } else {
                selectedTag = tag
            }
        }
    }
}
