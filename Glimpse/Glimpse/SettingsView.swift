#if !WIDGET
import SwiftUI
import CoreLocation
import PhotosUI

struct SettingsView: View {
    @Bindable var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var inviteCodeInput = ""
    @State private var isShowingInviteAlert = false
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
    @State private var isShowingAppMediaSettings = false
    @State private var isShowingThemeAppearance = false
    @State private var isShowingHelpSupport = false
    @State private var isShowingAboutGlimpse = false
    @State private var cacheSize = "Calculating..."
    @State private var isCopied = false
    
    @AppStorage("glimpse_theme_accent", store: UserDefaults(suiteName: "group.glimpse.app")) var themeAccentHex = "00FFFF"
    @AppStorage("glimpse_haptic_strength", store: UserDefaults(suiteName: "group.glimpse.app")) var hapticStrength = "rigid"
    @AppStorage("glimpse_background_theme", store: UserDefaults(suiteName: "group.glimpse.app")) var backgroundTheme = "default"
    @AppStorage("glimpse_default_map_style", store: UserDefaults(suiteName: "group.glimpse.app")) var defaultMapStyle = "satellite"
    
    @State private var backupManager = GoogleDriveBackupManager.shared

    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerView
                    
                    // 1. Relationship Section
                    relationshipSection
                    
                    // 2. Settings & Options
                    settingsSection
                    
                    // 2b. Cloud Backup
                    cloudBackupSection
                    
                    // 3. About & Legal
                    aboutLegalSection
                    
                    // 4. Logout
                    logoutButton
                    
                    // 5. Footer branding
                    footerBranding
                }
            }
        }

        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            cacheSize = auth.getImageCacheSize()
            auth.isHidingBrandingHeader = true
        }
        .onDisappear {
            auth.isHidingBrandingHeader = false
        }
    }
    
    // MARK: - Extracted Subviews
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.activeCyan)
            }
            Spacer()
            Text("Settings")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            // Spacer placeholder to balance back button
            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    private var relationshipSection: some View {
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
                                CompactMenuRow(icon: "envelope.fill", title: "Invite sent to \(partner.name)", value: "Pending", color: .activeCyan)
                            }
                        } else {
                            Button {
                                isShowingAcceptInviteConfirmation = true
                            } label: {
                                CompactMenuRow(icon: "envelope.badge.fill", title: "Invite from \(partner.name)", value: "Review", color: .activeCyan)
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
        .sheet(isPresented: $isShowingEditAnniversary) {
            EditAnniversaryView(auth: auth)
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
        }
        .alert("Connect Partner", isPresented: $isShowingInviteAlert) {
            TextField("Partner code", text: $inviteCodeInput)
                .autocapitalization(.allCharacters)
            Button("Connect") { connectPartner() }
            Button("Cancel", role: .cancel) {}
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
    }
    
    private var settingsSection: some View {
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
        .sheet(isPresented: $isShowingThemeAppearance) {
            ThemeAppearanceView(auth: auth)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingAppMediaSettings) {
            AppMediaSettingsView(auth: auth)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingHelpSupport) {
            HelpSupportView(auth: auth)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Clear Cache Storage?", isPresented: $isShowingClearCacheAlert) {
            Button("Clear", role: .destructive) {
                auth.clearImageCache()
                cacheSize = auth.getImageCacheSize()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                if backupManager.isConnected {
                    backupManager.performRestoreFlow(auth: auth)
                }
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
    
    private var cloudBackupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Cloud Backup")
            
            // Auto-restore banner: shown once after login when Drive token found on server
            if auth.shouldPromptAutoRestore {
                HStack(spacing: 12) {
                    Image(systemName: "icloud.and.arrow.down.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.activeCyan)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Backup found on Google Drive")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("Restore data from your latest backup?")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 6) {
                        Button {
                            auth.shouldPromptAutoRestore = false
                            backupManager.performRestoreFlow(auth: auth)
                        } label: {
                            Text("Restore")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.activeCyan)
                                .cornerRadius(8)
                        }
                        
                        Button {
                            withAnimation { auth.shouldPromptAutoRestore = false }
                        } label: {
                            Text("Later")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.activeCyan.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.activeCyan.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            VStack(spacing: 0) {
                GoogleDriveBackupRow(auth: auth)
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
            )
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.3), value: auth.shouldPromptAutoRestore)
    }
    
    private var aboutLegalSection: some View {
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
        .sheet(isPresented: $isShowingAboutGlimpse) {
            AboutGlimpseView(auth: auth)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var logoutButton: some View {
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
        .alert("Logout", isPresented: $isShowingLogoutConfirmation) {
            Button("Logout", role: .destructive) {
                auth.logout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to logout? You will need to login again to see your partner's updates.")
        }
    }
    
    private var footerBranding: some View {
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
        .padding(.top, 20)
        .padding(.bottom, 30)
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
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formattedPairedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return "paired " + formatter.string(from: date).lowercased()
    }
}

// MARK: - Google Drive Backup Row Component
struct GoogleDriveBackupRow: View {
    @Bindable var auth: AuthManager
    @State private var backupManager = GoogleDriveBackupManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "icloud.and.arrow.up.fill")
                    .foregroundColor(backupManager.isConnected ? .green : .activeCyan)
                    .font(.system(size: 20))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Google Drive Backup")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    if backupManager.isConnected {
                        Text(backupManager.userEmail ?? "Connected")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Text("Not connected")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                Spacer()
                
                if backupManager.isConnected {
                    Button {
                        Task {
                            let success = await backupManager.connect(loginHint: nil)
                            if success {
                                await backupManager.runBackup(flashes: auth.flashes)
                            }
                        }
                    } label: {
                        Text("Change Account")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.activeCyan)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.activeCyan.opacity(0.1))
                            .cornerRadius(8)
                    }
                } else {
                    Button {
                        Task {
                            let success = await backupManager.connect(loginHint: auth.currentUser?.email)
                            if success {
                                await backupManager.runBackup(flashes: auth.flashes)
                            }
                        }
                    } label: {
                        Text("Connect")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.activeCyan)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            
            if backupManager.isConnected {
                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.leading, 48)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Backup Progress")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if backupManager.isBackingUp {
                            ProgressView(value: backupManager.backupProgress)
                                .tint(.activeCyan)
                            Text("\(Int(backupManager.backupProgress * 100))% backed up...")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            if let error = backupManager.errorMessage {
                                Text("Error: \(error)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                            } else {
                                let rawBackedUpIds = UserDefaults.standard.array(forKey: "backed_up_flash_ids") as? [Int] ?? []
                                let currentFlashIds = Set(auth.flashes.map { $0.id })
                                let backedUpIds = rawBackedUpIds.filter { currentFlashIds.contains($0) }
                                Text("\(backedUpIds.count) of \(auth.flashes.count) flashes backed up")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Button {
                            Task {
                                await backupManager.runBackup(flashes: auth.flashes)
                            }
                        } label: {
                            Text(backupManager.isBackingUp ? "Backing up..." : "Backup Now")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 120)
                                .padding(.vertical, 8)
                                .background(backupManager.isBackingUp ? Color.white.opacity(0.1) : Color.white.opacity(0.08))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                 )
                        }
                        .disabled(backupManager.isBackingUp)
                        
                        Button {
                            backupManager.performRestoreFlow(auth: auth)
                        } label: {
                            Text("Restore Database")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.activeCyan)
                                .frame(width: 120)
                                .padding(.vertical, 6)
                                .background(Color.activeCyan.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.activeCyan.opacity(0.25), lineWidth: 1)
                                )
                        }
                        .disabled(backupManager.isRestoring)
                    }
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func getPresentationAnchor() -> UIWindow? {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.windows.first
        }
        return nil
    }
}
#endif
