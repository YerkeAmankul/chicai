import SwiftUI

class TabBarCoordinator: ObservableObject {
    @Published var isEmptyWardrobe: Bool = true
    @Published var goToRoot: Bool = false {
        didSet {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = scene.windows.first?.rootViewController else {
                return
            }
            
            rootViewController.dismiss(animated: false)
        }
    }
}
