//
//  GlimpseApp.swift
//  Glimpse
//
//  Created by LOVINPEACE on 16/05/26.
//

import SwiftUI

@main
struct GlimpseApp: App {
    init() {
        // Start background location tracking immediately on application launch (including background location wakeups!)
        LiveLocationManager.shared.startTracking()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
