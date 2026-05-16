import SwiftUI

struct OnboardingView: View {
    @State private var navigateToLogin = false
    @State private var navigateToSignup = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deepVelvet.ignoresSafeArea()
                
                // Hero Background
                Circle()
                    .fill(Color.electricPurple.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 60)
                    .offset(y: -250)
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Logo/Hero Section
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
                    
                    // Actions
                    VStack(spacing: 16) {
                        Button {
                            navigateToSignup = true
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.deepVelvet)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.electricPurple)
                                .cornerRadius(16)
                                .shadow(color: .electricPurple.opacity(0.3), radius: 10, y: 5)
                        }
                        
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.white.opacity(0.5))
                            
                            Button("Login") {
                                navigateToLogin = true
                            }
                            .fontWeight(.bold)
                            .foregroundColor(.electricPurple)
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
            }
            .navigationDestination(isPresented: $navigateToSignup) {
                SignupView()
            }
        }
    }
}

#Preview {
    OnboardingView()
}
