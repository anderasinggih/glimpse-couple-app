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
    @State private var isShowingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isShowingClearCacheAlert = false
    @State private var isShowingClearCacheSuccess = false
    @AppStorage("glimpse_theme_accent") var themeAccentHex = "00FFFF"
    @AppStorage("glimpse_haptic_strength") var hapticStrength = "rigid"
    @AppStorage("glimpse_dynamic_orbs") var dynamicOrbsEnabled = true
    @AppStorage("glimpse_default_map_style") var defaultMapStyle = "satellite"
    @State private var cacheSize = "Calculating..."
    
    @State private var isShowingThemeSelection = false
    @State private var isShowingHapticSelection = false
    @State private var isShowingMapStyleSelection = false
    
    @State private var notificationsEnabled = true
    @Binding var scrollOffset: CGFloat
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
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    ZStack {
                        // Scroll Position Detector
                        GeometryReader { geo in
                            Color.clear.preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("scroll")).minY)
                        }
                        .frame(height: 0)
                    
                    VStack(spacing: 24) {
                        Spacer(minLength: 95) // Space for floating header
                            .id("SCROLL_TOP_ANCHOR")
                        
                        // 1. Profile Summary (Dynamic Header)
                        if let user = auth.currentUser {
                            VStack(spacing: 16) {
                                if let partner = auth.partner {
                                    // PAIRED AVATARS
                                    // PAIRED AVATARS (Increased separation, accent borders, and removed covering heart icon)
                                    HStack(spacing: 24) {
                                        avatarImage(url: user.profile_photo_url)
                                            .overlay(Circle().stroke(Color.deepVelvet, lineWidth: 2))
                                            .shadow(color: .activeCyan.opacity(0.4), radius: 12)
                                        
                                        Image(systemName: "arrow.left.and.right")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.activeCyan.opacity(0.6))
                                            .frame(width: 32, height: 32)
                                            .background(Color.activeCyan.opacity(0.1))
                                            .clipShape(Circle())
                                        
                                        avatarImage(url: partner.profile_photo_url)
                                            .overlay(Circle().stroke(Color.deepVelvet, lineWidth: 2))
                                            .shadow(color: .activeCyan.opacity(0.4), radius: 12)
                                    }
                                    .padding(.top, 10)
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
                                                CompactMenuRow(icon: "clock.fill", title: "Unlink requested...", value: "Cancel Request", color: .activeCyan)
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
                                            CompactMenuRow(icon: "heart.fill", title: "Connected with \(partner.name)", value: formattedPairedDate(auth.pairedDate ?? Date()), color: .activeCyan)
                                        }
                                    }
                                    
                                    Button {
                                        isShowingEditAnniversary = true
                                    } label: {
                                        CompactMenuRow(icon: "calendar", title: "Anniversary date", value: formattedDate(auth.anniversaryDate ?? Date()), color: .activeCyan)
                                    }
                                } else {
                                    if auth.invitedBy == auth.currentUser?.id {
                                        Button {
                                            isShowingCancelInviteConfirmation = true
                                        } label: {
                                            CompactMenuRow(icon: "hourglass.badge.plus", title: "Invite sent to \(partner.name)", value: "Pending", color: .activeCyan)
                                        }
                                    } else {
                                        Button {
                                            isShowingAcceptInviteConfirmation = true
                                        } label: {
                                            CompactMenuRow(icon: "heart.badge.plus.fill", title: "Invite from \(partner.name)", value: "Review", color: .activeCyan)
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
                                CompactMenuRow(icon: "lock.fill", title: "Change password", value: "Security", color: .activeCyan)
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
                                CompactMenuRow(icon: "waveform.path", title: "Vibrations & haptics", value: hapticStrengthTitle(), color: .activeCyan)
                            }
                            
                            Button {
                                isShowingMapStyleSelection = true
                            } label: {
                                CompactMenuRow(icon: "map.fill", title: "Default map style", value: defaultMapStyleTitle(), color: .activeCyan)
                            }
                            
                            Button {
                                dynamicOrbsEnabled.toggle()
                                triggerHapticExample()
                            } label: {
                                CompactMenuRow(icon: "circle.hexagongrid.fill", title: "Animated 3D Orbs", value: dynamicOrbsEnabled ? "Active" : "Off (Saves Battery)", color: .activeCyan)
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
                                CompactMenuRow(icon: "location.viewfinder", title: "Location sharing", value: locationStatus(), color: .activeCyan)
                            }
                            
                            Button {
                                isShowingClearCacheAlert = true
                            } label: {
                                CompactMenuRow(icon: "trash.fill", title: "Clear cache storage", value: cacheSize, color: .activeCyan)
                            }
                            
                            Link(destination: URL(string: "https://api.galleryfortwo.my.id/privacy")!) {
                                CompactMenuRow(icon: "shield.fill", title: "Privacy policy", value: "View", color: .activeCyan)
                            }
                        }
                        .padding(.horizontal)
                        

                        
                        // 6. Logout
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
                        
                        // 7. Premium Footer & Branding by Lovinpeace
                        VStack(spacing: 6) {
                            Text("Glimpse for Couples")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Version 1.2.4 (Build 412)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.35))
                            
                            Text("Created by Lovinpeace")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.activeCyan.opacity(0.85))
                            
                            Text("© 2026 Lovinpeace. All Rights Reserved.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.2))
                        }
                        .padding(.top, 30)
                        .padding(.bottom, 10)
                        
                        Spacer(minLength: 120)
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                self.scrollOffset = value
            }
            .onChange(of: auth.selectedTab) { oldValue, newValue in
                if newValue == 4 { // Profile tab
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        proxy.scrollTo("SCROLL_TOP_ANCHOR", anchor: .top)
                    }
                }
            }
            } // Close ScrollViewReader
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
                .presentationDetents([.height(420)])
        }
        .sheet(isPresented: $isShowingMapStyleSelection) {
            MapStyleSelectionView(defaultMapStyle: $defaultMapStyle)
                .presentationDetents([.height(290)])
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
        .alert("Connection Error", isPresented: $isShowingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Clear Image Cache?", isPresented: $isShowingClearCacheAlert) {
            Button("Clear", role: .destructive) {
                auth.clearImageCache()
                cacheSize = auth.getImageCacheSize()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                isShowingClearCacheSuccess = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all downloaded cached images of your partner. They will be re-downloaded seamlessly when needed.")
        }
        .alert("Cache Cleared!", isPresented: $isShowingClearCacheSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All image cache has been successfully removed to free up your phone storage.")
        }
        .onAppear {
            cacheSize = auth.getImageCacheSize()
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
            .overlay(Circle().stroke(Color.activeCyan, lineWidth: 2))
            .shadow(color: .activeCyan.opacity(0.25), radius: 10)
    }
    
    private func triggerHapticExample() {
        guard hapticStrength != "none" else { return }
        if hapticStrength == "rigid" {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } else if hapticStrength == "soft" {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else if hapticStrength == "heavy" {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } else if hapticStrength == "success" {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if hapticStrength == "warning" {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
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
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isShowingErrorAlert = true
                }
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
        case "heavy": return "Heavy Impact"
        case "success": return "Success Wave"
        case "warning": return "Alert Warnings"
        case "none": return "Disabled"
        default: return "Crisp & Rigid"
        }
    }
    
    private func defaultMapStyleTitle() -> String {
        switch defaultMapStyle {
        case "satellite": return "Satellite Mode"
        case "standard": return "Standard Mode"
        default: return "Satellite Mode"
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
    @State private var bornDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var bornDateSelected = false
    @State private var gender = ""
    @State private var showDatePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSaving = false
    @State private var isProcessingImage = false
    @Environment(\.dismiss) var dismiss
    
    init(auth: AuthManager) {
        self.auth = auth
        _name = State(initialValue: auth.currentUser?.name ?? "")
        _email = State(initialValue: auth.currentUser?.email ?? "")
        _gender = State(initialValue: auth.currentUser?.gender ?? "")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let bdStr = auth.currentUser?.born_date, let date = formatter.date(from: bdStr) {
            _bornDate = State(initialValue: date)
            _bornDateSelected = State(initialValue: true)
        } else {
            _bornDate = State(initialValue: Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date())
            _bornDateSelected = State(initialValue: false)
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
                        .onChange(of: name) { oldValue, newValue in
                            if newValue.count > 30 {
                                name = String(newValue.prefix(30))
                            }
                        }
                    
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: email) { oldValue, newValue in
                            if newValue.count > 100 {
                                email = String(newValue.prefix(100))
                            }
                        }
                    
                    // Date of Birth Row
                    Button(action: {
                        showDatePicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 20)
                            
                            Text(bornDateSelected ? bornDate.formatted(date: .long, time: .omitted) : "Date of Birth")
                                .foregroundColor(bornDateSelected ? .white : .white.opacity(0.4))
                                .font(.system(size: 15))
                            
                            Spacer()
                            
                            Text(bornDateSelected ? "Edit" : "Select")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.electricPurple)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Gender Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.leading, 4)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                gender = "male"
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                HStack {
                                    Image(systemName: gender == "male" ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(gender == "male" ? .activeCyan : .white.opacity(0.3))
                                    Text("Male")
                                        .font(.system(size: 15, weight: gender == "male" ? .bold : .regular))
                                        .foregroundColor(gender == "male" ? .white : .white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(gender == "male" ? Color.activeCyan.opacity(0.15) : Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(gender == "male" ? Color.activeCyan : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                gender = "female"
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                HStack {
                                    Image(systemName: gender == "female" ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(gender == "female" ? .electricPurple : .white.opacity(0.3))
                                    Text("Female")
                                        .font(.system(size: 15, weight: gender == "female" ? .bold : .regular))
                                        .foregroundColor(gender == "female" ? .white : .white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(gender == "female" ? Color.electricPurple.opacity(0.15) : Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(gender == "female" ? Color.electricPurple : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal)
                
                Button {
                    saveProfile()
                } label: {
                    Group {
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
                }
                .padding(.horizontal)
                .disabled(isSaving || isProcessingImage)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showDatePicker) {
            ZStack {
                Color.deepVelvet.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    HStack {
                        Text("Select Date of Birth")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Button("Done") {
                            bornDateSelected = true
                            showDatePicker = false
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.electricPurple)
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    DatePicker(
                        "",
                        selection: $bornDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding(.horizontal)
                    .onChange(of: bornDate) { _, _ in
                        bornDateSelected = true
                    }
                    
                    Spacer()
                }
            }
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func saveProfile() {
        isSaving = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = bornDateSelected ? formatter.string(from: bornDate) : nil
        let genderVal = gender.isEmpty ? nil : gender
        
        Task {
            do {
                try await auth.updateProfile(name: name, email: email, bornDate: dateStr, gender: genderVal, photo: selectedImage)
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
                    Group {
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
                }
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
    ProfileView(scrollOffset: .constant(0))
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
    
    let hapticOptions = [
        ("Crisp & Rigid", "rigid", "Double metallic tap", "selection"),
        ("Soft & Subtle", "soft", "Light organic touch", "light"),
        ("Heavy Impact", "heavy", "Strong tactile bump", "heavy"),
        ("Success Wave", "success", "Playful double pulse", "success"),
        ("Alert Warnings", "warning", "Triple alert pulse", "warning"),
        ("Disabled", "none", "No vibration feedback", "none")
    ]
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea()
            
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Vibration & Haptics")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Tap any profile below to feel the haptic preview immediately!")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                
                VStack(spacing: 8) {
                    ForEach(hapticOptions, id: \.1) { option in
                        Button {
                            hapticStrength = option.1
                            triggerHaptic(type: option.3)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: hapticIcon(for: option.1))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(hapticStrength == option.1 ? .deepVelvet : .activeCyan)
                                    .frame(width: 28, height: 28)
                                    .background(hapticStrength == option.1 ? Color.activeCyan : Color.activeCyan.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.0)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(hapticStrength == option.1 ? .deepVelvet : .white)
                                    Text(option.2)
                                        .font(.system(size: 10.5))
                                        .foregroundColor(hapticStrength == option.1 ? .deepVelvet.opacity(0.7) : .white.opacity(0.4))
                                }
                                
                                Spacer()
                                
                                if hapticStrength == option.1 {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.deepVelvet)
                                        .font(.system(size: 15))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(hapticStrength == option.1 ? Color.activeCyan : Color.white.opacity(0.04))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(hapticStrength == option.1 ? Color.clear : Color.white.opacity(0.05), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                Button {
                    dismiss()
                } label: {
                    Text("Apply & Close")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.deepVelvet)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.activeCyan)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                Spacer()
            }
        }
    }
    
    private func hapticIcon(for strength: String) -> String {
        switch strength {
        case "rigid": return "circle.grid.2x1.fill"
        case "soft": return "circle.fill"
        case "heavy": return "bolt.horizontal.fill"
        case "success": return "checkmark.circle.fill"
        case "warning": return "exclamationmark.triangle.fill"
        default: return "slash.circle"
        }
    }
    
    private func triggerHaptic(type: String) {
        switch type {
        case "selection":
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case "light":
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case "heavy":
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case "success":
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case "warning":
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        default:
            break
        }
    }
}

struct MapStyleSelectionView: View {
    @Binding var defaultMapStyle: String
    @Environment(\.dismiss) var dismiss
    
    let options = [
        ("Satellite Mode", "satellite", "Hybrid high-res satellite map imagery", "globe.americas.fill"),
        ("Standard Mode", "standard", "Clean minimalist vector map layout", "map.fill")
    ]
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea()
            
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Default Map Style")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Choose the default style for all map views in the app")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                
                VStack(spacing: 8) {
                    ForEach(options, id: \.1) { option in
                        Button {
                            defaultMapStyle = option.1
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: option.3)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(defaultMapStyle == option.1 ? .deepVelvet : .activeCyan)
                                    .frame(width: 28, height: 28)
                                    .background(defaultMapStyle == option.1 ? Color.activeCyan : Color.activeCyan.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.0)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(defaultMapStyle == option.1 ? .deepVelvet : .white)
                                    Text(option.2)
                                        .font(.system(size: 10.5))
                                        .foregroundColor(defaultMapStyle == option.1 ? .deepVelvet.opacity(0.7) : .white.opacity(0.4))
                                }
                                
                                Spacer()
                                
                                if defaultMapStyle == option.1 {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.deepVelvet)
                                        .font(.system(size: 15))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(defaultMapStyle == option.1 ? Color.activeCyan : Color.white.opacity(0.04))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(defaultMapStyle == option.1 ? Color.clear : Color.white.opacity(0.05), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                Button {
                    dismiss()
                } label: {
                    Text("Apply & Close")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.deepVelvet)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.activeCyan)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                Spacer()
            }
        }
    }
}
