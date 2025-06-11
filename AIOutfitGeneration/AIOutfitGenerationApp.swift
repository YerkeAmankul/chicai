//
//  AIOutfitGenerationApp.swift
//  AIOutfitGeneration
//
//  Created by Yerkebulan Amankul on 18.03.2025.
//
import FirebaseCore
import SwiftUI
import StoreKit
import FirebaseAnalytics

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(true)
        return true
    }
}

@main
struct AIOutfitGenerationApp: App {
    @StateObject private var startupManager = StartupManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            Group {
                if startupManager.isReady {
                    AppView()
                } else {
                    VStack {
                        Spacer()
                        Image(uiImage: UIImage(named: "appicon")!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(80)
                            .cornerRadius(16)
                        Spacer()
                    }.background(Color("background")).ignoresSafeArea()
                }
            }
            .task {
                await startupManager.initialize()
            }
        }
    }
}
