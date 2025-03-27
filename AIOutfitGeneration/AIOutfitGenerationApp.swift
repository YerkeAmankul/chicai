//
//  AIOutfitGenerationApp.swift
//  AIOutfitGeneration
//
//  Created by Yerkebulan Amankul on 18.03.2025.
//

import SwiftUI

@main
struct AIOutfitGenerationApp: App {
    @StateObject private var coordinator = TabBarCoordinator()
    
    var body: some Scene {
        WindowGroup {
            if coordinator.isEmptyWardrobe {
                EmptyTabbarController(coordinator: coordinator)
            } else {
                TabbarController()
            }
        }
    }
}
