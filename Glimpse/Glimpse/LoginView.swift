import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showForgotPassword = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            // Background tap to dismiss keyboard
            Color.adaptiveBackground
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                }
            
            VStack(spacing: 24) {
                // Back Button Row
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(12) // Wider hit area
                            .background(Color.white.opacity(0.01)) // Make the padding clickable
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 10) // Extra breathing room
                .zIndex(10)
                
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
                    CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $email, maxLength: 100)
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .id("login-email-field")
                        .onTapGesture { focusedField = .email } // Click anywhere in container
                    
                    CustomTextField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true, maxLength: 32)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .id("login-password-field")
                        .onTapGesture { focusedField = .password } // Click anywhere in container
                    
                    HStack {
                        Spacer()
                        Button {
                            showForgotPassword = true
                        } label: {
                            Text("Forgot password?")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.electricPurple)
                        }
                    }
                    .padding(.top, 4)
                }
                .onSubmit {
                    if focusedField == .email {
                        focusedField = .password
                    } else {
                        focusedField = nil
                    }
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
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private func validate() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return false
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return false
        }
        return true
    }
    
    private func login() async {
        focusedField = nil
        isLoading = true
        errorMessage = ""
        do {
            try await AuthManager.shared.login(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                password: password
            )
        } catch {
            withAnimation { errorMessage = error.localizedDescription }
        }
        isLoading = false
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var maxLength: Int = 100
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.electricPurple)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .onChange(of: text) { oldValue, newValue in
            if newValue.count > maxLength {
                text = String(newValue.prefix(maxLength))
            }
        }
    }
}
