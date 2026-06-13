import SwiftUI
import Combine
import AudioToolbox
import MapKit

struct MainDashboardView: View {
    @State private var auth = AuthManager.shared
    @ObservedObject private var audioPlayerManager = AudioPlayManager.shared
    @State private var togetherAnimation = false
    @State private var streakPulse = false
    @State private var lastSeenLoveBurstTimestamp: Double = 0.0
    @State private var popHearts: [PopHeart] = []
    @State private var expandedFlashId: Int? = nil
    @State private var visibleFlashLimit: Int = 3
    @State private var streakCardBounce = false
    @State private var anniversaryCardBounce = false
    @State private var scheduleCardBounce = false
    @State private var selectedDetailSchedule: GlimpseSchedule? = nil
    @State private var showScheduleDetailPopup = false
    @State private var showReactions = false
    @State private var reactionCardScale: CGFloat = 1.0
    @State private var reactionHoveredIndex: Int? = nil
    @State private var touchStartTime: Date? = nil
    @State private var isLongPressActive = false
    @State private var activeReactionBadge: String? = nil
    @State private var showReactionBadge = false
    @State private var reactionBadgeScale: CGFloat = 0.0
    @State private var reactionBadgeAngle: Double = 0.0
    @State private var edgeReactions: [EdgeReaction] = []
    @State private var isSuppressingGlobalLoveBurst = false
    @State private var pollCounter = 0
    @State private var currentTime = Date()
    private let dashboardPollTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    @State private var dashboardScrollOffset: CGFloat = 0
    @State private var profileScrollOffset: CGFloat = 0
    
    // Toast notifications for dashboard kencan activities
    @State private var dashboardToastMessage = ""
    @State private var showDashboardToast = false
    @State private var isDashboardToastSuccess = true
    
    // Bump Animation State
    @State private var isShowingBumpAnimation = false
    @State private var lastSeenLoveBumpTimestamp: Double = 0.0
    @State private var playerDragOffset: CGFloat = 0
    @State private var isPlayerDismissing = false
    @AppStorage("glimpse_theme_accent", store: UserDefaults(suiteName: "group.glimpse.app")) private var themeAccentHex = "00FFFF"
    
    private var headerOpacity: Double {
        if auth.selectedTab == 0 {
            // Dashboard: fade out between offset 0 and -60
            if dashboardScrollOffset >= 0 {
                return 1.0
            } else if dashboardScrollOffset <= -60 {
                return 0.0
            } else {
                return Double(1.0 + (dashboardScrollOffset / 60.0))
            }
        } else if auth.selectedTab == 4 {
            // Profile: fade out between offset 0 and -60
            if profileScrollOffset >= 0 {
                return 1.0
            } else if profileScrollOffset <= -60 {
                return 0.0
            } else {
                return Double(1.0 + (profileScrollOffset / 60.0))
            }
        } else {
            // Other tabs (like Map or Flash Camera) - keep full opacity!
            return 1.0
        }
    }
    
    private var streakFlameColors: [Color] {
        let count = auth.togetherStreak
        if count >= 15 {
            return [.white, .activeCyan]
        } else if count >= 7 {
            return [.electricPurple, Color(hex: "FF4D94")]
        } else if count >= 3 {
            return [.red, .pink]
        } else {
            return [.orange, .yellow]
        }
    }
    
    private var streakGlowColor: Color {
        let count = auth.togetherStreak
        if count >= 15 {
            return .activeCyan
        } else if count >= 7 {
            return .electricPurple
        } else if count >= 3 {
            return .red
        } else {
            return .orange
        }
    }

    private var streakPulseAmount: CGFloat {
        let count = auth.togetherStreak
        if count >= 15 {
            return streakPulse ? 1.4 : 0.8
        } else if count >= 7 {
            return streakPulse ? 1.3 : 0.85
        } else if count >= 3 {
            return streakPulse ? 1.22 : 0.9
        } else {
            return streakPulse ? 1.15 : 0.95
        }
    }
    
    private var streakAnimationDuration: Double {
        let count = auth.togetherStreak
        if count >= 15 {
            return 0.4
        } else if count >= 7 {
            return 0.6
        } else if count >= 3 {
            return 0.8
        } else {
            return 1.1
        }
    }
    
    var body: some View {
        @Bindable var bindableAuth = auth
        return ZStack(alignment: .top) {
            // GLOBAL BACKGROUND to fill safe areas
            Color.adaptiveBackground.ignoresSafeArea()
            
            // Standard Native TabView
            TabView(selection: $bindableAuth.selectedTab) {
                // Tab 0: Dashboard
                dashboardView
                    .tabItem {
                        Image(systemName: "house.fill")
                    }
                    .tag(0)
                
                // Tab 1: Map
                Group {
                    if let partner = auth.partner, auth.coupleActive {
                        FullPartnerMapView(user: partner)
                    } else {
                        VStack(spacing: 15) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Map is currently empty")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.adaptiveBackground)
                    }
                }
                .tabItem {
                    Image(systemName: "map.fill")
                }
                .tag(1)
                
                // Tab 2: Flash
                FlashCameraView()
                    .tabItem {
                        Image(systemName: "camera.fill")
                    }
                    .tag(2)
                
                // Tab 3: Chat
                ChatView()
                    .tabItem {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                    }
                    .badge(auth.unreadMessagesCount > 0 ? Text("\(auth.unreadMessagesCount)") : nil)
                    .tag(3)
                
                // Tab 4: Profile
                ProfileView(scrollOffset: $profileScrollOffset)
                    .tabItem {
                        Image(systemName: "person.fill")
                    }
                    .tag(4)
            }
            .tint(.electricPurple)
            
            if showReactions {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            showReactions = false
                            reactionCardScale = 1.0
                        }
                    }
                    .zIndex(190)
            }
            
            // MASTER HEADER (Like app.blade.php)
            if auth.selectedTab != 3 || auth.selectedChatRoom == nil {
                BrandingHeader(
                    coupleActive: auth.coupleActive,
                    selectedTab: auth.selectedTab,
                    onCalendarTap: {
                        auth.showScheduleSheet = true
                    }
                )
                .opacity(headerOpacity)
                .allowsHitTesting(headerOpacity > 0.1) // Avoid blocking interaction when transparent
                .zIndex(100)
            }

            
            // GLOBAL POP HEARTS OVERLAY (BOTTOM TO TOP FLOATERS)
            ZStack {
                ForEach(popHearts) { heart in
                    PopHeartView(heart: heart)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .zIndex(999)
            
            // Custom Toast Notification overlay
            if showDashboardToast {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: isDashboardToastSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(isDashboardToastSuccess ? .activeCyan : .orange)
                        
                        Text(dashboardToastMessage)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isDashboardToastSuccess ? Color.activeCyan.opacity(0.4) : Color.orange.opacity(0.4), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 10, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(9999)
            }
            
            // Premium Bump Popup overlay
            if isShowingBumpAnimation {
                PremiumBumpPopup(
                    totalMeetings: auth.totalMeetings,
                    dailyBumps: auth.dailyBumps,
                    onDismiss: {
                        withAnimation {
                            isShowingBumpAnimation = false
                        }
                    }
                )
                .zIndex(10000)
            }
            
            // FLOATING AUDIO PLAYER OVERLAY
            if let playingMsg = audioPlayerManager.playingMessage,
               audioPlayerManager.playingMessageId != nil,
               !isInsideActiveChatRoomOfPlayingMessage {
                
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Play/Pause button
                        Button {
                            if audioPlayerManager.isPlaying {
                                audioPlayerManager.pause()
                            } else {
                                audioPlayerManager.resume()
                            }
                        } label: {
                            Image(systemName: audioPlayerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        
                        // Text & Progress Bar (Tap to Navigate)
                        VStack(alignment: .leading, spacing: 4) {
                            let isMe = playingMsg.sender_id == auth.currentUser?.id
                            let displayName = isMe ? "You" : (auth.partner?.name ?? "Partner")
                            Text("Voice Note from \(displayName)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            // Simple linear progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 4)
                                    
                                    let progress = audioPlayerManager.totalDuration > 0 ? CGFloat(audioPlayerManager.currentTime / audioPlayerManager.totalDuration) : 0.0
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color(hex: themeAccentHex))
                                        .frame(width: geo.size.width * progress, height: 4)
                                }
                            }
                            .frame(height: 4)
                        }
                        
                        // Speed Adjustment Button (1x / 1.5x / 2x)
                        Button {
                            let currentSpeed = audioPlayerManager.playbackSpeed
                            let nextSpeed: Float
                            if currentSpeed == 1.0 {
                                nextSpeed = 1.5
                            } else if currentSpeed == 1.5 {
                                nextSpeed = 2.0
                            } else {
                                nextSpeed = 1.0
                            }
                            audioPlayerManager.setSpeed(nextSpeed)
                        } label: {
                            let speedText = audioPlayerManager.playbackSpeed == 1.5 ? "1.5x" : (audioPlayerManager.playbackSpeed == 2.0 ? "2x" : "1x")
                            Text(speedText)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 26)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(6)
                        }
                        
                        // Close/Stop button
                        Button {
                            audioPlayerManager.stop()
                            audioPlayerManager.playingMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: themeAccentHex).opacity(0.4), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 64)
                    .shadow(color: Color.black.opacity(0.4), radius: 10, y: 5)
                    .offset(y: playerDragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if isPlayerDismissing { return }
                                
                                playerDragOffset = value.translation.height
                                
                                let threshold: CGFloat = 80
                                if value.translation.height > threshold {
                                    isPlayerDismissing = true
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        playerDragOffset = 300
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        audioPlayerManager.stop()
                                        audioPlayerManager.playingMessage = nil
                                        playerDragOffset = 0
                                        isPlayerDismissing = false
                                    }
                                } else if value.translation.height < -threshold {
                                    isPlayerDismissing = true
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        playerDragOffset = -300
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        audioPlayerManager.stop()
                                        audioPlayerManager.playingMessage = nil
                                        playerDragOffset = 0
                                        isPlayerDismissing = false
                                    }
                                }
                            }
                            .onEnded { value in
                                if isPlayerDismissing { return }
                                
                                let threshold: CGFloat = 70
                                let velocity = value.predictedEndTranslation.height - value.translation.height
                                
                                if value.translation.height > threshold || velocity > 150 {
                                    isPlayerDismissing = true
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        playerDragOffset = 300
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        audioPlayerManager.stop()
                                        audioPlayerManager.playingMessage = nil
                                        playerDragOffset = 0
                                        isPlayerDismissing = false
                                    }
                                } else if value.translation.height < -threshold || velocity < -150 {
                                    isPlayerDismissing = true
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        playerDragOffset = -300
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        audioPlayerManager.stop()
                                        audioPlayerManager.playingMessage = nil
                                        playerDragOffset = 0
                                        isPlayerDismissing = false
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        playerDragOffset = 0
                                    }
                                }
                            }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(500)
                }
            }
        }
        .onAppear {
            LiveLocationManager.shared.startTracking()
            Task {
                try? await auth.fetchState()
                _ = try? await auth.fetchFlashes()
            }
        }
        .onReceive(dashboardPollTimer) { _ in
            currentTime = Date()
            pollCounter += 1
            
            // WebSockets are not connected when coupleActive is false.
            // Poll state periodically (every 4 seconds) to detect partner connections and pending invite status changes in real-time.
            if !auth.coupleActive && pollCounter % 4 == 0 {
                Task {
                    try? await auth.fetchState()
                }
            }
        }
        // React instantly to real-time Love Burst triggers via WebSocket
        .onChange(of: auth.lastLoveBurstTimestamp) { oldValue, newValue in
            if newValue > lastSeenLoveBurstTimestamp {
                lastSeenLoveBurstTimestamp = newValue
                if isSuppressingGlobalLoveBurst {
                    isSuppressingGlobalLoveBurst = false
                } else {
                    if let reaction = auth.lastLoveBurstReaction {
                        // Partner reacted! Display reaction animations ONLY (no full screen sparks!)
                        triggerEdgeReactionAnimation(reaction)
                        activeReactionBadge = reaction
                        reactionBadgeAngle = Double.random(in: -15...15)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            showReactionBadge = true
                            reactionBadgeScale = 1.2
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                reactionBadgeScale = 1.0
                            }
                        }
                        
                        let currentBadge = reaction
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            if activeReactionBadge == currentBadge {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    reactionBadgeScale = 0.0
                                    showReactionBadge = false
                                }
                            }
                        }
                        auth.lastLoveBurstReaction = nil
                    } else {
                        // General love ping! Display standard floating hearts
                        triggerLoveBurst()
                    }
                }
            }
        }
        .alert("Request Declined", isPresented: $bindableAuth.showInviteDeclinedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your connection request was declined or cancelled.")
        }
        .sheet(isPresented: $bindableAuth.showScheduleSheet) {
            SchedulePlannerView()
        }
        .sheet(item: $selectedDetailSchedule) { schedule in
            ScheduleDetailSheetView(
                schedule: schedule,
                auth: auth,
                isPresented: Binding(
                    get: { selectedDetailSchedule != nil },
                    set: { if !$0 { selectedDetailSchedule = nil } }
                ),
                showToast: $showDashboardToast,
                toastMessage: $dashboardToastMessage,
                toastSuccess: $isDashboardToastSuccess
            )
        }
        .onShake {
            if auth.isTogether && auth.coupleActive {
                UISelectionFeedbackGenerator().selectionChanged()
                Task {
                    try? await auth.triggerServerBump()
                }
            }
        }
        .onChange(of: auth.lastLoveBumpTimestamp) { oldValue, newValue in
            if newValue > lastSeenLoveBumpTimestamp {
                lastSeenLoveBumpTimestamp = newValue
                if auth.isTogether && auth.coupleActive {
                    withAnimation {
                        isShowingBumpAnimation = true
                    }
                    
                    // Auto-dismiss after 4.0 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation {
                            isShowingBumpAnimation = false
                        }
                    }
                }
            }
        }
    }
    
    private var dashboardView: some View {
        ZStack(alignment: .top) {
            // Background
            iOS26Background()
            
            // Main Scroll Content
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    ZStack {
                        // Scroll Position Detector
                        GeometryReader { geo in
                            Color.clear.preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("dashboard_scroll")).minY)
                        }
                        .frame(height: 0)
                        
                        VStack(spacing: 20) {
                            Spacer(minLength: 65) // Space for floating header
                                .id("SCROLL_TOP_ANCHOR")
                    
                    // Presence Interface (Interactive Flip Card)
                    // Presence Interface (Interactive Flip Card)
                    if !auth.isInitialStateLoaded {
                        // PRESTIGE LOADING / SHIMMERING STATE
                        VStack(spacing: 20) {
                            ProgressView()
                                .tint(.electricPurple)
                                .scaleEffect(1.3)
                            Text("Loading Glimpse space...")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.vertical, 120)
                        .frame(maxWidth: .infinity)
                    } else if let partner = auth.partner {
                        if auth.coupleActive {
                            if let reqBy = auth.disconnectRequestedBy, reqBy == partner.id {
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.title2)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Disconnect Request")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("\(partner.name) wants to unlink from you.")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        Spacer()
                                    }
                                    
                                    HStack(spacing: 15) {
                                        Button {
                                            Task { try? await auth.approveDisconnectPartner() }
                                        } label: {
                                            Text("Approve Disconnect")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.red)
                                                .cornerRadius(10)
                                        }
                                        
                                        Button {
                                            Task { try? await auth.cancelDisconnectPartner() }
                                        } label: {
                                            Text("Decline")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.white.opacity(0.15))
                                                .cornerRadius(10)
                                        }
                                        Spacer()
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.bottom, 5)
                            }
                            
                            if auth.isTogether {
                                Button {
                                    isSuppressingGlobalLoveBurst = true
                                    triggerLoveBurst()
                                    Task {
                                        try? await auth.triggerServerLoveBurst()
                                    }
                                    
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                } label: {
                                    VStack(spacing: 12) {
                                        Text("Together right now")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .opacity(0.9)
                                        
                                        // Animated overlapping avatars
                                        HStack(spacing: -12) {
                                            // Self Profile Photo
                                            CachedImageView(urlString: auth.currentUser?.profile_photo_url ?? "")
                                                .frame(width: 65, height: 65)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.activeCyan, lineWidth: 2))
                                                .shadow(color: .activeCyan.opacity(0.6), radius: 12)
                                                .offset(x: togetherAnimation ? 6 : -6)
                                            
                                            // Glassmorphic Glowing Pulsing Heart in Between
                                            ZStack {
                                                Circle()
                                                    .fill(Color.red.opacity(0.15))
                                                    .frame(width: 38, height: 38)
                                                    .blur(radius: 4)
                                                
                                                Image(systemName: "heart.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.red)
                                                    .shadow(color: .red.opacity(0.8), radius: 10)
                                            }
                                            .scaleEffect(togetherAnimation ? 1.3 : 0.85)
                                            .zIndex(10)
                                            
                                            // Partner Profile Photo
                                            CachedImageView(urlString: partner.profile_photo_url)
                                                .frame(width: 65, height: 65)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.activeCyan, lineWidth: 2))
                                                .shadow(color: .activeCyan.opacity(0.6), radius: 12)
                                                .offset(x: togetherAnimation ? -6 : 6)
                                        }
                                        .padding(.vertical, 8)
                                        .onAppear {
                                            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                                togetherAnimation = true
                                            }
                                        }
                                        
                                        Text("Tap to send love sparks")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white.opacity(0.4))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 4)
                                            .background(Color.white.opacity(0.06))
                                            .clipShape(Capsule())
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                                    .background {
                                        ZStack {
                                            Color.clear.liquidGlass()
                                            
                                            // Dynamic subtle pulse background circle
                                            Circle()
                                                .stroke(Color.electricPurple.opacity(0.1), lineWidth: 1)
                                                .scaleEffect(togetherAnimation ? 1.2 : 0.9)
                                                .opacity(togetherAnimation ? 0.0 : 0.8)
                                        }
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(
                                                LinearGradient(colors: [.electricPurple.opacity(0.4), .activeCyan.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                                lineWidth: 1.5
                                            )
                                    )
                                    .shadow(color: .electricPurple.opacity(0.2), radius: 15)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.bottom, 12)
                            }
                            
                            PartnerMapView(user: partner)
                                .aspectRatio(1, contentMode: .fit)
                                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                                .onTapGesture {
                                    // Tap = flip the card with haptic (no swipe needed)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    NotificationCenter.default.post(name: NSNotification.Name("FlipDashboardCard"), object: nil)
                                }
                            
                            // Together Streak & Meeting Counters Card (Interactive & Haptic!)
                            VStack(spacing: 12) {
                                HStack(spacing: 16) {
                                    // Left Side: Streak
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(LinearGradient(colors: streakFlameColors.map { $0.opacity(0.2) }, startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(width: 44, height: 44)
                                                .shadow(color: streakGlowColor.opacity(0.3), radius: 6)
                                            
                                            Image(systemName: "flame.fill")
                                                .font(.title2)
                                                .foregroundStyle(LinearGradient(colors: streakFlameColors, startPoint: .top, endPoint: .bottom))
                                                .shadow(color: streakGlowColor, radius: 8)
                                                .shadow(color: .white.opacity(auth.togetherStreak >= 15 ? 0.8 : 0.0), radius: 10)
                                                .scaleEffect(streakPulseAmount)
                                                .id(auth.togetherStreak) // Forces animation restart when streak updates!
                                                .onAppear {
                                                    withAnimation(.easeInOut(duration: streakAnimationDuration).repeatForever(autoreverses: true)) {
                                                        streakPulse = true
                                                    }
                                                }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(auth.togetherStreak)")
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            Text("Together Streak")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Divider line
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 1, height: 35)
                                    
                                    // Right Side: Total Meetings
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(LinearGradient(colors: [Color.electricPurple.opacity(0.2), Color.royalPurple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(width: 44, height: 44)
                                            
                                            Image(systemName: "heart.text.square.fill")
                                                .font(.title2)
                                                .foregroundColor(.electricPurple)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(auth.totalMeetings)")
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            Text("Days Met")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.vertical, 4)
                                
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 13, weight: .bold))
                                        .shadow(color: .yellow.opacity(0.4), radius: 4)
                                    Text("Highest Streak Together")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    Text("\(auth.highestTogetherStreak) days")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.yellow)
                                        .shadow(color: .yellow.opacity(0.6), radius: 8)
                                }
                                .padding(.horizontal, 4)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .liquidGlass()
                            .scaleEffect(streakCardBounce ? 0.96 : 1.0)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                    streakCardBounce = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                        streakCardBounce = false
                                    }
                                }
                            }
                            .padding(.top, 5)
                            
                            // 🎂 USER's Birthday Card
                            if let user = auth.currentUser, user.isBirthdayToday {
                                VStack(spacing: 8) {
                                    Text("🎂 Happy Birthday! 🎉")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.orange)
                                        .shadow(color: .orange.opacity(0.4), radius: 5)
                                    
                                    Text("Wishing you a beautiful year filled with love, magic, and countless happy Glimpses together!")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.85))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 10)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [.orange.opacity(0.18), .red.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.orange.opacity(0.45), lineWidth: 1.2)
                                )
                                .shadow(color: Color.orange.opacity(0.15), radius: 8, y: 3)
                                .padding(.top, 8)
                            }
                            
                            // 🎂 PARTNER's Birthday Card
                            if let partner = auth.partner, partner.isBirthdayToday {
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "gift.fill")
                                            .foregroundColor(.pink)
                                            .font(.system(size: 22))
                                            .shadow(color: .pink.opacity(0.4), radius: 5)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("It's \(partner.name)'s Birthday Today! 🎂")
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundColor(.pink)
                                            Text("Don't forget to wish them a magical day!")
                                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        Spacer()
                                    }
                                    
                                    Button {
                                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                        auth.selectedTab = 3
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "heart.fill")
                                            Text("Send Birthday Wishes")
                                        }
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.pink)
                                        .cornerRadius(12)
                                        .shadow(color: Color.pink.opacity(0.35), radius: 5)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [.pink.opacity(0.18), .electricPurple.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.pink.opacity(0.45), lineWidth: 1.2)
                                )
                                .shadow(color: Color.pink.opacity(0.15), radius: 8, y: 3)
                                .padding(.top, 8)
                            }
                            
                            // Active Schedule / Date Invitation Card (Interactive & Haptic!)
                            if let schedule = auth.activeSchedule {
                                let isCreator = schedule.creator_id == (auth.currentUser?.id ?? 0)
                                let alarmTime = schedule.scheduledDate.addingTimeInterval(TimeInterval(-schedule.reminder_minutes * 60))
                                
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "calendar")
                                                    .foregroundColor(.activeCyan)
                                                    .font(.system(size: 14))
                                                Text(schedule.status == "pending" ? "Date Invitation" : "Upcoming Date")
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundColor(.activeCyan)
                                            }
                                            
                                            Text(schedule.title)
                                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.top, 2)
                                            
                                            Text(schedule.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                                                let timeString = timeRemainingString(from: context.date, to: schedule.scheduledDate)
                                                
                                                if !timeString.isEmpty {
                                                    HStack(spacing: 3) {
                                                        Image(systemName: "hourglass.badge.ellipsis")
                                                            .font(.system(size: 8))
                                                        Text("\(timeString) left")
                                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                    }
                                                    .foregroundColor(.activeCyan)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2.5)
                                                    .background(Color.activeCyan.opacity(0.12))
                                                    .cornerRadius(5)
                                                    .padding(.top, 2)
                                                } else {
                                                    HStack(spacing: 3) {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.system(size: 8))
                                                        Text("Happening Now!")
                                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                                    }
                                                    .foregroundColor(.vividMint)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2.5)
                                                    .background(Color.vividMint.opacity(0.12))
                                                    .cornerRadius(5)
                                                    .padding(.top, 2)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // RSVP badge
                                        VStack(spacing: 2) {
                                            Text(schedule.scheduledDate.formatted(.dateTime.day()))
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            Text(schedule.scheduledDate.formatted(.dateTime.month(.abbreviated)))
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                    
                                    // Reminder info
                                    HStack(spacing: 6) {
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 11))
                                        Text("Alarm set for: \(schedule.reminder_minutes)m before (\(alarmTime.formatted(date: .omitted, time: .shortened)))")
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                    }
                                    .foregroundColor(.white.opacity(0.6))
                                    
                                    // Respond controls if pending
                                    if schedule.status == "pending" {
                                        if !isCreator {
                                            HStack(spacing: 12) {
                                                Button {
                                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                                    generator.impactOccurred()
                                                    Task {
                                                        do {
                                                            try await auth.respondToSchedule(id: schedule.id, accept: true)
                                                            isDashboardToastSuccess = true
                                                            dashboardToastMessage = "Accepted the date! Set your alarm now."
                                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                                showDashboardToast = true
                                                            }
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                                withAnimation { showDashboardToast = false }
                                                            }
                                                        } catch {
                                                            isDashboardToastSuccess = false
                                                            dashboardToastMessage = error.localizedDescription
                                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                                showDashboardToast = true
                                                            }
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                                withAnimation { showDashboardToast = false }
                                                            }
                                                        }
                                                    }
                                                } label: {
                                                    Text("Accept Date")
                                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                                        .foregroundColor(.deepVelvet)
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.vertical, 10)
                                                        .background(Color.activeCyan)
                                                        .cornerRadius(12)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                
                                                Button {
                                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                                    generator.impactOccurred()
                                                    Task {
                                                        do {
                                                            try await auth.respondToSchedule(id: schedule.id, accept: false)
                                                            isDashboardToastSuccess = true
                                                            dashboardToastMessage = "Date invitation declined."
                                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                                showDashboardToast = true
                                                            }
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                                withAnimation { showDashboardToast = false }
                                                            }
                                                        } catch {
                                                            isDashboardToastSuccess = false
                                                            dashboardToastMessage = error.localizedDescription
                                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                                showDashboardToast = true
                                                            }
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                                withAnimation { showDashboardToast = false }
                                                            }
                                                        }
                                                    }
                                                } label: {
                                                    Text("Decline")
                                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                                        .foregroundColor(.white)
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.vertical, 10)
                                                        .background(Color.white.opacity(0.1))
                                                        .cornerRadius(12)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        } else {
                                            // Show pending status message
                                            HStack(spacing: 8) {
                                                Spacer()
                                                ProgressView()
                                                    .tint(.activeCyan)
                                                    .scaleEffect(0.8)
                                                Text("Waiting for partner to accept...")
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white.opacity(0.6))
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .background(Color.white.opacity(0.04))
                                            .cornerRadius(10)
                                        }
                                    } else if schedule.status == "accepted" {
                                        // Set alarm button
                                        Button {
                                            AlarmManager.shared.requestAccessAndAddEvent(
                                                title: schedule.title,
                                                date: schedule.scheduledDate,
                                                reminderMinutes: schedule.reminder_minutes,
                                                note: "Scheduled with Glimpse"
                                            ) { success, msg in
                                                DispatchQueue.main.async {
                                                    isDashboardToastSuccess = success
                                                    dashboardToastMessage = msg
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                        showDashboardToast = true
                                                    }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                        withAnimation { showDashboardToast = false }
                                                    }
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "alarm.fill")
                                                    .font(.system(size: 12))
                                                Text("Set iPhone Alarm & Calendar alert")
                                            }
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.12))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(20)
                                .background(
                                    LinearGradient(colors: [Color.activeCyan.opacity(0.15), Color.electricPurple.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.activeCyan.opacity(0.35), lineWidth: 1.2)
                                )
                                .shadow(color: Color.activeCyan.opacity(0.1), radius: 8, y: 3)
                                .scaleEffect(scheduleCardBounce ? 0.96 : 1.0)
                                .onTapGesture {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                        scheduleCardBounce = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                            scheduleCardBounce = false
                                        }
                                        selectedDetailSchedule = schedule
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Pending Partner Date Invitation Card (Interactive & Haptic!)
                            if let pendingInvitation = auth.pendingInvitation, pendingInvitation.id != auth.activeSchedule?.id {
                                let isCreator = pendingInvitation.creator_id == (auth.currentUser?.id ?? 0)
                                let alarmTime = pendingInvitation.scheduledDate.addingTimeInterval(TimeInterval(-pendingInvitation.reminder_minutes * 60))
                                
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "envelope.badge.fill")
                                                    .foregroundColor(.pink)
                                                    .font(.system(size: 14))
                                                Text("New Date Invitation")
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundColor(.pink)
                                            }
                                            
                                            Text(pendingInvitation.title)
                                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.top, 2)
                                            
                                            Text(pendingInvitation.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        
                                        Spacer()
                                        
                                        // Calendar Badge
                                        VStack(spacing: 2) {
                                            Text(pendingInvitation.scheduledDate.formatted(.dateTime.day()))
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            Text(pendingInvitation.scheduledDate.formatted(.dateTime.month(.abbreviated)))
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                    
                                    // Reminder info
                                    HStack(spacing: 6) {
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 11))
                                        Text("Alarm set for: \(pendingInvitation.reminder_minutes)m before (\(alarmTime.formatted(date: .omitted, time: .shortened)))")
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                    }
                                    .foregroundColor(.white.opacity(0.6))
                                    
                                    // Accept / Decline controls if not creator
                                    if !isCreator {
                                        HStack(spacing: 12) {
                                            Button {
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.impactOccurred()
                                                Task {
                                                    do {
                                                        try await auth.respondToSchedule(id: pendingInvitation.id, accept: true)
                                                        isDashboardToastSuccess = true
                                                        dashboardToastMessage = "Accepted the date! Set your alarm now."
                                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                            showDashboardToast = true
                                                        }
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                            withAnimation { showDashboardToast = false }
                                                        }
                                                    } catch {
                                                        isDashboardToastSuccess = false
                                                        dashboardToastMessage = error.localizedDescription
                                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                            showDashboardToast = true
                                                        }
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                            withAnimation { showDashboardToast = false }
                                                        }
                                                    }
                                                }
                                            } label: {
                                                Text("Accept Date")
                                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                                    .foregroundColor(.deepVelvet)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 10)
                                                    .background(Color.pink)
                                                    .cornerRadius(12)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Button {
                                                let generator = UIImpactFeedbackGenerator(style: .light)
                                                generator.impactOccurred()
                                                Task {
                                                    do {
                                                        try await auth.respondToSchedule(id: pendingInvitation.id, accept: false)
                                                        isDashboardToastSuccess = true
                                                        dashboardToastMessage = "Date invitation declined."
                                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                            showDashboardToast = true
                                                        }
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                            withAnimation { showDashboardToast = false }
                                                        }
                                                    } catch {
                                                        isDashboardToastSuccess = false
                                                        dashboardToastMessage = error.localizedDescription
                                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                            showDashboardToast = true
                                                        }
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                            withAnimation { showDashboardToast = false }
                                                        }
                                                    }
                                                }
                                            } label: {
                                                Text("Decline")
                                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 10)
                                                    .background(Color.white.opacity(0.1))
                                                    .cornerRadius(12)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    } else {
                                        HStack(spacing: 8) {
                                            Spacer()
                                            ProgressView()
                                                .tint(.pink)
                                                .scaleEffect(0.8)
                                            Text("Waiting for partner to accept...")
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundColor(.white.opacity(0.6))
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(10)
                                    }
                                }
                                .padding(20)
                                .background(
                                    LinearGradient(colors: [Color.pink.opacity(0.15), Color.electricPurple.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.pink.opacity(0.35), lineWidth: 1.2)
                                )
                                .shadow(color: Color.pink.opacity(0.1), radius: 8, y: 3)
                                .onTapGesture {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    selectedDetailSchedule = pendingInvitation
                                }
                                .padding(.top, 8)
                            }
                            
                            // Standalone Anniversary / Days of Love Card (Interactive & Haptic!)
                            if let anniversary = auth.anniversaryDate {
                                VStack(spacing: 8) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.activeCyan)
                                            .font(.system(size: 22))
                                            .shadow(color: .activeCyan.opacity(0.4), radius: 5)
                                        
                                        Text(relationshipDurationText(from: anniversary))
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(.activeCyan)
                                    }
                                    
                                    Text("Days of Love")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .liquidGlass()
                                .scaleEffect(anniversaryCardBounce ? 0.96 : 1.0)
                                .onTapGesture {
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                        anniversaryCardBounce = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                            anniversaryCardBounce = false
                                        }
                                    }
                                }
                                .padding(.top, 5)
                            }
                            
                            // Flash History Accordion List (No outer double container!)
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Image(systemName: "photo.stack.fill")
                                        .foregroundColor(.activeCyan)
                                        .font(.system(size: 15))
                                        .shadow(color: .activeCyan.opacity(0.5), radius: 6)
                                    Text("Flash History")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("(Last 7 Days)")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.4))
                                    Spacer()
                                    Text("\(auth.flashes.count) captures")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                
                                if auth.flashes.isEmpty {
                                    Text("No past Flash records found. Take a Flash photo to build your memory board!")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.4))
                                        .multilineTextAlignment(.center)
                                        .padding(.vertical, 20)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    let visibleFlashes = Array(auth.flashes.prefix(visibleFlashLimit))
                                    
                                    VStack(spacing: 12) {
                                        ForEach(visibleFlashes) { flash in
                                            flashRow(for: flash)
                                        }
                                    }
                                    
                                    // "See More" / "See Less" Buttons (Incrementing/Decrementing by 3)
                                    if auth.flashes.count > 3 {
                                        HStack(spacing: 12) {
                                            if visibleFlashLimit > 3 {
                                                Button {
                                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                                    generator.impactOccurred()
                                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                                        visibleFlashLimit = max(visibleFlashLimit - 3, 3)
                                                    }
                                                } label: {
                                                    HStack {
                                                        Image(systemName: "chevron.up.circle.fill")
                                                            .font(.system(size: 14))
                                                        Text("See Less")
                                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                                    }
                                                    .foregroundColor(.white.opacity(0.6))
                                                    .padding(.vertical, 12)
                                                    .frame(maxWidth: .infinity)
                                                    .background(Color.white.opacity(0.02))
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                                    )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                            
                                            if visibleFlashLimit < auth.flashes.count {
                                                Button {
                                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                                    generator.impactOccurred()
                                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                                        visibleFlashLimit = min(visibleFlashLimit + 3, auth.flashes.count)
                                                    }
                                                } label: {
                                                    HStack {
                                                        Text("See More")
                                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                                        Image(systemName: "chevron.down.circle.fill")
                                                            .font(.system(size: 14))
                                                    }
                                                    .foregroundColor(.activeCyan)
                                                    .padding(.vertical, 12)
                                                    .frame(maxWidth: .infinity)
                                                    .background(Color.white.opacity(0.04))
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.activeCyan.opacity(0.2), lineWidth: 1)
                                                    )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.top, 8)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .liquidGlass()
                            .padding(.top, 10)
                        } else {
                            // PENDING CONNECTION STATES
                            if auth.invitedBy == auth.currentUser?.id {
                                // Sent Request Pending
                                VStack(spacing: 20) {
                                    Image(systemName: "hourglass.badge.plus")
                                        .font(.system(size: 60))
                                        .foregroundColor(.orange.opacity(0.8))
                                    
                                    Text("Invite Sent!")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("Waiting for \(partner.name) to accept your connection request.")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                    
                                    Button {
                                        Task {
                                            do {
                                                try await auth.declineConnectRequest()
                                            } catch {
                                                await MainActor.run {
                                                    dashboardToastMessage = error.localizedDescription
                                                    isDashboardToastSuccess = false
                                                    withAnimation { showDashboardToast = true }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                        withAnimation { showDashboardToast = false }
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        Text("Cancel Request")
                                            .font(.headline)
                                            .padding(.horizontal, 30)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.1))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                    .padding(.top, 10)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 45)
                                .glassmorphic()
                                .padding(.top, 40)
                            } else {
                                // Received Request Pending
                                VStack(spacing: 20) {
                                    Image(systemName: "heart.badge.plus.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.red.opacity(0.8))
                                    
                                    Text("Connection Request")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("\(partner.name) wants to connect with you on Glimpse!")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 12) {
                                        Button {
                                            Task { try? await auth.acceptConnectRequest() }
                                        } label: {
                                            Text("Accept Connection")
                                                .font(.headline)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(Color.electricPurple)
                                                .foregroundColor(.white)
                                                .cornerRadius(12)
                                        }
                                        
                                        Button {
                                            Task { try? await auth.declineConnectRequest() }
                                        } label: {
                                            Text("Decline")
                                                .font(.headline)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(Color.white.opacity(0.15))
                                                .foregroundColor(.white.opacity(0.8))
                                                .cornerRadius(12)
                                        }
                                    }
                                    .padding(.horizontal, 30)
                                    .padding(.top, 10)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .glassmorphic()
                                .padding(.top, 40)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 56, weight: .light))
                                .foregroundColor(.white.opacity(0.35))
                                .shadow(color: .electricPurple.opacity(0.15), radius: 8)
                            
                            VStack(spacing: 8) {
                                Text("No Partner Connected")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Go to your Profile and enter your partner's invite code to start sharing your Glimpse!")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                            
                            Button {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                    auth.selectedTab = 4
                                }
                            } label: {
                                Text("Connect Partner")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.deepVelvet)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.electricPurple)
                                    .cornerRadius(20)
                                    .shadow(color: .electricPurple.opacity(0.35), radius: 8)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 80)
                        .frame(maxWidth: .infinity)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                } // Close ZStack
            }
            .coordinateSpace(name: "dashboard_scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                self.dashboardScrollOffset = value
            }
            .refreshable {
                try? await auth.fetchState()
                _ = try? await auth.fetchFlashes()
                await MainActor.run {
                    auth.dashboardRefreshTrigger.toggle()
                }
            }
            .onChange(of: auth.selectedTab) { oldValue, newValue in
                if newValue == 0 { // Home tab
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        proxy.scrollTo("SCROLL_TOP_ANCHOR", anchor: .top)
                    }
                }
            }
            } // Close ScrollViewReader
            
            // Floating Upload Progress Banner!
            if auth.isUploadingFlash || auth.uploadFailed {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Progress arc icon
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 3)
                                .frame(width: 38, height: 38)
                            
                            Circle()
                                .trim(from: 0.0, to: auth.uploadFailed ? 1.0 : CGFloat(auth.uploadProgress))
                                .stroke(
                                    LinearGradient(
                                        colors: auth.uploadFailed ? [.red, .orange] : (auth.uploadSuccess ? [.vividMint, .green] : [.electricPurple, .activeCyan]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 38, height: 38)
                                .rotationEffect(Angle(degrees: -90))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: auth.uploadProgress)
                            
                            Image(systemName: auth.uploadFailed ? "exclamationmark" : (auth.uploadSuccess ? "checkmark" : "arrow.up.circle.fill"))
                                .font(.system(size: auth.uploadFailed ? 16 : (auth.uploadSuccess ? 15 : 18), weight: .bold))
                                .foregroundColor(auth.uploadFailed ? .red : (auth.uploadSuccess ? .vividMint : .activeCyan))
                        }
                        
                        // Queue badge pill (only when more than 1 in queue)
                        if auth.uploadQueueTotal > 1 && !auth.uploadFailed && !auth.uploadSuccess {
                            Text("\(auth.uploadQueueCurrent)/\(auth.uploadQueueTotal)")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.deepVelvet)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.activeCyan)
                                .clipShape(Capsule())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(auth.uploadFailed ? "Upload Failed" : (auth.uploadSuccess ? "Flash Shared!" : (auth.uploadQueueTotal > 1 ? "Uploading Flash \(auth.uploadQueueCurrent) of \(auth.uploadQueueTotal)" : "Uploading Flash...")))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(auth.uploadFailed ? .red : (auth.uploadSuccess ? .vividMint : .white))
                            
                            Text(auth.uploadFailed ? "Saved to Outbox — will retry" : (auth.uploadSuccess ? "Sent to your partner" : "\(Int(auth.uploadProgress * 100))% complete • Outbox safe"))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        // Cancel button (only during active upload, not during failed state or success state)
                        if auth.isUploadingFlash && !auth.uploadFailed && !auth.uploadSuccess {
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    auth.cancelFlashUpload()
                                }
                            } label: {
                                Text("Cancel")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Retry button (only on failed state)
                        if auth.uploadFailed {
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    auth.uploadFailed = false
                                    auth.processPendingFlashes()
                                }
                            } label: {
                                Text("Retry")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.12))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: auth.uploadFailed
                                        ? [.red.opacity(0.4), .clear]
                                        : [.white.opacity(0.15), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: auth.uploadFailed ? Color.red.opacity(0.25) : Color.black.opacity(0.4), radius: 10, y: 5)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(100)
            }
        }
    }
    
    private func triggerLoveBurst() {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success) // 📳 Premium Success Haptic Explosion!
        
        // System pop sound effect
        AudioServicesPlaySystemSound(1306)
        
        var newHearts: [PopHeart] = []
        
        // 5 elegant lightweight floating hearts
        for _ in 0..<5 {
            let heartId = UUID()
            
            // Randomly scatter horizontal start positions across the screen
            let startX = CGFloat.random(in: -120...120)
            let endX = startX + CGFloat.random(in: -40...40)
            
            // Initial Y starting just below the bottom of the screen
            let startY: CGFloat = 80
            // Target Y floating all the way to the top of the screen
            let screenHeight = UIScreen.main.bounds.height
            let endY = -screenHeight - 100
            
            let duration = Double.random(in: 1.8...2.5)
            
            let particle = PopHeart(
                id: heartId,
                startX: startX,
                endX: endX,
                startY: startY,
                endY: endY,
                startScale: CGFloat.random(in: 0.6...1.1),
                targetScale: CGFloat.random(in: 0.6...1.1) * 1.2,
                color: .red,
                startRotation: Double.random(in: -20...20),
                targetRotation: Double.random(in: -20...20) + Double.random(in: -40...40),
                systemName: "heart.fill",
                emojiString: nil,
                duration: duration
            )
            
            newHearts.append(particle)
            
            // Clean up when animation ends
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                self.popHearts.removeAll(where: { $0.id == heartId })
            }
        }
        
        self.popHearts.append(contentsOf: newHearts)
    }
    
    private func triggerEmojiBurst(_ emoji: String) {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success) // 📳 Premium Success Haptic Explosion!
        
        // System pop sound effect
        AudioServicesPlaySystemSound(1306)
        
        var newEmojis: [PopHeart] = []
        
        // 8 elegant floating emojis
        for _ in 0..<8 {
            let heartId = UUID()
            
            // Randomly scatter horizontal start positions across the screen
            let startX = CGFloat.random(in: -140...140)
            let endX = startX + CGFloat.random(in: -50...50)
            
            // Initial Y starting just below the bottom of the screen
            let startY: CGFloat = 80
            // Target Y floating all the way to the top of the screen
            let screenHeight = UIScreen.main.bounds.height
            let endY = -screenHeight - 100
            
            let duration = Double.random(in: 2.2...3.0)
            
            let particle = PopHeart(
                id: heartId,
                startX: startX,
                endX: endX,
                startY: startY,
                endY: endY,
                startScale: CGFloat.random(in: 0.6...1.2),
                targetScale: CGFloat.random(in: 0.6...1.2) * 1.3,
                color: .clear,
                startRotation: Double.random(in: -30...30),
                targetRotation: Double.random(in: -30...30) + Double.random(in: -60...60),
                systemName: nil,
                emojiString: emoji,
                duration: duration
            )
            
            newEmojis.append(particle)
            
            // Clean up when animation ends
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                self.popHearts.removeAll(where: { $0.id == heartId })
            }
        }
        
        self.popHearts.append(contentsOf: newEmojis)
    }
    
    private func triggerEdgeReactionAnimation(_ emoji: String) {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
        
        // Soft pop sound effect
        AudioServicesPlaySystemSound(1306)
        
        // Spawn 6 particles along the edges (3 left, 3 right)
        for i in 0..<6 {
            let isLeft = i % 2 == 0
            let particleId = UUID()
            
            // Random horizontal positioning near the borders
            let baseX: CGFloat = isLeft ? -140 : 140
            let randomXOffset = CGFloat.random(in: -15...15)
            
            let initialY: CGFloat = 160 // Bottom of card
            let targetY: CGFloat = -180  // Floats above top of card
            
            let delay = Double(i) * 0.08 // Elegant staggered cascade
            
            let particle = EdgeReaction(
                id: particleId,
                emoji: emoji,
                x: baseX + randomXOffset,
                y: initialY,
                scale: CGFloat.random(in: 0.6...1.1),
                opacity: 0.0,
                rotation: Double.random(in: -30...30)
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.edgeReactions.append(particle)
                
                // Animate rising up and fading out along the edges
                withAnimation(.spring(response: 1.2, dampingFraction: 0.85, blendDuration: 0)) {
                    if let idx = self.edgeReactions.firstIndex(where: { $0.id == particleId }) {
                        self.edgeReactions[idx].y = targetY
                        self.edgeReactions[idx].opacity = 1.0
                        self.edgeReactions[idx].scale *= 1.2
                        self.edgeReactions[idx].rotation += Double.random(in: -45...45)
                    }
                }
                
                // Fade out at the top
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        if let idx = self.edgeReactions.firstIndex(where: { $0.id == particleId }) {
                            self.edgeReactions[idx].opacity = 0.0
                            self.edgeReactions[idx].scale *= 0.8
                        }
                    }
                }
                
                // Cleanup
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.edgeReactions.removeAll(where: { $0.id == particleId })
                }
            }
        }
    }
    
    private func timeRemainingString(from now: Date, to target: Date) -> String {
        let diff = target.timeIntervalSince(now)
        guard diff > 0 else { return "" }
        
        let totalSeconds = Int(diff)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        var parts: [String] = []
        if days > 0 { parts.append("\(days)d") }
        if hours > 0 || days > 0 { parts.append("\(hours)hr") }
        if minutes > 0 || hours > 0 || days > 0 { parts.append("\(minutes)min") }
        parts.append("\(seconds)sec")
        
        return parts.joined(separator: " ")
    }
    
    private func formatFlashTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func relationshipDurationText(from date: Date) -> String {
        let now = currentTime
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date, to: now)
        
        let years = components.year ?? 0
        let months = components.month ?? 0
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        let seconds = components.second ?? 0
        
        return "\(years)y \(months)m \(days)d \(hours)h \(minutes)m \(seconds)s"
    }
}

struct PopHeart: Identifiable {
    let id: UUID
    let startX: CGFloat
    let endX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let startScale: CGFloat
    let targetScale: CGFloat
    let color: Color
    let startRotation: Double
    let targetRotation: Double
    let systemName: String?
    let emojiString: String?
    let duration: Double
}

struct PopHeartView: View {
    let heart: PopHeart
    @State private var animate = false
    
    var body: some View {
        Group {
            if let emoji = heart.emojiString {
                Text(emoji)
                    .font(.system(size: 32))
            } else if let sysName = heart.systemName {
                Image(systemName: sysName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(heart.color)
            }
        }
        .scaleEffect(animate ? heart.targetScale : heart.startScale)
        .rotationEffect(.degrees(animate ? heart.targetRotation : heart.startRotation))
        .opacity(animate ? 0.0 : 1.0)
        .offset(
            x: animate ? heart.endX : heart.startX,
            y: animate ? heart.endY : heart.startY
        )
        .onAppear {
            withAnimation(.easeOut(duration: heart.duration)) {
                animate = true
            }
        }
    }
}


struct FlashLocationRow: View {
    let flash: GlimpseFlash
    @State private var resolvedAddress: String? = nil
    
    var body: some View {
        Group {
            if let address = flash.location_name ?? resolvedAddress {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.activeCyan)
                        .font(.system(size: 13))
                        .shadow(color: .activeCyan.opacity(0.5), radius: 4)
                    Text(address)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .task {
            if flash.location_name == nil {
                if let lat = flash.latitude, lat != 0.0,
                   let lon = flash.longitude, lon != 0.0 {
                    let location = CLLocation(latitude: lat, longitude: lon)
                    let geocoder = CLGeocoder()
                    if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
                       let placemark = placemarks.first {
                        let street = placemark.thoroughfare ?? ""
                        let kelurahan = placemark.subLocality ?? ""
                        let kecamatan = placemark.subAdministrativeArea ?? ""
                        
                        var addressParts: [String] = []
                        if !street.isEmpty { addressParts.append(street) }
                        if !kelurahan.isEmpty { addressParts.append(kelurahan) }
                        if !kecamatan.isEmpty { addressParts.append(kecamatan) }
                        
                        let formattedAddress = addressParts.isEmpty ? (placemark.locality ?? "Tidak Diketahui") : addressParts.joined(separator: ", ")
                        
                        await MainActor.run {
                            withAnimation(.easeOut(duration: 0.3)) {
                                self.resolvedAddress = formattedAddress
                            }
                        }
                    }
                }
            }
        }
    }
}

struct EdgeReaction: Identifiable {
    let id: UUID
    let emoji: String
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var rotation: Double
}

#Preview {
    MainDashboardView()
}

struct ScheduleDetailSheetView: View {
    let schedule: GlimpseSchedule
    let auth: AuthManager
    @Binding var isPresented: Bool
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    @Binding var toastSuccess: Bool
    
    var body: some View {
        let isCreator = schedule.creator_id == (auth.currentUser?.id ?? 0)
        let alarmTime = schedule.scheduledDate.addingTimeInterval(TimeInterval(-schedule.reminder_minutes * 60))
        
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 22) {
                // Drag indicator spacer
                HStack {
                    Spacer()
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 5)
                    Spacer()
                }
                .padding(.top, 12)
                
                // Header Title
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.activeCyan)
                        .font(.system(size: 16, weight: .bold))
                    Text(schedule.status == "pending" ? "Date Invitation" : "Upcoming Date")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.activeCyan)
                    
                    Spacer()
                    
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Event Details Block
                VStack(alignment: .leading, spacing: 8) {
                    Text(schedule.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.activeCyan)
                        Text(schedule.scheduledDate.formatted(date: .long, time: .shortened))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.12))
                
                // Alarm Metadata Block
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        Text("ALARM SET FOR")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Text("\(schedule.reminder_minutes) minutes before (\(alarmTime.formatted(date: .omitted, time: .shortened)))")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Status Block
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        Text("RSVP STATUS")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: schedule.status == "accepted" ? "checkmark.circle.fill" : "hourglass")
                            .font(.system(size: 14))
                            .foregroundColor(schedule.status == "accepted" ? .activeCyan : .orange)
                        Text(schedule.status == "accepted" ? "Accepted by both partners" : "Waiting for partner response")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(schedule.status == "accepted" ? .activeCyan : .orange)
                    }
                }
                
                Spacer()
                
                // Interactive RSVP Actions inside the Detail Popup
                if schedule.status == "pending" {
                    if !isCreator {
                        HStack(spacing: 16) {
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                isPresented = false
                                Task {
                                    do {
                                        try await auth.respondToSchedule(id: schedule.id, accept: true)
                                        toastSuccess = true
                                        toastMessage = "Accepted the date! Set your alarm now."
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                            showToast = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                            withAnimation { showToast = false }
                                        }
                                    } catch {
                                        toastSuccess = false
                                        toastMessage = error.localizedDescription
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                            showToast = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                            withAnimation { showToast = false }
                                        }
                                    }
                                }
                            } label: {
                                Text("Accept Date")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.deepVelvet)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.activeCyan)
                                    .cornerRadius(14)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                isPresented = false
                                Task {
                                    do {
                                        try await auth.respondToSchedule(id: schedule.id, accept: false)
                                        toastSuccess = true
                                        toastMessage = "Date invitation declined."
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                            showToast = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                            withAnimation { showToast = false }
                                        }
                                    } catch {
                                        toastSuccess = false
                                        toastMessage = error.localizedDescription
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                            showToast = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                            withAnimation { showToast = false }
                                        }
                                    }
                                }
                            } label: {
                                Text("Decline")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(14)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(.activeCyan)
                                .scaleEffect(0.8)
                            Text("Waiting for partner to accept...")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(14)
                    }
                } else if schedule.status == "accepted" {
                    // Set alarm button
                    Button {
                        isPresented = false
                        AlarmManager.shared.requestAccessAndAddEvent(
                            title: schedule.title,
                            date: schedule.scheduledDate,
                            reminderMinutes: schedule.reminder_minutes,
                            note: "Scheduled with Glimpse"
                        ) { success, msg in
                            DispatchQueue.main.async {
                                toastSuccess = success
                                toastMessage = msg
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showToast = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    withAnimation { showToast = false }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "alarm.fill")
                                .font(.system(size: 14))
                            Text("Set iPhone Alarm & Calendar Alert")
                        }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .presentationDetents([.fraction(0.55)])
    }
}

extension MainDashboardView {
    private var isInsideActiveChatRoomOfPlayingMessage: Bool {
        guard auth.selectedTab == 3, let activeRoom = auth.selectedChatRoom else { return false }
        if let playingMsg = audioPlayerManager.playingMessage {
            if activeRoom.id == playingMsg.room_id {
                return true
            }
            if activeRoom.is_main && (playingMsg.room_id == nil || playingMsg.room_id == 0) {
                return true
            }
        }
        return false
    }
    
    private func activeRoomThemeColorForMsg(_ msg: ChatMessage) -> Color {
        if let roomId = msg.room_id, roomId > 0 {
            if let room = auth.chatRooms.first(where: { $0.id == roomId }),
               let hex = room.theme_color, !hex.isEmpty {
                return Color(hex: hex)
            }
        } else {
            if let mainRoom = auth.chatRooms.first(where: { $0.is_main }),
               let hex = mainRoom.theme_color, !hex.isEmpty {
                return Color(hex: hex)
            }
        }
        return Color.activeCyan
    }
    
    private func navigateToMessageRoom(_ msg: ChatMessage) {
        auth.selectedTab = 3
        
        if let roomId = msg.room_id, roomId > 0 {
            if let room = auth.chatRooms.first(where: { $0.id == roomId }) {
                auth.selectedChatRoom = room
            }
        } else {
            if let mainRoom = auth.chatRooms.first(where: { $0.is_main }) {
                auth.selectedChatRoom = mainRoom
            }
        }
        
        audioPlayerManager.navigateToMessageIdTrigger = msg.id
    }
    
    private func flashMapView(flash: GlimpseFlash) -> some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: flash.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        ))) {
            Annotation(flash.sender_name, coordinate: flash.coordinate) {
                ZStack {
                    Circle()
                        .fill(Color.activeCyan.opacity(0.3))
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .stroke(Color.activeCyan, lineWidth: 2)
                        .frame(width: 18, height: 18)
                        .shadow(color: Color.activeCyan, radius: 4)
                }
            }
        }
    }
    
    @ViewBuilder
    private func flashRow(for flash: GlimpseFlash) -> some View {
        let isExpanded = expandedFlashId == flash.id
        let isMe = flash.sender_id == auth.currentUser?.id
        
        VStack(spacing: 0) {
            // HEADER ROW
            Button {
                UISelectionFeedbackGenerator().selectionChanged()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    if isExpanded {
                        expandedFlashId = nil
                    } else {
                        expandedFlashId = flash.id
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.activeCyan)
                                .frame(width: 6, height: 6)
                                .shadow(color: Color.activeCyan, radius: 4)
                            
                            Text(isMe ? "You" : flash.sender_name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(formatFlashTime(flash.createdDate))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.03))
            }
            .buttonStyle(PlainButtonStyle())
            
            // CONTENT BODY (EXPANDABLE)
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        // Left side: Photo (1:1 Ratio - Sebelahan)
                        CachedImageView(urlString: flash.photo_url)
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .aspectRatio(1.0, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        // Right side: Map View (1:1 Ratio - Sebelahan)
                        if let lat = flash.latitude, lat != 0.0,
                           let lon = flash.longitude, lon != 0.0 {
                            flashMapView(flash: flash)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(1.0, contentMode: .fit)
                                .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    .frame(height: 155)
                    
                    // Location Detail Row (with background fallback resolver)
                    FlashLocationRow(flash: flash)
                    
                    // Kabar / Status Note Row
                    if let note = flash.status_note, !note.isEmpty {
                        Text("\"\(note)\"")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .italic()
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(8)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.01))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
