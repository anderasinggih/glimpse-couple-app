//
//  ContentView.swift
//  Glimpse
//
//  Created by LOVINPEACE on 16/05/26.
//

import SwiftUI

struct ContentView: View {
    @State private var auth = AuthManager.shared
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea() // BG Permanen sejak detik 0
            
            if showSplash {
                SplashScreenView()
                    .transition(.opacity.combined(with: .scale))
            } else {
                Group {
                    if auth.isAuthenticated {
                        MainDashboardView()
                    } else {
                        OnboardingView()
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.8), value: showSplash)
        .animation(.smooth, value: auth.isAuthenticated)
        .task {
            // Splash duration - Optimized for iOS 26 speed
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.smooth(duration: 0.6)) {
                showSplash = false
            }
        }
    }
}

#Preview {
    ContentView()
}
