import SwiftUI
import PhotosUI
import CoreLocation
import CoreMotion
import AVFoundation
import StoreKit

struct ProfileView: View {
    @State private var auth = AuthManager.shared
    @State private var inviteCodeInput = ""
    @State private var isShowingInviteAlert = false
    @State private var isShowingEditProfile = false
    @State private var isShowingChangePassword = false
    @State private var isShowingAccountSettings = false
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
    @AppStorage("glimpse_theme_accent", store: UserDefaults(suiteName: "group.glimpse.app")) var themeAccentHex = "00FFFF"
    @AppStorage("glimpse_haptic_strength", store: UserDefaults(suiteName: "group.glimpse.app")) var hapticStrength = "rigid"
    @AppStorage("glimpse_dynamic_orbs", store: UserDefaults(suiteName: "group.glimpse.app")) var dynamicOrbsEnabled = true
    @AppStorage("glimpse_default_map_style", store: UserDefaults(suiteName: "group.glimpse.app")) var defaultMapStyle = "satellite"
    @AppStorage("glimpse_background_theme", store: UserDefaults(suiteName: "group.glimpse.app")) var backgroundTheme = "default"
    @State private var cacheSize = "Calculating..."
    @State private var isShowingAppMediaSettings = false
    @State private var isShowingThemeAppearance = false
    @State private var isShowingHelpSupport = false
    @State private var isShowingAboutGlimpse = false
    
    @State private var notificationsEnabled = true
    @Binding var scrollOffset: CGFloat
    @State private var isCopied = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // LAYER 1: Background
            ZStack {
                Color.adaptiveBackground
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
                                            .overlay(Circle().stroke(Color.adaptiveBackground, lineWidth: 2))
                                            .shadow(color: .activeCyan.opacity(0.4), radius: 12)
                                        
                                        Image(systemName: "link.circle.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(.activeCyan.opacity(0.7))
                                        
                                        avatarImage(url: partner.profile_photo_url)
                                            .overlay(Circle().stroke(Color.adaptiveBackground, lineWidth: 2))
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
                                        
                                        let mySpeed = auth.myAverageSpeedKmH ?? 0.0
                                        let partnerSpeed = auth.partnerAverageSpeedKmH ?? 0.0
                                        
                                        if mySpeed >= 3.0 || partnerSpeed >= 3.0 {
                                            Text("\(mySpeed >= 3.0 ? "Me: \(Int(mySpeed)) km/h" : "")\(mySpeed >= 3.0 && partnerSpeed >= 3.0 ? "  •  " : "")\(partnerSpeed >= 3.0 ? "\(partner.name): \(Int(partnerSpeed)) km/h" : "")")
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundColor(.activeCyan)
                                                .padding(.vertical, 2)
                                        }
                                    } else {
                                        Text(user.name)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(user.email)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    Button {
                                        isShowingEditProfile = true
                                    } label: {
                                        Text("Edit Profile")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .padding(.vertical, 5)
                                            .padding(.horizontal, 14)
                                            .background(Color.white.opacity(0.08))
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                                            )
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding(.top, 20)
                        }
                        
                        // 2. Relationship Section
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel(auth.partner != nil ? "Relationship (shared settings)" : "Get started")
                            
                            if let partner = auth.partner {
                                VStack(spacing: 0) {
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
                                        
                                        Divider()
                                            .background(Color.white.opacity(0.08))
                                            .padding(.leading, 52)
                                        
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
                                }
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                )
                            } else {
                                inviteCard
                            }
                        }
                        .padding(.horizontal)
                        
                        // 3. Settings & Options (4 Main Pillars)
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Settings")
                            
                            VStack(spacing: 0) {
                                Button {
                                    isShowingAccountSettings = true
                                } label: {
                                    CompactMenuRow(icon: "lock.fill", title: "Account & Security", value: "", color: .activeCyan)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)
                                
                                Button {
                                    isShowingThemeAppearance = true
                                } label: {
                                    CompactMenuRow(icon: "paintpalette.fill", title: "Theme & Appearance", value: "", color: .activeCyan)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)
                                
                                Button {
                                    isShowingAppMediaSettings = true
                                } label: {
                                    CompactMenuRow(icon: "gearshape.fill", title: "App Settings & Permissions", value: "", color: .activeCyan)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)
                                
                                Button {
                                    isShowingHelpSupport = true
                                } label: {
                                    CompactMenuRow(icon: "questionmark.circle.fill", title: "Help & Support", value: "", color: .activeCyan)
                                }
                            }
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            )
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("About & Legal")
                            
                            VStack(spacing: 0) {
                                Button {
                                    isShowingAboutGlimpse = true
                                } label: {
                                    CompactMenuRow(icon: "info.circle.fill", title: "About Glimpse", value: "", color: .activeCyan)
                                }
                            }
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            )
                        }
                        .padding(.horizontal)
                        
                        // 6. Logout
                        Button {
                            isShowingLogoutConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 14))
                                Text("Logout")
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
                            
                            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                            Text("Version \(appVersion) (Build \(buildNumber))")
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
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingAccountSettings) {
            AccountSettingsView(auth: auth)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingChangePassword) {
            ChangePasswordView(auth: auth)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingEditAnniversary) {
            EditAnniversaryView(auth: auth)
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingThemeAppearance) {
            ThemeAppearanceView(auth: auth)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingHelpSupport) {
            HelpSupportView(auth: auth)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingAboutGlimpse) {
            AboutGlimpseView(auth: auth)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingAppMediaSettings) {
            AppMediaSettingsView(auth: auth)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
        .alert("Clear Cache Storage?", isPresented: $isShowingClearCacheAlert) {
            Button("Clear", role: .destructive) {
                auth.clearImageCache()
                cacheSize = auth.getImageCacheSize()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                isShowingClearCacheSuccess = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all downloaded cached images and voice notes. They will be re-downloaded seamlessly when needed.")
        }
        .alert("Cache Cleared!", isPresented: $isShowingClearCacheSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All image and voice note caches have been successfully removed to free up your phone storage.")
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
        case "00FFFF": return "Cyan"
        case "BF80FF": return "Purple"
        case "FF4D9E": return "Pink"
        case "00FF88": return "Green"
        case "FF8C42": return "Orange"
        case "FFD700": return "Gold"
        case "FF4D6D": return "Red"
        case "4D9EFF": return "Blue"
        case "FFFFFF": return "White"
        default: return "Custom"
        }
    }
    
    private func backgroundThemeTitle() -> String {
        switch backgroundTheme {
        case "dark": return "Pure Black"
        default: return "Default Velvet"
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
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var showForgotPassword = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Text("Change Password")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 24)
                    
                    VStack(spacing: 16) {
                        SecureField("Current password", text: $currentPassword)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        SecureField("New password", text: $newPassword)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        SecureField("Confirm new password", text: $confirmPassword)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
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
                    .padding(.horizontal)
                    
                    // Real-time Data Validation Feedback
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: !currentPassword.isEmpty ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(!currentPassword.isEmpty ? .green : .white.opacity(0.3))
                                .font(.system(size: 13))
                            Text("Current password is required")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(!currentPassword.isEmpty ? .white.opacity(0.7) : .white.opacity(0.4))
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: newPassword.count >= 8 ? "checkmark.circle.fill" : (newPassword.isEmpty ? "circle" : "xmark.circle.fill"))
                                .foregroundColor(newPassword.count >= 8 ? .green : (newPassword.isEmpty ? .white.opacity(0.3) : .red))
                                .font(.system(size: 13))
                            Text("New password must be at least 8 characters")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(newPassword.count >= 8 ? .white.opacity(0.7) : (newPassword.isEmpty ? .white.opacity(0.4) : .red))
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: (newPassword == confirmPassword && !confirmPassword.isEmpty) ? "checkmark.circle.fill" : (confirmPassword.isEmpty ? "circle" : "xmark.circle.fill"))
                                .foregroundColor((newPassword == confirmPassword && !confirmPassword.isEmpty) ? .green : (confirmPassword.isEmpty ? .white.opacity(0.3) : .red))
                                .font(.system(size: 13))
                            Text("Confirm password matches new password")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor((newPassword == confirmPassword && !confirmPassword.isEmpty) ? .white.opacity(0.7) : (confirmPassword.isEmpty ? .white.opacity(0.4) : .red))
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal)
                    }
                    
                    Button {
                        Task { await updatePassword() }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.deepVelvet)
                            } else {
                                Text("Update password")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            currentPassword.isEmpty || newPassword.count < 8 || newPassword != confirmPassword
                            ? Color.gray.opacity(0.3)
                            : Color.orange
                        )
                        .foregroundColor(.deepVelvet)
                        .cornerRadius(16)
                    }
                    .disabled(isSaving || currentPassword.isEmpty || newPassword.count < 8 || newPassword != confirmPassword)
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private func updatePassword() async {
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "New passwords do not match."
            return
        }
        
        hideKeyboard()
        isSaving = true
        errorMessage = ""
        successMessage = ""
        
        do {
            try await auth.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            successMessage = "Password updated successfully!"
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
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
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    @State private var showEmailVerifySheet = false
    @State private var verificationCode = ""
    @State private var isVerifyingEmail = false
    @State private var verificationErrorMessage: String? = nil
    @State private var showVerificationErrorAlert = false
    @Environment(\.dismiss) var dismiss
    
    init(auth: AuthManager) {
        self.auth = auth
        _name = State(initialValue: auth.currentUser?.name ?? "")
        _email = State(initialValue: auth.currentUser?.email ?? "")
        _gender = State(initialValue: auth.currentUser?.gender ?? "")
        
        var parsedDate: Date? = nil
        if let bdStr = auth.currentUser?.born_date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: bdStr) {
                parsedDate = date
            } else {
                let isoFormatter = ISO8601DateFormatter()
                if let date = isoFormatter.date(from: bdStr) {
                    parsedDate = date
                } else {
                    let isoFormatterMS = ISO8601DateFormatter()
                    isoFormatterMS.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = isoFormatterMS.date(from: bdStr) {
                        parsedDate = date
                    }
                }
            }
        }
        
        if let date = parsedDate {
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
            Color.adaptiveBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Text("Edit Profile Info")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 24)
                    
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
                                    HStack(spacing: 8) {
                                        Image(systemName: gender == "male" ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(gender == "male" ? Color(hex: "3A86FF") : .white.opacity(0.3))
                                        Text("♂ Male")
                                            .font(.system(size: 15, weight: gender == "male" ? .bold : .semibold, design: .rounded))
                                            .foregroundColor(gender == "male" ? Color(hex: "3A86FF") : .white.opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(gender == "male" ? Color(hex: "3A86FF").opacity(0.15) : Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(gender == "male" ? Color(hex: "3A86FF") : Color.white.opacity(0.12), lineWidth: 1.2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    gender = "female"
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: gender == "female" ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(gender == "female" ? Color(hex: "FF4DAD") : .white.opacity(0.3))
                                        Text("♀ Female")
                                            .font(.system(size: 15, weight: gender == "female" ? .bold : .semibold, design: .rounded))
                                            .foregroundColor(gender == "female" ? Color(hex: "FF4DAD") : .white.opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(gender == "female" ? Color(hex: "FF4DAD").opacity(0.15) : Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(gender == "female" ? Color(hex: "FF4DAD") : Color.white.opacity(0.12), lineWidth: 1.2)
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
                    
                    // Bottom spacer so Save button is never hidden under home indicator
                    Spacer(minLength: 32)
                }
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
        }
        .alert("Could not save", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred. Please try again.")
        }
        .sheet(isPresented: $showDatePicker) {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                
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
        .sheet(isPresented: $showEmailVerifySheet) {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Verify Email Change")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 24)
                    
                    Text("We've sent a 6-digit verification code to: \(email). Please enter it below to complete the change.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    TextField("Code", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal, 48)
                        .onChange(of: verificationCode) { oldValue, newValue in
                            if newValue.count > 6 {
                                verificationCode = String(newValue.prefix(6))
                            }
                        }
                    
                    Button {
                        submitEmailVerification()
                    } label: {
                        Group {
                            if isVerifyingEmail {
                                ProgressView().tint(.deepVelvet)
                            } else {
                                Text("Verify and Update")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.electricPurple)
                        .foregroundColor(.deepVelvet)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 48)
                    .disabled(isVerifyingEmail || verificationCode.count != 6)
                    
                    Button {
                        resendCode()
                    } label: {
                        Text("Resend Code")
                            .font(.subheadline)
                            .foregroundColor(.electricPurple)
                    }
                    .disabled(isVerifyingEmail)
                    
                    Spacer()
                }
            }
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
            .alert("Verification Failed", isPresented: $showVerificationErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(verificationErrorMessage ?? "Invalid code. Please try again.")
            }
        }
    }
    
    private func submitEmailVerification() {
        isVerifyingEmail = true
        Task {
            do {
                try await auth.verifyEmailChange(otp: verificationCode)
                await MainActor.run {
                    isVerifyingEmail = false
                    showEmailVerifySheet = false
                    dismiss()
                }
            } catch {
                let msg = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                await MainActor.run {
                    verificationErrorMessage = msg
                    showVerificationErrorAlert = true
                    isVerifyingEmail = false
                }
            }
        }
    }
    
    private func resendCode() {
        Task {
            do {
                try await auth.resendEmailChangeVerification()
            } catch {
                print("Failed to resend email change code: \(error)")
            }
        }
    }
    
    private func saveProfile() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Name cannot be empty."
            showErrorAlert = true
            return
        }
        isSaving = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = bornDateSelected ? formatter.string(from: bornDate) : nil
        let genderVal = gender.isEmpty ? nil : gender
        
        Task {
            do {
                let pendingVerification = try await auth.updateProfile(name: name, email: email, bornDate: dateStr, gender: genderVal, photo: selectedImage)
                if pendingVerification {
                    await MainActor.run {
                        isSaving = false
                        showEmailVerifySheet = true
                    }
                } else {
                    await MainActor.run { dismiss() }
                }
            } catch {
                let msg = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                await MainActor.run {
                    errorMessage = msg
                    showErrorAlert = true
                    isSaving = false
                }
                return
            }
            await MainActor.run { isSaving = false }
        }
    }
}

struct EditAnniversaryView: View {
    @Bindable var auth: AuthManager
    @State private var date = Date()
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    @Environment(\.dismiss) var dismiss
    
    init(auth: AuthManager) {
        self.auth = auth
        _date = State(initialValue: auth.anniversaryDate ?? Date())
    }
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Select Anniversary Date")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 24)
                
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
        .alert("Could not save", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred. Please try again.")
        }
    }
    
    private func saveAnniversary() {
        isSaving = true
        Task {
            do {
                try await auth.updateAnniversary(date: date)
                await MainActor.run { dismiss() }
            } catch {
                let msg = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                await MainActor.run {
                    errorMessage = msg
                    showErrorAlert = true
                    isSaving = false
                }
                return
            }
            await MainActor.run { isSaving = false }
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
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    ProfileView(scrollOffset: .constant(0))
}

struct ThemeSelectionView: View {
    @Binding var accentHex: String
    @Environment(\.dismiss) var dismiss
    
    let themes = [
        ("Cyan",    "00FFFF"),
        ("Purple",  "BF80FF"),
        ("Pink",    "FF4D9E"),
        ("Green",   "00FF88"),
        ("Orange",  "FF8C42"),
        ("Gold",    "FFD700"),
        ("Red",     "FF4D6D"),
        ("Blue",    "4D9EFF"),
        ("White",   "FFFFFF"),
    ]
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                Text("Select App Theme")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 24)
                    .padding(.bottom, 5)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 16) {
                    ForEach(themes, id: \.1) { theme in
                        Button {
                            accentHex = theme.1
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: theme.1))
                                        .frame(width: 48, height: 48)
                                        .shadow(color: Color(hex: theme.1).opacity(0.4), radius: 6, x: 0, y: 3)
                                    
                                    if accentHex == theme.1 {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2.5)
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(theme.1 == "FFFFFF" ? .black : .white)
                                    }
                                }
                                
                                Text(theme.0)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(accentHex == theme.1 ? .white : .white.opacity(0.5))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                
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
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
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
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                
                // Fixed at bottom
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
                .padding(.vertical, 16)
                .background(Color.adaptiveBackground)
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
            Color.adaptiveBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
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
                    .padding(.horizontal)
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
                    
                    Spacer(minLength: 24)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct BackgroundThemeSelectionView: View {
    @Binding var backgroundTheme: String
    @Environment(\.dismiss) var dismiss
    
    let options = [
        ("Default Velvet", "default", "Beautiful signature Glimpse gradient dark purple", "paintpalette.fill"),
        ("Pure Black", "dark", "Pitch black AMOLED theme to maximize contrast and battery life", "moon.fill")
    ]
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    VStack(spacing: 4) {
                        Text("Background Theme")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Choose the background layout style for all screens")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    VStack(spacing: 8) {
                        ForEach(options, id: \.1) { option in
                            Button {
                                backgroundTheme = option.1
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: option.3)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(backgroundTheme == option.1 ? .deepVelvet : .activeCyan)
                                        .frame(width: 28, height: 28)
                                        .background(backgroundTheme == option.1 ? Color.activeCyan : Color.activeCyan.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(option.0)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(backgroundTheme == option.1 ? .deepVelvet : .white)
                                        Text(option.2)
                                            .font(.system(size: 10.5))
                                            .foregroundColor(backgroundTheme == option.1 ? .deepVelvet.opacity(0.7) : .white.opacity(0.4))
                                    }
                                    
                                    Spacer()
                                    
                                    if backgroundTheme == option.1 {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.deepVelvet)
                                            .font(.system(size: 15))
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(backgroundTheme == option.1 ? Color.activeCyan : Color.white.opacity(0.04))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(backgroundTheme == option.1 ? Color.clear : Color.white.opacity(0.05), lineWidth: 1)
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
                    
                    Spacer(minLength: 24)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct AccountSettingsView: View {
    @Bindable var auth: AuthManager
    @State private var isShowingChangePassword = false
    @State private var isShowingDeleteAccount = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Account & Security")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 24)
                
                // Section 1: Security
                VStack(alignment: .leading, spacing: 8) {
                    Text("Security")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.leading, 8)
                    
                    VStack(spacing: 0) {
                        Button {
                            isShowingChangePassword = true
                        } label: {
                            CompactMenuRow(icon: "lock.fill", title: "Change password", value: "Security", color: .activeCyan)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.leading, 52)
                        
                        Button {
                            isShowingDeleteAccount = true
                        } label: {
                            CompactMenuRow(icon: "person.crop.circle.badge.xmark", title: "Delete account", value: "Permanently delete account", color: .red)
                        }
                    }
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .sheet(isPresented: $isShowingChangePassword) {
            ChangePasswordView(auth: auth)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingDeleteAccount) {
            DeleteAccountView(auth: auth)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct DeleteAccountView: View {
    @Bindable var auth: AuthManager
    @State private var deleteMethod = "password" // "password" or "email"
    @State private var password = ""
    @State private var otpCode = ""
    @State private var agreed = false
    @State private var isSendingOtp = false
    @State private var isDeleting = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    @State private var showConfirmDeleteAlert = false
    @State private var otpSentMessage: String? = nil
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Title
                    Text("Delete Account")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 24)
                    
                    // Danger Box
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 20))
                            Text("Warning: Permanent Action")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Deleting your account is permanent. All your chats, shared photos, schedules, and link with your partner will be permanently erased and cannot be recovered.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Verification Method Picker
                    Picker("Confirmation Method", selection: $deleteMethod) {
                        Text("Use Password").tag("password")
                        Text("Use Email OTP").tag("email")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .environment(\.colorScheme, .dark)
                    
                    VStack(spacing: 16) {
                        if deleteMethod == "password" {
                            // Password input
                            SecureField("Enter your password", text: $password)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                        } else {
                            // Email OTP input
                            VStack(spacing: 12) {
                                Button {
                                    sendOtp()
                                } label: {
                                    HStack {
                                        if isSendingOtp {
                                            ProgressView().tint(.white)
                                        } else {
                                            Text(otpSentMessage != nil ? "Resend Code" : "Send Verification Code")
                                                .font(.system(size: 14, weight: .bold))
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color.activeCyan.opacity(0.15))
                                    .foregroundColor(.activeCyan)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.activeCyan.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .disabled(isSendingOtp)
                                
                                if let sentMsg = otpSentMessage {
                                    Text(sentMsg)
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .multilineTextAlignment(.center)
                                }
                                
                                TextField("Enter 6-digit Code", text: $otpCode)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .padding(.horizontal)
                                    .onChange(of: otpCode) { _, newValue in
                                        if newValue.count > 6 {
                                            otpCode = String(newValue.prefix(6))
                                        }
                                    }
                            }
                        }
                        
                        // Agreement Checkbox
                        Toggle(isOn: $agreed) {
                            Text("I understand and wish to permanently delete my account.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    // Delete Button
                    Button {
                        showConfirmDeleteAlert = true
                    } label: {
                        HStack {
                            if isDeleting {
                                ProgressView().tint(.deepVelvet)
                            } else {
                                Text("Delete My Account")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Color.red : Color.gray.opacity(0.3))
                        .foregroundColor(canSubmit ? .white : .white.opacity(0.5))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .disabled(!canSubmit || isDeleting)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
        }
        .alert("Are you absolutely sure?", isPresented: $showConfirmDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Account", role: .destructive) {
                performDelete()
            }
        } message: {
            Text("This will instantly delete all your data and log you out. There is no turning back.")
        }
        .alert("Could not delete", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }
    
    private var canSubmit: Bool {
        guard agreed else { return false }
        if deleteMethod == "password" {
            return !password.isEmpty
        } else {
            return otpCode.count == 6
        }
    }
    
    private func sendOtp() {
        isSendingOtp = true
        errorMessage = nil
        Task {
            do {
                try await auth.sendDeleteAccountOtp()
                await MainActor.run {
                    isSendingOtp = false
                    otpSentMessage = "Code sent to \(auth.currentUser?.email ?? "")"
                }
            } catch {
                await MainActor.run {
                    isSendingOtp = false
                    errorMessage = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                }
            }
        }
    }
    
    private func performDelete() {
        isDeleting = true
        errorMessage = nil
        Task {
            do {
                try await auth.deleteAccount(
                    method: deleteMethod,
                    password: deleteMethod == "password" ? password : nil,
                    otp: deleteMethod == "email" ? otpCode : nil,
                    agreement: agreed
                )
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .red : .white.opacity(0.4))
                    .font(.system(size: 20))
                configuration.label
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReportBugView: View {
    @Bindable var auth: AuthManager
    @State private var title = ""
    @State private var description = ""
    @State private var isSending = false
    @State private var errorMessage: String? = nil
    @State private var showSuccessAlert = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Report a Bug")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 24)
                    
                    Text("Found a bug? Tell us about it and we'll fix it as soon as possible.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.leading, 4)
                        
                        TextField("Brief summary of the issue", text: $title)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details / Steps to reproduce")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.leading, 4)
                        
                        TextEditor(text: $description)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                    }
                    .padding(.horizontal)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    Button {
                        submitReport()
                    } label: {
                        HStack {
                            if isSending {
                                ProgressView().tint(.deepVelvet)
                            } else {
                                Text("Submit Bug Report")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Color.activeCyan : Color.gray.opacity(0.3))
                        .foregroundColor(canSubmit ? .deepVelvet : .white.opacity(0.5))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .disabled(!canSubmit || isSending)
                    
                    Spacer()
                }
            }
        }
        .alert("Thank you!", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your report has been successfully submitted to Glimpse Console.")
        }
    }
    
    private var canSubmit: Bool {
        return !title.isEmpty && !description.isEmpty
    }
    
    private func submitReport() {
        isSending = true
        errorMessage = nil
        
        let model = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let deviceInfo = "Device: \(model) | iOS: \(systemVersion) | App: \(appVersion) (\(buildNumber))"
        
        Task {
            do {
                try await auth.reportBug(title: title, description: description, deviceInfo: deviceInfo)
                await MainActor.run {
                    isSending = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                }
            }
        }
    }
}

struct AboutGlimpseView: View {
    @Bindable var auth: AuthManager
    @State private var isShowingToS = false
    @State private var isShowingPrivacyPolicy = false
    @State private var isShowingDevMenu = false
    @State private var versionTaps = 0
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("About Glimpse")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 56)
                
                Image(systemName: "heart.text.square.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.activeCyan)
                    .padding(.top, 20)
                
                VStack(spacing: 4) {
                    Text("Glimpse for Couples")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                    Text("Version \(appVersion) (Build \(buildNumber))")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .onTapGesture {
                            versionTaps += 1
                            if versionTaps >= 7 {
                                versionTaps = 0
                                isShowingDevMenu = true
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            } else {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    
                    Text("Created by Lovinpeace")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.activeCyan)
                        .padding(.top, 4)
                }
                
                VStack(spacing: 0) {
                    Button {
                        isShowingToS = true
                    } label: {
                        CompactMenuRow(icon: "doc.text.fill", title: "Terms of Service", value: "View", color: .activeCyan)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.leading, 52)
                    
                    Button {
                        isShowingPrivacyPolicy = true
                    } label: {
                        CompactMenuRow(icon: "shield.fill", title: "Privacy Policy", value: "View", color: .activeCyan)
                    }
                }
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )
                .padding(.horizontal)
                
                Spacer()
                
                Text("© 2026 Lovinpeace. All Rights Reserved.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $isShowingToS) {
            LegalPlaceholderView(
                title: "Terms of Service",
                text: LegalTexts.tos
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingPrivacyPolicy) {
            LegalPlaceholderView(
                title: "Privacy Policy",
                text: LegalTexts.privacy
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingDevMenu) {
            DeveloperMenuView(auth: auth)
        }
    }
}

struct DeveloperMenuView: View {
    @Bindable var auth: AuthManager
    @State private var customBaseURL = ""
    @State private var simulatedLat = ""
    @State private var simulatedLon = ""
    @State private var isMockingLocation = false
    @State private var showSuccessAlert = false
    @State private var alertMsg = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Text("Developer Options")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.activeCyan)
                    .fontWeight(.semibold)
                }
                .padding()
                .background(Color.white.opacity(0.03))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Section 1: Server Config
                        VStack(alignment: .leading, spacing: 10) {
                            Text("API CONFIGURATION")
                                .font(.caption.bold())
                                .foregroundColor(.activeCyan)
                            
                            TextField("Base URL (e.g. http://localhost:8000)", text: $customBaseURL)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            
                            Button("Apply Base URL") {
                                if !customBaseURL.isEmpty {
                                    auth.baseURL = customBaseURL
                                    alertMsg = "Server URL changed to \(customBaseURL)"
                                    showSuccessAlert = true
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.activeCyan.opacity(0.15))
                            .foregroundColor(.activeCyan)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Section 2: Mock GPS Coordinates
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MOCK GPS COORDINATES")
                                .font(.caption.bold())
                                .foregroundColor(.activeCyan)
                            
                            Toggle(isOn: $isMockingLocation) {
                                Text("Mock Location Active")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .activeCyan))
                            
                            HStack(spacing: 12) {
                                TextField("Latitude", text: $simulatedLat)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .keyboardType(.decimalPad)
                                
                                TextField("Longitude", text: $simulatedLon)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .keyboardType(.decimalPad)
                            }
                            
                            Button("Inject Mock Coordinates") {
                                if let lat = Double(simulatedLat), let lon = Double(simulatedLon) {
                                    Task {
                                        await auth.pushLocationAndStatus(latitude: lat, longitude: lon, locationName: "Mock Location")
                                        await MainActor.run {
                                            alertMsg = "Successfully injected coordinates: \(lat), \(lon)"
                                            showSuccessAlert = true
                                        }
                                    }
                                } else {
                                    alertMsg = "Invalid Latitude/Longitude values."
                                    showSuccessAlert = true
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.activeCyan.opacity(0.15))
                            .foregroundColor(.activeCyan)
                            .cornerRadius(12)
                            .disabled(!isMockingLocation)
                        }
                        .padding(.horizontal)
                        
                        // Section 3: Clean Actions
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CACHE & CLEANUP")
                                .font(.caption.bold())
                                .foregroundColor(.activeCyan)
                            
                            Button("Clear All Caches") {
                                auth.clearImageCache()
                                alertMsg = "Image cache, temporary files, and voice notes cleared!"
                                showSuccessAlert = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
        }
        .onAppear {
            customBaseURL = auth.baseURL
            if let lat = auth.currentUser?.latitude, let lon = auth.currentUser?.longitude {
                simulatedLat = String(lat)
                simulatedLon = String(lon)
            }
        }
        .alert("Developer Menu", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMsg)
        }
    }
}

struct LegalPlaceholderView: View {
    let title: String
    let text: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.activeCyan)
                    .fontWeight(.semibold)
                }
                .padding()
                .padding(.top, 24)
                .background(Color.white.opacity(0.03))
                
                ScrollView {
                    Text(text)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.body)
                        .lineSpacing(6)
                        .padding()
                }
            }
        }
    }
}

struct AppMediaSettingsView: View {
    @Bindable var auth: AuthManager
    
    // State variables for permissions
    @State private var locationStatus: String = "Checking..."
    @State private var motionStatus: String = "Checking..."
    @State private var cameraStatus: String = "Checking..."
    @State private var notificationStatus: String = "Checking..."
    
    // Data usage & quality
    @AppStorage("glimpse_voice_quality", store: UserDefaults(suiteName: "group.glimpse.app")) var voiceQuality = "data_saver"
    
    // Cache
    @State private var cacheSize = "Calculating..."
    @State private var isShowingClearCacheAlert = false
    @State private var isShowingClearCacheSuccess = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("App Settings & Permissions")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 24)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Section 1: Device Permissions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Device Permissions")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                permissionRow(icon: "location.fill", title: "Always Location", value: locationStatus)
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)
                                
                                permissionRow(icon: "figure.walk", title: "Motion & Fitness", value: motionStatus)
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)
                                
                                permissionRow(icon: "camera.fill", title: "Camera Access", value: cameraStatus)
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)
                                
                                permissionRow(icon: "bell.fill", title: "Push Notifications", value: notificationStatus)
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)
                                
                                Button {
                                    openAppSettings()
                                } label: {
                                    HStack {
                                        Image(systemName: "gearshape.fill")
                                            .foregroundColor(.activeCyan)
                                            .frame(width: 28, height: 28)
                                        Text("Open Device Settings")
                                            .foregroundColor(.white)
                                            .font(.system(size: 15, weight: .medium))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.3))
                                            .font(.system(size: 12))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                }
                            }
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            )
                        }
                        
                        // Section 2: Data Usage & Quality
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Data Usage & Quality")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "waveform")
                                        .foregroundColor(.activeCyan)
                                        .frame(width: 28, height: 28)
                                    Text("Voice Note Quality")
                                        .foregroundColor(.white)
                                        .font(.system(size: 15, weight: .medium))
                                    Spacer()
                                    Picker("Voice Quality", selection: $voiceQuality) {
                                        Text("Data Saver").tag("data_saver")
                                        Text("High Quality").tag("high_quality")
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.activeCyan)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                            }
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            )
                        }
                        
                        // Section 3: Storage & Cache
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Storage & Cache")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                Button {
                                    isShowingClearCacheAlert = true
                                } label: {
                                    CompactMenuRow(icon: "trash.fill", title: "Clear cache storage", value: cacheSize, color: .activeCyan)
                                }
                            }
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            checkPermissions()
            cacheSize = auth.getImageCacheSize()
        }
        .alert("Clear Cache Storage?", isPresented: $isShowingClearCacheAlert) {
            Button("Clear", role: .destructive) {
                auth.clearImageCache()
                cacheSize = auth.getImageCacheSize()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                isShowingClearCacheSuccess = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all downloaded cached images and voice notes. They will be re-downloaded seamlessly when needed.")
        }
        .alert("Cache Cleared!", isPresented: $isShowingClearCacheSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All image and voice note caches have been successfully removed to free up your phone storage.")
        }
    }
    
    private func permissionRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.activeCyan)
                .frame(width: 28, height: 28)
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .medium))
            Spacer()
            Text(value)
                .foregroundColor(value == "Denied" || value == "Disabled" || value == "Not Allowed" ? .red : .white.opacity(0.6))
                .font(.system(size: 14))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func checkPermissions() {
        // 1. Location
        let locManager = CLLocationManager()
        switch locManager.authorizationStatus {
        case .authorizedAlways:
            locationStatus = "Always Allowed"
        case .authorizedWhenInUse:
            locationStatus = "While Using"
        case .denied, .restricted:
            locationStatus = "Denied"
        case .notDetermined:
            locationStatus = "Not Allowed"
        @unknown default:
            locationStatus = "Unknown"
        }
        
        // 2. Motion & Fitness
        let motionAvailable = CMMotionActivityManager.isActivityAvailable()
        if !motionAvailable {
            motionStatus = "Not Available"
        } else {
            if #available(iOS 11.0, *) {
                switch CMMotionActivityManager.authorizationStatus() {
                case .authorized: motionStatus = "Allowed"
                case .denied, .restricted: motionStatus = "Denied"
                case .notDetermined: motionStatus = "Not Checked"
                @unknown default: motionStatus = "Unknown"
                }
            } else {
                motionStatus = "Available"
            }
        }
        
        // 3. Camera
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraStatus = "Allowed"
        case .denied, .restricted:
            cameraStatus = "Denied"
        case .notDetermined:
            cameraStatus = "Not Checked"
        @unknown default:
            cameraStatus = "Unknown"
        }
        
        // 4. Notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    notificationStatus = "Allowed"
                case .denied:
                    notificationStatus = "Denied"
                case .notDetermined:
                    notificationStatus = "Not Checked"
                @unknown default:
                    notificationStatus = "Unknown"
                }
            }
        }
    }
}

struct ThemeAppearanceView: View {
    @Bindable var auth: AuthManager
    
    // Binding app storages
    @AppStorage("glimpse_theme_accent", store: UserDefaults(suiteName: "group.glimpse.app")) var themeAccentHex = "00FFFF"
    @AppStorage("glimpse_haptic_strength", store: UserDefaults(suiteName: "group.glimpse.app")) var hapticStrength = "rigid"
    @AppStorage("glimpse_dynamic_orbs", store: UserDefaults(suiteName: "group.glimpse.app")) var dynamicOrbsEnabled = true
    @AppStorage("glimpse_default_map_style", store: UserDefaults(suiteName: "group.glimpse.app")) var defaultMapStyle = "satellite"
    @AppStorage("glimpse_background_theme", store: UserDefaults(suiteName: "group.glimpse.app")) var backgroundTheme = "default"
    
    @State private var isShowingThemeSelection = false
    @State private var isShowingHapticSelection = false
    @State private var isShowingMapStyleSelection = false
    @State private var isShowingBackgroundThemeSelection = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Theme & Appearance")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 24)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Section 1: Customization options
                        VStack(alignment: .leading, spacing: 8) {
                            Text("App Styling")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                Button {
                                    isShowingThemeSelection = true
                                } label: {
                                    CompactMenuRow(icon: "paintpalette.fill", title: "App accent theme", value: activeThemeName(), color: .activeCyan)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)
                                
                                Button {
                                    isShowingBackgroundThemeSelection = true
                                } label: {
                                    CompactMenuRow(icon: "photo.on.rectangle.angled", title: "Background Theme", value: backgroundThemeTitle(), color: .activeCyan)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)
                                
                                Button {
                                    isShowingHapticSelection = true
                                } label: {
                                    CompactMenuRow(icon: "waveform.path", title: "Vibrations & haptics", value: hapticStrengthTitle(), color: .activeCyan)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)
                                
                                Button {
                                    isShowingMapStyleSelection = true
                                } label: {
                                    CompactMenuRow(icon: "map.fill", title: "Default map style", value: defaultMapStyleTitle(), color: .activeCyan)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)
                                
                                Button {
                                    dynamicOrbsEnabled.toggle()
                                    triggerHapticExample()
                                } label: {
                                    CompactMenuRow(icon: "circle.hexagongrid.fill", title: "Animated 3D Orbs", value: dynamicOrbsEnabled ? "Active" : "Off (Saves Battery)", color: .activeCyan)
                                }
                            }
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $isShowingThemeSelection) {
            ThemeSelectionView(accentHex: $themeAccentHex)
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingHapticSelection) {
            HapticSelectionView(hapticStrength: $hapticStrength)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingMapStyleSelection) {
            MapStyleSelectionView(defaultMapStyle: $defaultMapStyle)
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingBackgroundThemeSelection) {
            BackgroundThemeSelectionView(backgroundTheme: $backgroundTheme)
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func activeThemeName() -> String {
        switch themeAccentHex {
        case "00FFFF": return "Cyan"
        case "BF80FF": return "Purple"
        case "FF4D9E": return "Pink"
        case "00FF88": return "Green"
        case "FF8C42": return "Orange"
        case "FFD700": return "Gold"
        case "FF4D6D": return "Red"
        case "4D9EFF": return "Blue"
        case "FFFFFF": return "White"
        default: return "Custom"
        }
    }
    
    private func backgroundThemeTitle() -> String {
        switch backgroundTheme {
        case "default": return "Dynamic"
        case "solid": return "Solid Velvet"
        case "starry": return "Starry Space"
        case "aurora": return "Aurora Glow"
        case "neon": return "Neon Grid"
        case "dark": return "Pure Black"
        default: return "Dynamic"
        }
    }
    
    private func hapticStrengthTitle() -> String {
        switch hapticStrength {
        case "none": return "Disabled"
        case "light": return "Light"
        case "medium": return "Medium"
        case "soft": return "Soft & Subtle"
        case "heavy": return "Heavy Impact"
        case "success": return "Success Wave"
        case "warning": return "Alert Warnings"
        case "rigid": return "Crisp & Rigid"
        default: return "Crisp & Rigid"
        }
    }
    
    private func defaultMapStyleTitle() -> String {
        switch defaultMapStyle {
        case "standard": return "Standard Mode"
        case "satellite": return "Satellite Mode"
        case "hybrid": return "Hybrid Map"
        default: return "Satellite Mode"
        }
    }
    
    private func triggerHapticExample() {
        switch hapticStrength {
        case "light": UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case "medium": UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case "heavy": UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case "rigid": UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        default: break
        }
    }
}

struct HelpSupportView: View {
    @Bindable var auth: AuthManager
    
    @State private var isShowingReportBug = false
    @State private var isShowingAboutGlimpse = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Help & Support")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 24)
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Assistance")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                Button {
                                    isShowingReportBug = true
                                } label: {
                                    CompactMenuRow(icon: "ladybug.fill", title: "Report a bug", value: "Submit feedback", color: .activeCyan)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)
                                
                                Button {
                                    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                                        SKStoreReviewController.requestReview(in: scene)
                                    }
                                } label: {
                                    CompactMenuRow(icon: "star.fill", title: "Rate App", value: "Love Glimpse?", color: .activeCyan)
                                }
                            }
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $isShowingReportBug) {
            ReportBugView(auth: auth)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct LegalTexts {
    static let tos = "Welcome to Glimpse (the \"App\"). By creating an account or using Glimpse, you agree to be bound by these Terms of Service (\"Terms\"). If you do not agree to these Terms, please do not use the App.\n\n1. Purpose & Core Service\nGlimpse is designed as a real-time location-sharing and communication app for couples. Its primary function is to continuously share your live location coordinate details, battery levels, status notes, custom app settings, and active chat indicators with your single connected partner.\n\n2. Consent & Partner Linkage\nLocation sharing is activated exclusively when you pair with another user using a unique generated connection code. By sharing your invitation code or entering a partner's code, you explicitly consent to sharing your continuous background location and real-time updates with that designated partner. You may withdraw your consent and end sharing at any time by requesting to disconnect from your partner inside the Profile settings.\n\n3. Background Location & Battery Use\nTo ensure location updates work in real-time, the App requests permission to access your location in the background. Continuous use of background location tracking may significantly reduce your device's battery life. Glimpse is not responsible for battery drainage, data consumption charges, or network carrier costs associated with background GPS updates.\n\n4. Data Security & Storage\nWe transmit your coordinates and updates securely over HTTPS to our server at api.galleryfortwo.my.id. Your current location and partner status data are shared strictly with your connected partner and are not sold, distributed, or exposed to third-party advertising companies. We retain status logs, chat messages, and coordinates history solely for presenting you and your partner with timeline features.\n\n5. Account Safety & Prohibited Behavior\nYou are responsible for keeping your password and account details secure. You agree not to use the App to spy, stalk, or track anyone without their explicit consent. Installing the App on a device owned by someone else without their direct knowledge is strictly prohibited and constitutes a violation of these Terms.\n\n6. Disclaimers & Limitation of Liability\nGLIMPSE IS PROVIDED \"AS IS\" WITHOUT WARRANTY OF ANY KIND. We do not guarantee that GPS coordinates will always be accurate, that network connectivity to our servers will be uninterrupted, or that push notifications will be delivered instantly. We are not liable for any personal disputes, safety incidents, battery degradation, or loss of privacy resulting from your voluntary setup of partner sharing.\n\n7. Relationship Termination & Data Purge\nYou can unlink from your partner at any time. Once unlinked, all real-time sharing terminates immediately. If you choose to permanently delete your account, all personal details, location logs, active relation statuses, and chat message history will be purged completely and irreversibly from our database server records.\n\n8. Modifications to Terms\nWe reserve the right to modify these Terms at any time. Your continued use of the App following any updates constitutes acceptance of the new Terms.\n\n---\n\nCreated by Lovinpeace\n© 2026 Lovinpeace. All Rights Reserved."
    static let privacy = "Privacy Policy\n\nLast Updated: June 2026\n\n1. Information We Collect\nWhen you use Glimpse, we collect information you provide directly, such as your name, email address, password, and the unique partner code used to establish a relationship link. In addition, to fulfill the core purpose of the application, we continuously collect real-time background location coordinates (latitude and longitude), battery level, network status, and personal status notes.\n\n2. How We Use Your Information\nThe primary use of your data is to facilitate the Glimpse core experience: securely syncing your live status and precise location with your exclusively connected partner. Your chat messages, voice notes, and flash photos are stored securely to provide chat history. We do not use your location data or personal information for advertising, marketing, or behavioral tracking.\n\n3. Data Sharing & Disclosure\nYour real-time data is strictly shared ONLY with the one partner account you have explicitly linked to. We do not sell, rent, or trade your personal information to third parties, advertisers, or data brokers under any circumstances. In extremely rare cases, we may disclose information if required by a valid legal subpoena or to protect the safety of our users.\n\n4. Data Retention & Deletion\nLocation history and chat messages are retained on our servers at api.galleryfortwo.my.id to allow you and your partner to view your historical timeline. If you break the connection with your partner, real-time sharing stops immediately. If you choose to delete your account via the settings menu, all associated location logs, messages, and personally identifiable information are permanently and irreversibly purged from our active databases.\n\n5. Security Measures\nWe employ industry-standard security measures including HTTPS encryption in transit and secure hashed passwords in our database to protect your account. However, no electronic transmission or storage is 100% secure. You are responsible for keeping your login credentials confidential.\n\n6. Your Consent\nBy installing Glimpse and linking with a partner, you provide explicit consent for the continuous collection and sharing of your background location data as described in this policy.\n\n7. Contact Us\nIf you have questions about this Privacy Policy or how your data is handled, please contact our support team through the 'Report a Bug' section within the App.\n\n---\n\nCreated by Lovinpeace\n© 2026 Lovinpeace. All Rights Reserved."
}
