import SwiftUI

final class MainViewModel: ObservableObject {
    @Published var selectedCategory: Event? = .casual
    var categrories: [Event] = [.casual, .formal, .workwear, .sport, .home]
}
