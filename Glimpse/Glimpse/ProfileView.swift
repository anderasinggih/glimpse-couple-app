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
    @State private var isShowingLogoutConfirmation = false
    @State private var isShowingDisconnectConfirmation = false
    @State private var isShowingCancelDisconnectConfirmation = false
    @State private var isShowingApproveDisconnectConfirmation = false
    @State private var isShowingAcceptInviteConfirmation = false
    @State private var isShowingCancelInviteConfirmation = false
    @AppStorage("glimpse_theme_accent") var themeAccentHex = "00FFFF"
    @AppStorage("glimpse_haptic_strength") var hapticStrength = "rigid"
    
    @State private var isShowingThemeSelection = false
    @State private var isShowingHapticSelection = false
    
    @State private var notificationsEnabled = true
    @State private var scrollOffset: CGFloat = 0
    @State private var isCopied = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // LAYER 1: Background
            ZStack {
                Color.deepVelvet
                iOS26Background().opacity(0.4)
            }
            .ignoresSafeArea()
            
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
                                if auth.coupleActive {
                                    if let reqBy = auth.disconnectRequestedBy {
                                        if reqBy == auth.currentUser?.id {
                                            Button {
                                                isShowingCancelDisconnectConfirmation = true
                                            } label: {
                                                CompactMenuRow(icon: "clock.fill", title: "Unlink requested...", value: "Cancel Request", color: .orange)
                                            }
                                        } else {
                                            Button {
                                                isShowingApproveDisconnectConfirmation = true
                                            } label: {
                                                CompactMenuRow(icon: "person.fill.xmark", title: "Unlink request from \(partner.name)", value: "Review", color: .red)
                                            }
                                        }
                                    } else {
                                        Button {
                                            isShowingDisconnectConfirmation = true
                                        } label: {
                                            CompactMenuRow(icon: "heart.fill", title: "Connected with \(partner.name)", value: formattedPairedDate(auth.anniversaryDate ?? Date()), color: .red)
                                        }
                                    }
                                    
                                    Button {
                                        isShowingEditAnniversary = true
                                    } label: {
                                        CompactMenuRow(icon: "calendar", title: "Anniversary date", value: formattedDate(auth.anniversaryDate ?? Date()), color: .electricPurple)
                                    }
                                } else {
                                    if auth.invitedBy == auth.currentUser?.id {
                                        Button {
                                            isShowingCancelInviteConfirmation = true
                                        } label: {
                                            CompactMenuRow(icon: "hourglass.badge.plus", title: "Invite sent to \(partner.name)", value: "Pending", color: .orange)
                                        }
                                    } else {
                                        Button {
                                            isShowingAcceptInviteConfirmation = true
                                        } label: {
                                            CompactMenuRow(icon: "heart.badge.plus.fill", title: "Invite from \(partner.name)", value: "Review", color: .red)
                                        }
                                    }
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
                        
                        // 4. Glimpse Customization
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("Glimpse Customization")
                            
                            Button {
                                isShowingThemeSelection = true
                            } label: {
                                CompactMenuRow(icon: "paintpalette.fill", title: "App accent theme", value: activeThemeName(), color: .activeCyan)
                            }
                            
                            Button {
                                isShowingHapticSelection = true
                            } label: {
                                CompactMenuRow(icon: "waveform.path", title: "Vibrations & haptics", value: hapticStrengthTitle(), color: .orange)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 5. App & Privacy
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
                            isShowingLogoutConfirmation = true
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
            .ignoresSafeArea(.container, edges: .top)
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
        .sheet(isPresented: $isShowingThemeSelection) {
            ThemeSelectionView(accentHex: $themeAccentHex)
                .presentationDetents([.height(260)])
        }
        .sheet(isPresented: $isShowingHapticSelection) {
            HapticSelectionView(hapticStrength: $hapticStrength)
                .presentationDetents([.height(230)])
        }
        .alert("Connect Partner", isPresented: $isShowingInviteAlert) {
            TextField("Partner code", text: $inviteCodeInput)
                .autocapitalization(.allCharacters)
            Button("Connect") { connectPartner() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Logout", isPresented: $isShowingLogoutConfirmation) {
            Button("Logout", role: .destructive) {
                auth.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to logout? You will need to login again to see your partner's updates.")
        }
        .alert("Unlink Partner?", isPresented: $isShowingDisconnectConfirmation) {
            Button("Request Unlink", role: .destructive) {
                Task { try? await auth.disconnectPartner() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will send a disconnect request to \(auth.partner?.name ?? "your partner"). You will remain connected until they approve it.")
        }
        .alert("Approve Unlink?", isPresented: $isShowingApproveDisconnectConfirmation) {
            Button("Approve Disconnect", role: .destructive) {
                Task { try? await auth.approveDisconnectPartner() }
            }
            Button("Keep Connected", role: .cancel) {
                Task { try? await auth.cancelDisconnectPartner() }
            }
        } message: {
            Text("\(auth.partner?.name ?? "Your partner") has requested to unlink. Approving this will immediately disconnect you both. Choosing 'Keep Connected' will decline the request.")
        }
        .alert("Cancel Unlink Request?", isPresented: $isShowingCancelDisconnectConfirmation) {
            Button("Cancel Request", role: .destructive) {
                Task { try? await auth.cancelDisconnectPartner() }
            }
            Button("Keep Waiting", role: .cancel) {}
        } message: {
            Text("Do you want to cancel your request to unlink from \(auth.partner?.name ?? "your partner")?")
        }
        .alert("Approve Connection?", isPresented: $isShowingAcceptInviteConfirmation) {
            Button("Accept", role: .destructive) {
                Task { try? await auth.acceptConnectRequest() }
            }
            Button("Decline", role: .cancel) {
                Task { try? await auth.declineConnectRequest() }
            }
        } message: {
            Text("\(auth.partner?.name ?? "Your partner") has sent you a connection request. Would you like to connect and share your Glimpse?")
        }
        .alert("Cancel Invite?", isPresented: $isShowingCancelInviteConfirmation) {
            Button("Cancel Request", role: .destructive) {
                Task { try? await auth.declineConnectRequest() }
            }
            Button("Keep Waiting", role: .cancel) {}
        } message: {
            Text("Do you want to cancel your pending invite to \(auth.partner?.name ?? "your partner")?")
        }
    }
    
    private func formattedUrl(_ urlString: String) -> String {
        if urlString.hasPrefix("http") {
            return urlString
        } else {
            let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
            let baseURL = AuthManager.shared.baseURL.replacingOccurrences(of: "/api", with: "")
            return cleanPath.contains("storage/") ? "\(baseURL)/\(cleanPath)" : "\(baseURL)/storage/\(cleanPath)"
        }
    }
    
    private func avatarImage(url: String) -> some View {
        CachedImageView(urlString: formattedUrl(url))
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
                    Text(isCopied ? "Copied!" : "Your invite code (Tap to Copy)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isCopied ? .green : .electricPurple)
                    Text(auth.currentUser?.invite_code ?? "----")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard let code = auth.currentUser?.invite_code else { return }
                    UIPasteboard.general.string = code
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation {
                        isCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            isCopied = false
                        }
                    }
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
    
    private func activeThemeName() -> String {
        switch themeAccentHex {
        case "00FFFF": return "Electric Cyan"
        case "FF66B2": return "Rose Romance"
        case "FFA500": return "Sunset Spark"
        case "00FF88": return "Vivid Mint"
        default: return "Custom"
        }
    }
    
    private func hapticStrengthTitle() -> String {
        switch hapticStrength {
        case "rigid": return "Crisp & Rigid"
        case "soft": return "Soft & Subtle"
        case "none": return "Disabled"
        default: return "Standard"
        }
    }
    
    private func formattedPairedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return "paired " + formatter.string(from: date).lowercased()
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
    
    private func formattedUrl(_ urlString: String) -> String {
        if urlString.hasPrefix("http") {
            return urlString
        } else {
            let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
            let baseURL = AuthManager.shared.baseURL.replacingOccurrences(of: "/api", with: "")
            return cleanPath.contains("storage/") ? "\(baseURL)/\(cleanPath)" : "\(baseURL)/storage/\(cleanPath)"
        }
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
                            CachedImageView(urlString: formattedUrl(auth.currentUser?.profile_photo_url ?? ""))
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
                    .environment(\.colorScheme, .dark)
                
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

struct ThemeSelectionView: View {
    @Binding var accentHex: String
    @Environment(\.dismiss) var dismiss
    
    let themes = [
        ("Electric Cyan", "00FFFF"),
        ("Rose Romance", "FF66B2"),
        ("Sunset Spark", "FFA500"),
        ("Vivid Mint", "00FF88")
    ]
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Select App Theme")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                HStack(spacing: 18) {
                    ForEach(themes, id: \.1) { theme in
                        Button {
                            accentHex = theme.1
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(Color(hex: theme.1))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: accentHex == theme.1 ? 3 : 0)
                                    )
                                    .shadow(color: Color(hex: theme.1).opacity(0.5), radius: 8)
                                
                                Text(theme.0)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(accentHex == theme.1 ? .white : .white.opacity(0.5))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}


struct HapticSelectionView: View {
    @Binding var hapticStrength: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Vibration & Haptic Feedback")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                VStack(spacing: 8) {
                    ForEach([("Crisp & Rigid", "rigid"), ("Soft & Subtle", "soft"), ("Disabled", "none")], id: \.1) { option in
                        Button {
                            hapticStrength = option.1
                            if option.1 == "rigid" {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            } else if option.1 == "soft" {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Text(option.0)
                                Spacer()
                                if hapticStrength == option.1 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.activeCyan)
                                }
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}
