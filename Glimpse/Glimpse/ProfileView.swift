import SwiftUI
import PhotosUI
import CoreLocation

struct ProfileView: View {
    @State private var auth = AuthManager.shared
    @State private var inviteCodeInput = ""
    @State private var isShowingInviteAlert = false
    @State private var isShowingEditProfile = false
    @State private var isShowingChangePassword = false
    @State private var isShowingEditAnniversary = false
    @State private var notificationsEnabled = true
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            // LAYER 1: Background
            Color.deepVelvet.ignoresSafeArea()
            iOS26Background().opacity(0.4)
            
            // LAYER 2: Scroll Content
            ScrollView(showsIndicators: false) {
                ZStack {
                    // Scroll Position Detector
                    GeometryReader { geo in
                        Color.clear.preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 24) {
                        Spacer(minLength: 95) // Space for floating header
                        
                        // 1. Profile Summary (Dynamic Header)
                        if let user = auth.currentUser {
                            VStack(spacing: 16) {
                                if let partner = auth.partner {
                                    // PAIRED AVATARS
                                    ZStack {
                                        avatarImage(url: partner.profile_photo_url)
                                            .offset(x: 25, y: 10)
                                            .scaleEffect(0.9)
                                        
                                        avatarImage(url: user.profile_photo_url)
                                            .overlay(Circle().stroke(Color.deepVelvet, lineWidth: 4))
                                            .offset(x: -20)
                                        
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.red)
                                            .padding(6)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .shadow(radius: 5)
                                            .offset(x: 10, y: 0)
                                    }
                                    .padding(.horizontal, 30)
                                } else {
                                    avatarImage(url: user.profile_photo_url)
                                }
                                
                                VStack(spacing: 4) {
                                    if let partner = auth.partner {
                                        Text("\(user.name) & \(partner.name)")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    } else {
                                        Text(user.name)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(user.email)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.top, 20)
                        }
                        
                        // 2. Relationship Section
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel(auth.partner != nil ? "Relationship (shared settings)" : "Get started")
                            
                            if let partner = auth.partner {
                                CompactMenuRow(icon: "heart.fill", title: "Connected with \(partner.name)", value: "Paired", color: .red)
                                
                                Button {
                                    isShowingEditAnniversary = true
                                } label: {
                                    CompactMenuRow(icon: "calendar", title: "Anniversary date", value: formattedDate(auth.anniversaryDate ?? Date()), color: .electricPurple)
                                }
                            } else {
                                inviteCard
                            }
                        }
                        .padding(.horizontal)
                        
                        // 3. Account Settings
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("Account settings")
                            
                            Button {
                                isShowingEditProfile = true
                            } label: {
                                CompactMenuRow(icon: "person.text.rectangle.fill", title: "Edit profile info", value: "Name, Email, Photo", color: .activeCyan)
                            }
                            
                            Button {
                                isShowingChangePassword = true
                            } label: {
                                CompactMenuRow(icon: "lock.fill", title: "Change password", value: "Security", color: .orange)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 4. App & Privacy
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("App & privacy")
                            
                            Button {
                                notificationsEnabled.toggle()
                            } label: {
                                CompactMenuRow(icon: "bell.fill", title: "Push notifications", value: notificationsEnabled ? "On" : "Off", color: .activeCyan)
                            }
                            
                            Button {
                                openAppSettings()
                            } label: {
                                CompactMenuRow(icon: "location.viewfinder", title: "Location sharing", value: locationStatus(), color: .green)
                            }
                            
                            Link(destination: URL(string: "https://glimpse-app.com/privacy")!) {
                                CompactMenuRow(icon: "shield.fill", title: "Privacy policy", value: "View", color: .secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 5. Logout
                        Button {
                            auth.logout()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 14))
                                Text("Logout from account")
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
                        
                        Spacer(minLength: 120)
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                scrollOffset = value
            }
            .ignoresSafeArea(.container, edges: .top)
            
            // LAYER 3: Floating Header (With Dynamic Opacity)
            headerView
                .padding(.top, 10)
                .opacity(headerOpacity)
                .animation(.easeInOut, value: headerOpacity)
                .zIndex(10)
        }
        .sheet(isPresented: $isShowingEditProfile) {
            EditProfileView(auth: auth)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $isShowingChangePassword) {
            ChangePasswordView(auth: auth)
                .presentationDetents([.height(350)])
        }
        .sheet(isPresented: $isShowingEditAnniversary) {
            EditAnniversaryView(auth: auth)
                .presentationDetents([.height(300)])
        }
        .alert("Connect Partner", isPresented: $isShowingInviteAlert) {
            TextField("Partner code", text: $inviteCodeInput)
                .autocapitalization(.allCharacters)
            Button("Connect") { connectPartner() }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private var headerView: some View {
        BrandingHeader()
    }
    
    private func avatarImage(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle().fill(Color.gray.opacity(0.3))
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.electricPurple, lineWidth: 2))
        .shadow(color: .electricPurple.opacity(0.2), radius: 10)
    }
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white.opacity(0.4))
            .padding(.leading, 8)
    }
    
    private var inviteCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your invite code")
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
                Text("Enter partner code")
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
    
    private func locationStatus() -> String {
        let manager = CLLocationManager()
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return "Always"
        case .denied, .restricted: return "Disabled"
        default: return "Check settings"
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private var headerOpacity: Double {
        // Logo starts fading after 20px scroll, disappears at 60px
        let opacity = 1.0 + (scrollOffset / 60.0)
        return max(0, min(1, opacity))
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ChangePasswordView: View {
    @Bindable var auth: AuthManager
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Change Password")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top)
                
                VStack(spacing: 12) {
                    SecureField("Current password", text: $currentPassword)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    
                    SecureField("New password", text: $newPassword)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    
                    SecureField("Confirm new password", text: $confirmPassword)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Button {
                    // Logic to change password
                    dismiss()
                } label: {
                    Text("Update password")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.deepVelvet)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

struct EditProfileView: View {
    @Bindable var auth: AuthManager
    @State private var name = ""
    @State private var email = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSaving = false
    @State private var isProcessingImage = false
    @Environment(\.dismiss) var dismiss
    
    init(auth: AuthManager) {
        self.auth = auth
        _name = State(initialValue: auth.currentUser?.name ?? "")
        _email = State(initialValue: auth.currentUser?.email ?? "")
    }
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Edit Profile Info")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top)
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            AsyncImage(url: URL(string: auth.currentUser?.profile_photo_url ?? "")) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        }
                        
                        if isProcessingImage {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.electricPurple)
                                .clipShape(Circle())
                                .offset(x: 30, y: 30)
                        }
                    }
                }
                .onChange(of: selectedItem) {
                    Task {
                        isProcessingImage = true
                        defer { isProcessingImage = false }
                        if let data = try? await selectedItem?.loadTransferable(type: Data.self), 
                           let image = UIImage(data: data) {
                            selectedImage = image
                        }
                    }
                }
                
                VStack(spacing: 12) {
                    TextField("Name", text: $name)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                .padding(.horizontal)
                
                Button {
                    saveProfile()
                } label: {
                    if isSaving {
                        ProgressView().tint(.deepVelvet)
                    } else {
                        Text("Save changes")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.electricPurple)
                .foregroundColor(.deepVelvet)
                .cornerRadius(16)
                .padding(.horizontal)
                .disabled(isSaving || isProcessingImage)
                
                Spacer()
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        Task {
            do {
                try await auth.updateProfile(name: name, email: email, photo: selectedImage)
                dismiss()
            } catch {
                print("Failed to save: \(error)")
            }
            isSaving = false
        }
    }
}

struct EditAnniversaryView: View {
    @Bindable var auth: AuthManager
    @State private var date = Date()
    @State private var isSaving = false
    @Environment(\.dismiss) var dismiss
    
    init(auth: AuthManager) {
        self.auth = auth
        _date = State(initialValue: auth.anniversaryDate ?? Date())
    }
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Select Anniversary Date")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top)
                
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorInvert()
                    .colorMultiply(.white)
                
                Button {
                    saveAnniversary()
                } label: {
                    if isSaving {
                        ProgressView().tint(.deepVelvet)
                    } else {
                        Text("Update date")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.electricPurple)
                .foregroundColor(.deepVelvet)
                .cornerRadius(16)
                .padding(.horizontal)
                .disabled(isSaving)
                
                Spacer()
            }
        }
    }
    
    private func saveAnniversary() {
        isSaving = true
        Task {
            do {
                try await auth.updateAnniversary(date: date)
                dismiss()
            } catch {
                print("Failed to save: \(error)")
            }
            isSaving = false
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
