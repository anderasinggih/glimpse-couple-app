import SwiftUI

struct OnboardingView: View {
    @State private var navigateToLogin = false
    @State private var navigateToSignup = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deepVelvet.ignoresSafeArea()
                
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
                        Button { navigateToSignup = true } label: {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.deepVelvet)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.electricPurple)
                                .cornerRadius(16)
                        }
                        
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.white.opacity(0.5))
                            
                            Button("Login") { navigateToLogin = true }
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
