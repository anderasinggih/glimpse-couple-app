import SwiftUI

struct SignupView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            iOS26Background()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text("Join Glimpse")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .tracking(-0.5)
                    Text("The future of connection starts here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Form Container
                VStack(spacing: 0) {
                    CustomNativeField(icon: "person.fill", placeholder: "Full Name", text: $name)
                    Divider().padding(.leading, 50).opacity(0.1)
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
                }
                
                // Action Button
                Button {
                    if validate() {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { await register() }
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.deepVelvet)
                        } else {
                            Text("Create Account")
                                .fontWeight(.bold)
                            Image(systemName: "sparkles")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.electricPurple)
                .clipShape(Capsule())
                .padding(.horizontal)
                .disabled(isLoading || name.isEmpty || email.isEmpty || password.isEmpty)
                
                Spacer()
                
                Button("Already have an account? Sign In") {
                    dismiss()
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.bold())
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func validate() -> Bool {
        if name.count < 3 {
            errorMessage = "Full name required"
            return false
        }
        if !email.contains("@") {
            errorMessage = "Invalid email format"
            return false
        }
        if password.count < 8 {
            errorMessage = "Password must be 8+ chars"
            return false
        }
        return true
    }
    
    private func register() async {
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
