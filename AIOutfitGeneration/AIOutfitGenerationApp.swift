//
//  AIOutfitGenerationApp.swift
//  AIOutfitGeneration
//
//  Created by Yerkebulan Amankul on 18.03.2025.
//

import SwiftUI
import StoreKit

@main
struct AIOutfitGenerationApp: App {
    @StateObject private var startupManager = StartupManager()
    
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
