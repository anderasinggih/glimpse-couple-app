struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            iOS26Background()
            
            VStack(spacing: 20) {
                // Hero Branding (Compact)
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.electricPurple, Color.activeCyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: Color.electricPurple.opacity(0.4), radius: 15)
                    
                    Text("Glimpse")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .tracking(-0.5)
                }
                .padding(.top, 50)
                
                // Liquid Glass Form
                VStack(spacing: 12) {
                    CustomGlassField(icon: "envelope.fill", placeholder: "Email", text: $email)
                    CustomGlassField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)
                }
                .padding(.horizontal)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.horizontal)
                }
                
                // Compact Glass Button
                Button {
                    if validate() {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        Task { await login() }
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color.electricPurple, Color.royalPurple], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.electricPurple.opacity(0.3), radius: 10, y: 4)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal)
                
                Spacer()
                
                NavigationLink(destination: SignupView()) {
                    Text("Don't have an account? **Create One**")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onTapGesture { hideKeyboard() }
    }
    
    private func validate() -> Bool {
        if !email.contains("@") { return false }
        if password.count < 6 { return false }
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

struct CustomGlassField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.electricPurple)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial.opacity(0.5))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}
