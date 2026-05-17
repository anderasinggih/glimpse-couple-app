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
        @Bindable var bindableAuth = auth
        return ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                Group {
                    if auth.isAuthenticated {
                        MainDashboardView()
                    } else {
                        OnboardingView()
                    }
                }
                .transition(.identity) // No heavy transition here
                .zIndex(0)
            }
        }
        .animation(.linear(duration: 0.2), value: showSplash)
        .alert("Session Terminated", isPresented: $bindableAuth.showSessionTerminatedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your account has been logged in on another device. This session has been terminated.")
        }
        .task {
            // Very short splash for iOS 26 speed
            try? await Task.sleep(nanoseconds: 600_000_000)
            showSplash = false
        }
    }
}

#Preview {
    ContentView()
}
