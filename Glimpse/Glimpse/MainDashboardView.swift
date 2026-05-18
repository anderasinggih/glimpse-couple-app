import SwiftUI
import Combine
import AudioToolbox
import MapKit

struct MainDashboardView: View {
    @State private var auth = AuthManager.shared
    @State private var togetherAnimation = false
    @State private var streakPulse = false
    @State private var lastSeenLoveBurstTimestamp: Double = 0.0
    @State private var popHearts: [PopHeart] = []
    @State private var expandedFlashId: Int? = nil
    @State private var visibleFlashLimit: Int = 4
    @State private var streakCardBounce = false
    @State private var anniversaryCardBounce = false
    @State private var scheduleCardBounce = false
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
            Color.deepVelvet.ignoresSafeArea()
            
            // Standard Native TabView
            TabView(selection: $bindableAuth.selectedTab) {
                // Tab 0: Dashboard
                dashboardView
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)
                
                // Tab 1: Map
                Group {
                    if let partner = auth.partner, auth.coupleActive {
                        FullPartnerMapView(user: partner)
                    } else {
                        VStack(spacing: 15) {
                            Image(systemName: "map")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Map is currently empty")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.deepVelvet)
                    }
                }
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(1)
                
                // Tab 2: Flash
                FlashCameraView()
                    .tabItem {
                        Label("Flash", systemImage: "camera")
                    }
                    .tag(2)
                
                // Tab 3: Chat
                ChatView()
                    .tabItem {
                        Label("Chat", systemImage: "bubble.left.and.bubble.right")
                    }
                    .badge(auth.unreadMessagesCount > 0 ? Text("\(auth.unreadMessagesCount)") : nil)
                    .tag(3)
                
                // Tab 4: Profile
                ProfileView(scrollOffset: $profileScrollOffset)
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .tag(4)
            }
            .tint(.electricPurple)
            .simultaneousGesture(
                DragGesture().onEnded { value in
                    // Disable swipe-to-switch on Map tab (Tab 1) so user can pan the map freely
                    guard auth.selectedTab != 1 else { return }
                    
                    // SWIPE LOGIC
                    let threshold: CGFloat = 100
                    if value.translation.width > threshold {
                        // Swipe Right -> Previous Tab
                        if auth.selectedTab > 0 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                auth.selectedTab -= 1
                            }
                        }
                    } else if value.translation.width < -threshold {
                        // Swipe Left -> Next Tab
                        if auth.selectedTab < 4 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                auth.selectedTab += 1
                            }
                        }
                    }
                }
            )
            
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
            if auth.selectedTab != 3 {
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

            
            // GLOBAL POP HEARTS OVERLAY (IN CENTER OF SCREEN)
            ZStack {
                ForEach(popHearts) { heart in
                    ZStack {
                        if let emoji = heart.emojiString {
                            Text(emoji)
                                .font(.system(size: 55))
                                .scaleEffect(heart.scale)
                                .shadow(color: .black.opacity(0.3), radius: 6)
                        } else if let sysName = heart.systemName {
                            Image(systemName: sysName)
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(heart.color.opacity(0.2))
                                .scaleEffect(heart.scale + 0.2)
                                .blur(radius: 6)
                            
                            Image(systemName: sysName)
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(heart.color)
                                .shadow(color: heart.color.opacity(0.8), radius: 10)
                                .scaleEffect(heart.scale)
                        }
                    }
                    .rotationEffect(.degrees(heart.rotation))
                    .opacity(heart.opacity)
                    .offset(x: heart.x, y: heart.y)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
            
            // Premium Detail Popup Modal for Active Schedule
            if showScheduleDetailPopup, let schedule = auth.activeSchedule {
                let isCreator = schedule.creator_id == (auth.currentUser?.id ?? 0)
                let alarmTime = schedule.scheduledDate.addingTimeInterval(TimeInterval(-schedule.reminder_minutes * 60))
                
                ZStack {
                    // Blurred Backdrop (tapping it dismisses the popup)
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showScheduleDetailPopup = false
                            }
                        }
                    
                    // Card Dialog Container
                    VStack(alignment: .leading, spacing: 18) {
                        // Close / Action Row
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.activeCyan)
                                    .font(.system(size: 15))
                                Text(schedule.status == "pending" ? "Date Invitation" : "Upcoming Date")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.activeCyan)
                            }
                            
                            Spacer()
                            
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showScheduleDetailPopup = false
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Event Details Block
                        VStack(alignment: .leading, spacing: 6) {
                            Text(schedule.title)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.activeCyan)
                                Text(schedule.scheduledDate.formatted(date: .long, time: .shortened))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                            .background(Color.white.opacity(0.12))
                        
                        // Alarm Metadata Block
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("Alarm Set For")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            
                            Text("\(schedule.reminder_minutes) minutes before (\(alarmTime.formatted(date: .omitted, time: .shortened)))")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Status Block
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("RSVP Status")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: schedule.status == "accepted" ? "checkmark.circle.fill" : "hourglass")
                                    .font(.system(size: 12))
                                    .foregroundColor(schedule.status == "accepted" ? .activeCyan : .orange)
                                Text(schedule.status == "accepted" ? "Accepted by both partners" : "Waiting for partner response")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(schedule.status == "accepted" ? .activeCyan : .orange)
                            }
                        }
                        
                        // Interactive RSVP Actions inside the Detail Popup
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
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    showScheduleDetailPopup = false
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
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(.deepVelvet)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
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
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    showScheduleDetailPopup = false
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
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.12))
                                            .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.top, 6)
                            } else {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(.activeCyan)
                                        .scaleEffect(0.8)
                                    Text("Waiting for partner to accept...")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(12)
                                .padding(.top, 6)
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
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            showScheduleDetailPopup = false
                                            showDashboardToast = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                            withAnimation { showDashboardToast = false }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "alarm.fill")
                                        .font(.system(size: 14))
                                    Text("Set iPhone Alarm & Calendar Alert")
                                }
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 6)
                        }
                    }
                    .padding(24)
                    .background(
                        LinearGradient(colors: [Color.deepVelvet, Color.black.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.activeCyan.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.6), radius: 25, y: 15)
                    .padding(.horizontal, 32)
                }
                .transition(.scale(scale: 0.95).combined(with: .opacity))
                .zIndex(99999)
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
            
            // Backup fallback state sync every 30 seconds (WebSocket handles instant updates!)
            if pollCounter % 30 == 0 {
                Task {
                    try? await auth.fetchState()
                }
            }
        }
        // React instantly to real-time Love Burst triggers via WebSocket
        .onChange(of: auth.lastLoveBurstTimestamp) { oldValue, newValue in
            if newValue > lastSeenLoveBurstTimestamp {
                lastSeenLoveBurstTimestamp = newValue
                triggerLoveBurst()
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
                            
                            ZStack {
                                PartnerMapView(user: partner)
                                    .aspectRatio(1, contentMode: .fit)
                                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                                    .scaleEffect(reactionCardScale)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                if touchStartTime == nil {
                                                    touchStartTime = Date()
                                                    let startLoc = value.startLocation
                                                    // Trigger fast long-press overlay after 150ms hold
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                        guard let startTime = touchStartTime else { return }
                                                        if !isLongPressActive {
                                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                                reactionCardScale = 0.94
                                                                showReactions = true
                                                                isLongPressActive = true
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                guard isLongPressActive else { return }
                                                
                                                // Map touch position to the 5 emoji slots
                                                let xPos = value.location.x
                                                let cardWidth: CGFloat = 300.0 // standard card width boundary
                                                let segmentWidth = cardWidth / 5.0
                                                var index = Int(xPos / segmentWidth)
                                                if index < 0 { index = 0 }
                                                if index > 4 { index = 4 }
                                                
                                                if reactionHoveredIndex != index {
                                                    reactionHoveredIndex = index
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                }
                                            }
                                            .onEnded { value in
                                                let duration = Date().timeIntervalSince(touchStartTime ?? Date())
                                                touchStartTime = nil
                                                
                                                if !isLongPressActive || duration < 0.15 {
                                                    // Quick tap flips the card!
                                                    NotificationCenter.default.post(name: NSNotification.Name("FlipDashboardCard"), object: nil)
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                                        reactionCardScale = 1.0
                                                        showReactions = false
                                                        isLongPressActive = false
                                                        reactionHoveredIndex = nil
                                                    }
                                                } else {
                                                    // Released after long press! Send hovered emoji
                                                    if let hoveredIdx = reactionHoveredIndex {
                                                        let emojisList = ["❤️", "🔥", "✨", "😘", "💩"]
                                                        let selectedEmoji = emojisList[hoveredIdx]
                                                        
                                                        // Trigger elegant card-edge sparkles instead of fullscreen burst
                                                        triggerEdgeReactionAnimation(selectedEmoji)
                                                        
                                                        // Show Locket-style edge floating badge
                                                        activeReactionBadge = selectedEmoji
                                                        reactionBadgeAngle = Double.random(in: -15...15)
                                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                                            showReactionBadge = true
                                                            reactionBadgeScale = 1.2
                                                        }
                                                        
                                                        // Bounce effect
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                                reactionBadgeScale = 1.0
                                                            }
                                                        }
                                                        
                                                        // Auto-hide the edge reaction badge after 4 seconds
                                                        let currentBadge = selectedEmoji
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                                            if activeReactionBadge == currentBadge {
                                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                                    reactionBadgeScale = 0.0
                                                                    showReactionBadge = false
                                                                }
                                                            }
                                                        }
                                                        
                                                        // Prevent the subsequent WebSocket broadcast from triggering double full-screen sparkles!
                                                        isSuppressingGlobalLoveBurst = true
                                                        
                                                        // Sync love burst to server in background
                                                        Task {
                                                            try? await auth.triggerServerLoveBurst()
                                                        }
                                                    }
                                                    
                                                    // Reset card scale and hide reactions
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                                        reactionCardScale = 1.0
                                                        showReactions = false
                                                        isLongPressActive = false
                                                        reactionHoveredIndex = nil
                                                    }
                                                }
                                            }
                                    )
                                
                                // Rising Edge Reaction Sparkles (Floating gracefully from bottom to top along borders)
                                ForEach(edgeReactions) { particle in
                                    Text(particle.emoji)
                                        .font(.system(size: 34))
                                        .scaleEffect(particle.scale)
                                        .rotationEffect(.degrees(particle.rotation))
                                        .opacity(particle.opacity)
                                        .offset(x: particle.x, y: particle.y)
                                        .shadow(color: .black.opacity(0.2), radius: 4)
                                        .zIndex(205)
                                }
                                
                                // Locket-Style Edge Floating Reaction Badge
                                if let badge = activeReactionBadge, showReactionBadge {
                                    Text(badge)
                                        .font(.system(size: 42))
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.2))
                                        .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
                                        .rotationEffect(.degrees(reactionBadgeAngle))
                                        .scaleEffect(reactionBadgeScale)
                                        .offset(x: 130, y: -130) // Overlap perfectly at the top-right corner!
                                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                                        .zIndex(210)
                                }
                                
                                if showReactions {
                                    // Glassmorphic Capsule Reaction Overlay
                                    HStack(spacing: 20) {
                                        ForEach(Array(["❤️", "🔥", "✨", "😘", "💩"].enumerated()), id: \.offset) { index, emoji in
                                            Text(emoji)
                                                .font(.system(size: 38))
                                                .scaleEffect(reactionHoveredIndex == index ? 1.45 : 1.0)
                                                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: reactionHoveredIndex)
                                                .shadow(color: .black.opacity(0.3), radius: 4)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 15, y: 10)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8, anchor: .center).combined(with: .opacity),
                                        removal: .scale(scale: 0.8, anchor: .center).combined(with: .opacity)
                                    ))
                                    .zIndex(200)
                                }
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
                                        showScheduleDetailPopup = true
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Standalone Anniversary / Days of Love Card (Interactive & Haptic!)
                            if let anniversary = auth.anniversaryDate {
                                VStack(spacing: 8) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "calendar.badge.heart")
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
                                    
                                    // "See More" / "See Less" Button
                                    if auth.flashes.count > 4 {
                                        Button {
                                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                                if visibleFlashLimit < auth.flashes.count {
                                                    visibleFlashLimit += 4
                                                } else {
                                                    visibleFlashLimit = 4
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Text(visibleFlashLimit < auth.flashes.count ? "See More Captures" : "See Less")
                                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                                    .foregroundColor(visibleFlashLimit >= auth.flashes.count ? .white.opacity(0.6) : .activeCyan)
                                                Image(systemName: visibleFlashLimit < auth.flashes.count ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(visibleFlashLimit >= auth.flashes.count ? .white.opacity(0.6) : .activeCyan)
                                            }
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.white.opacity(visibleFlashLimit >= auth.flashes.count ? 0.02 : 0.04))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(visibleFlashLimit >= auth.flashes.count ? Color.white.opacity(0.05) : Color.activeCyan.opacity(0.2), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
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
                                        Task { try? await auth.declineConnectRequest() }
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
            if auth.isUploadingFlash {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Tiny thumbnail or upload icon with progress arc
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 3)
                                .frame(width: 38, height: 38)
                            
                            Circle()
                                .trim(from: 0.0, to: CGFloat(auth.uploadProgress))
                                .stroke(
                                    LinearGradient(
                                        colors: [.electricPurple, .activeCyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 38, height: 38)
                                .rotationEffect(Angle(degrees: -90))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: auth.uploadProgress)
                            
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.activeCyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Uploading Glimpse...")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("\(Int(auth.uploadProgress * 100))% complete • Outbox safe")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.15), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 10, y: 5)
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
        
        let shapes = ["heart.fill", "sparkles", "star.fill", "flame.fill", "bolt.fill"]
        
        for _ in 0..<15 {
            let heartId = UUID()
            let angle = Double.random(in: 0...(2 * Double.pi))
            let radius = CGFloat.random(in: 80...250)
            let shape = shapes.randomElement() ?? "heart.fill"
            let color = [
                Color.activeCyan, 
                Color.electricPurple, 
                Color.pink, 
                Color(hex: "FF4D94"), 
                Color.orange
            ].randomElement()!
            
            let particle = PopHeart(
                id: heartId,
                x: 0,
                y: 0,
                scale: CGFloat.random(in: 0.5...1.2),
                color: color,
                opacity: 1.0,
                rotation: Double.random(in: -45...45),
                systemName: shape,
                emojiString: nil
            )
            
            self.popHearts.append(particle)
            
            // Animate outwards radially!
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
                if let idx = self.popHearts.firstIndex(where: { $0.id == heartId }) {
                    self.popHearts[idx].x = cos(angle) * radius
                    self.popHearts[idx].y = sin(angle) * radius
                    self.popHearts[idx].opacity = 0.0
                    self.popHearts[idx].scale *= 1.4
                    self.popHearts[idx].rotation += Double.random(in: -90...90)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.popHearts.removeAll(where: { $0.id == heartId })
            }
        }
    }
    
    private func triggerEmojiBurst(_ emoji: String) {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success) // 📳 Premium Success Haptic Explosion!
        
        // System pop sound effect
        AudioServicesPlaySystemSound(1306)
        
        for _ in 0..<15 {
            let heartId = UUID()
            let angle = Double.random(in: 0...(2 * Double.pi))
            let radius = CGFloat.random(in: 80...250)
            
            let particle = PopHeart(
                id: heartId,
                x: 0,
                y: 0,
                scale: CGFloat.random(in: 0.5...1.2),
                color: .clear,
                opacity: 1.0,
                rotation: Double.random(in: -45...45),
                systemName: nil,
                emojiString: emoji
            )
            
            self.popHearts.append(particle)
            
            // Animate outwards radially!
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
                if let idx = self.popHearts.firstIndex(where: { $0.id == heartId }) {
                    self.popHearts[idx].x = cos(angle) * radius
                    self.popHearts[idx].y = sin(angle) * radius
                    self.popHearts[idx].opacity = 0.0
                    self.popHearts[idx].scale *= 1.4
                    self.popHearts[idx].rotation += Double.random(in: -90...90)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.popHearts.removeAll(where: { $0.id == heartId })
            }
        }
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
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var color: Color
    var opacity: Double
    var rotation: Double
    var systemName: String?
    var emojiString: String?
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
                        let subLoc = placemark.subLocality ?? placemark.locality ?? ""
                        
                        await MainActor.run {
                            withAnimation(.easeOut(duration: 0.3)) {
                                if !street.isEmpty && !subLoc.isEmpty {
                                    self.resolvedAddress = "\(street), \(subLoc)"
                                } else {
                                    self.resolvedAddress = street.isEmpty ? subLoc : street
                                }
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
