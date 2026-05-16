import SwiftUI

struct ProfileView: View {
    @State private var auth = AuthManager.shared
    @State private var inviteCodeInput = ""
    @State private var isShowingInviteAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea()
            iOS26Background().opacity(0.4)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Profile Header (Self)
                    if let user = auth.currentUser {
                        VStack(spacing: 16) {
                            AsyncImage(url: URL(string: user.profile_photo_url)) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.electricPurple, lineWidth: 3))
                            .shadow(color: .electricPurple.opacity(0.3), radius: 15)
                            
                            VStack(spacing: 4) {
                                Text(user.name)
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.top, 60)
                    }
                    
                    // Relationship Status
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Relationship")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal)
                        
                        if let partner = auth.partner {
                            HStack(spacing: 16) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text("Connected with \(partner.name)")
                                        .font(.headline)
                                    if let date = auth.anniversaryDate {
                                        Text("Since \(formattedDate(date))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                            .glassmorphic()
                            .padding(.horizontal)
                        } else {
                            inviteSection
                        }
                    }
                    
                    // Account Actions
                    VStack(spacing: 12) {
                        Button {
                            auth.logout()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Logout")
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                .padding(.bottom, 100)
            }
        }
        .alert("Connect Partner", isPresented: $isShowingInviteAlert) {
            TextField("Enter Partner's Code", text: $inviteCodeInput)
                .autocapitalization(.allCharacters)
            Button("Connect") {
                connectPartner()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter the unique code shared by your partner to connect.")
        }
    }
    
    private var inviteSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Invite Code")
                    .font(.subheadline.bold())
                    .foregroundColor(.electricPurple)
                
                HStack {
                    Text(auth.currentUser?.invite_code ?? "----")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        shareInviteCode()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.electricPurple)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            Button {
                isShowingInviteAlert = true
            } label: {
                Text("Have a code? Connect here")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.electricPurple)
                    .cornerRadius(16)
            }
        }
        .padding()
        .glassmorphic()
        .padding(.horizontal)
    }
    
    private func shareInviteCode() {
        guard let code = auth.currentUser?.invite_code else { return }
        let shareText = "Connect with me on Glimpse! Use my invite code: \(code)"
        let av = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
    
    private func connectPartner() {
        Task {
            do {
                try await auth.connectPartner(inviteCode: inviteCodeInput)
                inviteCodeInput = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    ProfileView()
}
