import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            iOS26Background()
            
            VStack(spacing: 32) {
                // Hero Branding
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.electricPurple, Color.activeCyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: Color.electricPurple.opacity(0.5), radius: 20)
                    
                    Text("Glimpse")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .tracking(-0.5)
                }
                .padding(.top, 60)
                
                // Native-feel Form with Material
                VStack(spacing: 0) {
                    CustomNativeField(icon: "envelope.fill", placeholder: "Email", text: $email)
                    Divider().padding(.leading, 50).opacity(0.1)
                    CustomNativeField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
                .padding(.horizontal)
                
                if !errorMessage.isEmpty {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Futuristic Action Button
                Button {
                    if validate() {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { await login() }
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.deepVelvet)
                        } else {
                            Text("Sign In")
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.electricPurple)
                .clipShape(Capsule())
                .padding(.horizontal)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                Spacer()
                
                // Footer
                NavigationLink(destination: SignupView()) {
                    HStack {
                        Text("Don't have an account?")
                        Text("Create One").bold()
                    }
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onTapGesture { hideKeyboard() }
    }
    
    private func validate() -> Bool {
        if !email.contains("@") {
            errorMessage = "Invalid email format"
            return false
        }
        if password.count < 6 {
            errorMessage = "Password too short"
            return false
        }
        return true
    }
    
    private func login() async {
        isLoading = true
        errorMessage = ""
        do {
            try await AuthManager.shared.login(email: email.lowercased().trimmingCharacters(in: .whitespaces), password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct CustomNativeField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.electricPurple)
                .font(.system(size: 20))
                .frame(width: 24)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
        }
        .padding(20)
    }
}
