import SwiftUI

struct EmptyTabbarController: View {
    
    @EnvironmentObject var coordinator: TabBarCoordinator
    
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.backgroundColor = UIColor.white
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: "primary")!.withAlphaComponent(0.5)
    }
    
    var body: some View {
        TabView {
            EmptyWardrobeView()
                .environmentObject(coordinator)
                .tabItem {
                    VStack {
                        Image(uiImage: UIImage(named: "visor")!.resized(to: CGSize(width: 40, height: 40)))
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 8, height: 8)
                        Text("Лук")
                    }
                }
            EmptyWardrobeView()
                .environmentObject(coordinator)
                .tabItem {
                    VStack {
                        Image(uiImage: UIImage(named: "wardrobe")!.resized(to: CGSize(width: 40, height: 40)))
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        Text("Гардероб")
                    }
                }
        }
        .background(Color.white)
        .tint(Color("primary"))
    }
}

struct TabbarController: View {
    
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.backgroundColor = UIColor.white
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: "primary")!.withAlphaComponent(0.5)
    }
    
    var body: some View {
        TabView {
            MainView()
                .tabItem {
                    VStack {
                        Image(uiImage: UIImage(named: "visor")!.resized(to: CGSize(width: 40, height: 40)))
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                        Text("Лук")
                    }
                }
            WardrobeView()
                .tabItem {
                    VStack {
                        Image(uiImage: UIImage(named: "wardrobe")!.resized(to: CGSize(width: 40, height: 40)))
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                        Text("Гардероб")
                    }
                }
        }
        .background(Color.white)
        .tint(Color("primary"))
    }
}

struct TabbarController_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
    }
}

struct AppView: View {
    @StateObject private var coordinator = TabBarCoordinator()

    var body: some View {
        if coordinator.isEmptyWardrobe {
            EmptyTabbarController()
                .environmentObject(coordinator)
        } else {
            TabbarController()
        }
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
