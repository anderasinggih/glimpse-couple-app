//
//  GlimpseApp.swift
//  Glimpse
//
//  Created by LOVINPEACE on 16/05/26.
//

import SwiftUI

@main
struct GlimpseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // Start background location tracking safely after app has fully bootstrapped
                    LiveLocationManager.shared.startTracking()
                }
        }
    }
}
