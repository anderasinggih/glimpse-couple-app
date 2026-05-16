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
            
            VStack(spacing: 20) {
                // Header (Compact)
                VStack(spacing: 6) {
                    Text("Join Glimpse")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("The future of connection starts here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Liquid Glass Form
                VStack(spacing: 12) {
                    CustomGlassField(icon: "person.fill", placeholder: "Full Name", text: $name)
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
                
                // Action Button
                Button {
                    if validate() {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        Task { await register() }
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                                .font(.system(size: 16, weight: .bold))
                            Image(systemName: "sparkles")
                                .font(.caption)
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
                .disabled(isLoading || name.isEmpty || email.isEmpty || password.isEmpty)
                .padding(.horizontal)
                
                Spacer()
                
                Button("Already have an account? **Sign In**") {
                    dismiss()
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func validate() -> Bool {
        if name.count < 3 { return false }
        if !email.contains("@") { return false }
        if password.count < 8 { return false }
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
