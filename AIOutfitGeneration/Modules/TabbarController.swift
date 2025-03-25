import SwiftUI

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
                        Image(uiImage: UIImage(named: "visor")!)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 8, height: 8)
                        Text("Лук")
                    }
                }
            WardrobeView()
//            EmptyWardrobeView()
                .tabItem {
                    VStack {
                        Image(uiImage: UIImage(named: "wardrobe")!)
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

struct TabbarController_Previews: PreviewProvider {
    static var previews: some View {
        TabbarController()
    }
}
