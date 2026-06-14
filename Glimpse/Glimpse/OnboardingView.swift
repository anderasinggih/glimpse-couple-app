import SwiftUI

struct OnboardingView: View {
    @State private var navigateToLogin = false
    @State private var navigateToSignup = false
    @State private var isShowingToS = false
    @State private var isShowingPrivacyPolicy = false
    @State private var showMockAppleSimulation = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var isPureBlack = true
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                Color.adaptiveBackground.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.electricPurple)
                            .shadow(color: .electricPurple.opacity(0.5), radius: 20)
                        
                        Text("Glimpse")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Intimacy beyond words.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .transition(.opacity)
                        }
                        
                        Button { navigateToSignup = true } label: {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.deepVelvet)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.electricPurple)
                                .cornerRadius(16)
                        }
                        
                        // Apple Sign In Button
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showMockAppleSimulation = true
                        } label: {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 18))
                                    Text("Sign in with Apple")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(16)
                        }
                        .disabled(isLoading)
                        
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.white.opacity(0.5))
                            
                            Button("Login") { navigateToLogin = true }
                            .fontWeight(.bold)
                            .foregroundColor(.electricPurple)
                        }
                        .font(.subheadline)
                        .padding(.top, 4)
                        
                        VStack(spacing: 4) {
                            Text("By continuing, you agree to our")
                                .foregroundColor(.white.opacity(0.5))
                            HStack(spacing: 4) {
                                Button("Terms of Service") { isShowingToS = true }
                                    .foregroundColor(.electricPurple)
                                    .fontWeight(.semibold)
                                Text("and")
                                    .foregroundColor(.white.opacity(0.5))
                                Button("Privacy Policy") { isShowingPrivacyPolicy = true }
                                    .foregroundColor(.electricPurple)
                                    .fontWeight(.semibold)
                             }
                        }
                        .font(.caption2)
                        .padding(.top, 12)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
                
                // Top Right Theme Toggle Switch
                themeToggleView
                    .padding(.top, 16)
                    .padding(.trailing, 20)
                    .zIndex(10)
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
            }
            .navigationDestination(isPresented: $navigateToSignup) {
                SignupView()
            }
        }
        .sheet(isPresented: $isShowingToS) {
            LegalPlaceholderView(
                title: "Terms of Service",
                text: LegalTexts.tos
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingPrivacyPolicy) {
            LegalPlaceholderView(
                title: "Privacy Policy",
                text: LegalTexts.privacy
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Simulate Apple Sign-In", isPresented: $showMockAppleSimulation, titleVisibility: .visible) {
            Button("Sign In as Bob (Mock Apple)") {
                Task {
                    await simulateAppleLogin(id: "apple_mock_bob", email: "bob.apple@glimpse.test", name: "Bob Apple")
                }
            }
            Button("Sign In as Alice (Mock Apple)") {
                Task {
                    await simulateAppleLogin(id: "apple_mock_alice", email: "alice.apple@glimpse.test", name: "Alice Apple")
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Since this app is in local development without a Paid Apple Developer Account, you can simulate Apple Sign-In with these test profiles.")
        }
        .onAppear {
            let suite = UserDefaults(suiteName: "group.glimpse.app")
            if suite?.object(forKey: "glimpse_background_theme") == nil {
                suite?.set("pure_black", forKey: "glimpse_background_theme")
                isPureBlack = true
            } else {
                let current = suite?.string(forKey: "glimpse_background_theme") ?? "pure_black"
                isPureBlack = (current == "pure_black" || current == "dark")
            }
        }
    }
    
    private var themeToggleView: some View {
        HStack(spacing: 6) {
            Image(systemName: isPureBlack ? "moon.fill" : "sun.max.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isPureBlack ? .white : .yellow)
                .transition(.scale.combined(with: .opacity))
                .id(isPureBlack)
            
            Text(isPureBlack ? "Pure Black" : "Bg Default")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 5)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPureBlack.toggle()
                let suite = UserDefaults(suiteName: "group.glimpse.app")
                suite?.set(isPureBlack ? "pure_black" : "default", forKey: "glimpse_background_theme")
            }
        }
    }
    
    private func simulateAppleLogin(id: String, email: String, name: String) async {
        isLoading = true
        errorMessage = ""
        do {
            try await AuthManager.shared.loginWithApple(
                appleUserId: id,
                email: email,
                name: name,
                identityToken: "mock_identity_token_\(id)"
            )
        } catch {
            withAnimation { errorMessage = error.localizedDescription }
        }
        isLoading = false
    }
}

#Preview {
    OnboardingView()
}
