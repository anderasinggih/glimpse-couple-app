import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.deepVelvet
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Sign in to connect with your partner.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                VStack(spacing: 16) {
                    CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                        .keyboardType(.emailAddress)
                    CustomTextField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)
                }
                .padding(.horizontal)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Button {
                    if validate() {
                        Task {
                            await login()
                        }
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.deepVelvet)
                        } else {
                            Text("Sign In")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(email.isEmpty || password.isEmpty ? Color.gray.opacity(0.3) : Color.electricPurple)
                    .foregroundColor(.deepVelvet)
                    .cornerRadius(12)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func validate() -> Bool {
        if !email.contains("@") || !email.contains(".") {
            errorMessage = "Please enter a valid email address."
            return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            return false
        }
        return true
    }
    
    private func login() async {
        hideKeyboard()
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

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.electricPurple)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .tint(.electricPurple) // Cursor color
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .tint(.electricPurple) // Cursor color
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1)))
        .contentShape(Rectangle()) // Ensure the whole area is tappable
    }
}
