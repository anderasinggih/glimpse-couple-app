import SwiftUI

struct ProfileView: View {
    @State private var auth = AuthManager.shared
    @State private var inviteCodeInput = ""
    @State private var isShowingInviteAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.deepVelvet.ignoresSafeArea()
            iOS26Background().opacity(0.4)
            
            VStack(spacing: 0) {
                // Fixed Header Branding
                headerView
                    .padding(.top, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. Profile Summary (Compact)
                        if let user = auth.currentUser {
                            VStack(spacing: 12) {
                                AsyncImage(url: URL(string: user.profile_photo_url)) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 80, height: 80) // Downsized
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.electricPurple, lineWidth: 2))
                                .shadow(color: .electricPurple.opacity(0.2), radius: 10)
                                
                                VStack(spacing: 2) {
                                    Text(user.name)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text(user.email)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.top, 20)
                        }
                        
                        // 2. Relationship Section
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("RELATIONSHIP")
                            
                            if let partner = auth.partner {
                                CompactMenuRow(icon: "heart.fill", title: "Connected with \(partner.name)", value: "Since 2023", color: .red)
                                CompactMenuRow(icon: "calendar", title: "Anniversary Date", value: "Oct 20", color: .electricPurple)
                            } else {
                                inviteCard
                            }
                        }
                        .padding(.horizontal)
                        
                        // 3. Settings & Stats Section
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("ACCOUNT & PRIVACY")
                            
                            CompactMenuRow(icon: "bell.fill", title: "Notifications", value: "Enabled", color: .activeCyan)
                            CompactMenuRow(icon: "location.viewfinder", title: "Background Sharing", value: "Always", color: .green)
                            CompactMenuRow(icon: "shield.fill", title: "Privacy Policy", value: "", color: .secondary)
                        }
                        .padding(.horizontal)
                        
                        // 4. Logout
                        Button {
                            auth.logout()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 14))
                                Text("Logout Account")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .alert("Connect Partner", isPresented: $isShowingInviteAlert) {
            TextField("Partner Code", text: $inviteCodeInput)
                .autocapitalization(.allCharacters)
            Button("Connect") { connectPartner() }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.electricPurple)
                    .font(.system(size: 28))
                Text("Glimpse")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white.opacity(0.4))
            .padding(.leading, 8)
    }
    
    private var inviteCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Invite Code")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.electricPurple)
                    Text(auth.currentUser?.invite_code ?? "----")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                Spacer()
                Button { shareInviteCode() } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.electricPurple)
                        .padding(8)
                        .background(Color.electricPurple.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            Button { isShowingInviteAlert = true } label: {
                Text("Enter Partner Code")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.electricPurple)
                    .cornerRadius(10)
            }
        }
        .padding(15)
        .glassmorphic()
    }
    
    private func shareInviteCode() {
        guard let code = auth.currentUser?.invite_code else { return }
        let shareText = "Connect with me on Glimpse! My code: \(code)"
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
                print("Connection failed: \(error)")
            }
        }
    }
}

struct CompactMenuRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassmorphic()
    }
}

#Preview {
    ProfileView()
}
