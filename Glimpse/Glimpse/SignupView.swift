import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password
    }
    
    var body: some View {
        ZStack {
            // Background tap to dismiss keyboard
            Color.deepVelvet
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
                            .background(Color.white.opacity(0.01))
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 10)
                .zIndex(10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Join Glimpse")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Start your intimate journey today.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                VStack(spacing: 16) {
                    CustomTextField(icon: "person.fill", placeholder: "Full Name", text: $name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onTapGesture { focusedField = .name }
                    
                    CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onTapGesture { focusedField = .email }
                    
                    CustomTextField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onTapGesture { focusedField = .password }
                }
                .onSubmit {
                    if focusedField == .name { focusedField = .email }
                    else if focusedField == .email { focusedField = .password }
                    else { focusedField = nil }
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
                            await register()
                        }
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.deepVelvet)
                        } else {
                            Text("Create Account")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(name.isEmpty || email.isEmpty || password.isEmpty ? Color.gray.opacity(0.3) : Color.electricPurple)
                    .foregroundColor(.deepVelvet)
                    .cornerRadius(12)
                }
                .disabled(isLoading || name.isEmpty || email.isEmpty || password.isEmpty)
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func validate() -> Bool {
        if name.count < 3 {
            errorMessage = "Please enter your full name."
            return false
        }
        if !email.contains("@") || !email.contains(".") {
            errorMessage = "Please enter a valid email address."
            return false
        }
        if password.count < 8 {
            errorMessage = "Password must be at least 8 characters."
            return false
        }
        return true
    }
    
    private func register() async {
        hideKeyboard()
        isLoading = true
        errorMessage = ""
        do {
            try await AuthManager.shared.register(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
