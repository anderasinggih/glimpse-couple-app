import SwiftUI
import Combine
import AudioToolbox

struct ChatView: View {
    @State private var auth = AuthManager.shared
    @State private var messages: [ChatMessage] = []
    @State private var messageInput = ""
    @State private var isSending = false
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 5.0, on: .main, in: .common)
    @State private var cancellable: Cancellable?
    @FocusState private var isInputFocused: Bool
    
    // To track when to push status (every 2 ticks of the 5.0s timer = 10s)
    @State private var tickCount = 0
    @State private var isSearchingChat = false
    @State private var searchQuery = ""
    @State private var isShowingScrollToBottomButton = false
    
    var filteredMessages: [ChatMessage] {
        let cleanQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanQuery.isEmpty {
            return messages
        }
        return messages.filter { $0.message.localizedCaseInsensitiveContains(cleanQuery) }
    }
    
    var body: some View {
        ZStack {
            // LAYER 1: Background
            ZStack {
                Color.deepVelvet.ignoresSafeArea()
                iOS26Background().opacity(0.4)
            }
            .ignoresSafeArea()
            .ignoresSafeArea(.keyboard)
            .onTapGesture {
                isInputFocused = false
            }
            
            // LAYER 2: Main Content
            if let partner = auth.partner, auth.coupleActive {
                ZStack(alignment: .top) {
                    
                    // Messages ScrollView (occupies full height, goes UNDER header)
                    ScrollViewReader { proxy in
                        ZStack(alignment: .bottomTrailing) {
                            ScrollView {
                            VStack(spacing: 12) {
                                // Top space to offset first message below the frosted header (height matches whether search is expanded)
                                Spacer().frame(height: isSearchingChat ? 165 : 110)
                                
                                ForEach(Array(filteredMessages.enumerated()), id: \.element.id) { index, msg in
                                    VStack(spacing: 12) {
                                        if shouldShowDateHeader(for: index) {
                                            dateHeaderBadge(for: msg)
                                        }
                                        chatBubble(msg: msg)
                                            .transition(.asymmetric(
                                                insertion: .scale(scale: 0.8, anchor: msg.sender_id == auth.currentUser?.id ? .bottomTrailing : .bottomLeading)
                                                    .combined(with: .opacity),
                                                removal: .opacity
                                            ))
                                    }
                                }
                                
                                // Beautiful Glassmorphic "No Results" state when query returns nothing
                                if !searchQuery.isEmpty && filteredMessages.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "magnifyingglass.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(.white.opacity(0.25))
                                        Text("No results for \"\(searchQuery)\"")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(.vertical, 40)
                                    .frame(maxWidth: .infinity)
                                    .transition(.opacity.combined(with: .scale))
                                }
                                
                                if auth.isPartnerTyping {
                                    HStack {
                                        TypingIndicatorView()
                                            .transition(.asymmetric(
                                                insertion: .scale(scale: 0.7, anchor: .bottomLeading)
                                                    .combined(with: .opacity),
                                                removal: .opacity
                                            ))
                                        Spacer()
                                    }
                                    .padding(.leading, 4)
                                    .padding(.top, 4)
                                }
                                
                                // Tiny bottom padding to prevent drop shadow clipping of the last bubble
                                Spacer().frame(height: 15)
                                
                                // Bottom Scroll Detection Marker
                                Color.clear
                                    .frame(height: 1)
                                    .background(
                                        GeometryReader { geo in
                                            let frame = geo.frame(in: .global)
                                            Color.clear
                                                .onChange(of: frame.minY) { _, newValue in
                                                    let screenHeight = UIScreen.main.bounds.height
                                                    let isOff = newValue > screenHeight + 120
                                                    if isShowingScrollToBottomButton != isOff {
                                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                                            isShowingScrollToBottomButton = isOff
                                                        }
                                                    }
                                                }
                                        }
                                    )
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 600)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isInputFocused = false
                            }
                        }
                        .safeAreaInset(edge: .bottom) {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 0.8)
                                
                                floatingInputBar
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                    .padding(.bottom, 12)
                            }
                            .background(
                                Color.white.opacity(0.01) // Super transparent base for see-through feel
                                    .background(.ultraThinMaterial) // Clean glassmorphic transparent blur
                                    .ignoresSafeArea(edges: .bottom)
                            )
                        }
                        .onChange(of: messages) { oldMessages, newMessages in
                            if let lastMsg = newMessages.last {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                        proxy.scrollTo(lastMsg.id, anchor: .bottom)
                                    }
                                }
                                
                                // Play soft "ting" sound (1103) and tactile "klek" haptic (.rigid) when partner message is received
                                if !oldMessages.isEmpty && lastMsg.sender_id == auth.partner?.id {
                                    AudioServicesPlaySystemSound(1103) // Soft ting/chime
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                }
                            }
                        }
                        .onChange(of: isInputFocused) { _, isFocused in
                            if isFocused {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    if let lastMsg = messages.last {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                            proxy.scrollTo(lastMsg.id, anchor: .bottom)
                                        }
                                    }
                                }
                            }
                        }
                        .onAppear {
                            if let lastMsg = messages.last {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        proxy.scrollTo(lastMsg.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        
                        // Floating Scroll To Bottom Button
                        if isShowingScrollToBottomButton {
                            Button {
                                if let lastMsg = messages.last {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                        proxy.scrollTo(lastMsg.id, anchor: .bottom)
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color.electricPurple)
                                            .shadow(color: .electricPurple.opacity(0.6), radius: 8, x: 0, y: 4)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 90) // Positions nicely above glass input bar
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                    
                    // Premium Small Header - aligned top overlaying ScrollView!
                    chatHeader(partner: partner)
                        .zIndex(10)
                }
            } else {
                // Not Connected Placeholder
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 65))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("Chat is empty")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Connect with your partner first to start chatting in real-time.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadMessages()
            startPolling()
            auth.pushCurrentStatus() // Immediate status update on load
        }
        .onDisappear {
            stopPolling()
        }
        // Push our current battery/charging status to partner periodically in background
        .onReceive(timer) { _ in
            if auth.partner != nil, auth.coupleActive {
                tickCount += 1
                
                // Every 2 ticks (10s): Push our current battery/charging status to partner
                if tickCount >= 2 {
                    tickCount = 0
                    auth.pushCurrentStatus()
                }
            }
        }
        // Listen to live WebSocket message broadcasts from Partner
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlimpseChatMessageReceived"))) { notification in
            if let newMsg = notification.object as? ChatMessage {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    if !self.messages.contains(where: { $0.id == newMsg.id }) {
                        self.messages.append(newMsg)
                        
                        // Play soft "ting" sound (1103) and tactile "klek" haptic (.rigid) for live incoming messages
                        if let partner = auth.partner, newMsg.sender_id == partner.id {
                            AudioServicesPlaySystemSound(1103)
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        }
                    }
                }
            }
        }
        // Real-time typing notification triggers
        .onChange(of: messageInput) { oldValue, newValue in
            let cleanNew = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanOld = oldValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !cleanNew.isEmpty && cleanOld.isEmpty {
                auth.sendTypingStatus(isTyping: true)
            } else if cleanNew.isEmpty && !cleanOld.isEmpty {
                auth.sendTypingStatus(isTyping: false)
            }
        }
    }
    
    // PREMIUM TINY HEADER WITH INTEGRATED BLUR EFFECT (Bleeds to top edge)
    private func chatHeader(partner: GlimpseUser) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Profile Photo (Small circle)
                AsyncImage(url: URL(string: formattedUrl(partner.profile_photo_url))) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.white.opacity(0.1)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.electricPurple.opacity(0.3), lineWidth: 1.5))
                
                // Partner Details (Tiny & Compact)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(partner.name)
                            .font(.system(size: 16.5, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Online Indicator Dot
                        Circle()
                            .fill(partner.isOffline ? Color.gray : Color.green)
                            .frame(width: 7, height: 7)
                    }
                    
                    // Status, Location, and Battery
                    HStack(spacing: 10) {
                        // 1. Online / Offline Status
                        Text(partner.isOffline ? "Offline" : "Online")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                        
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.3))
                        
                         // 2. Location (Tap to redirect to Map screen)
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 9.5))
                            Text(partner.location_name ?? "Unknown")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundColor(.electricPurple.opacity(0.95))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                auth.selectedTab = 1 // Switch to map tab
                            }
                        }
                        
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.3))
                        
                        // 3. Battery with Charging Support
                        HStack(spacing: 3) {
                            Image(systemName: partner.is_charging == true ? "battery.100.bolt" : "battery.75")
                                .font(.system(size: 11))
                                .foregroundColor(partner.is_charging == true ? .green : (partner.battery_level ?? 100 > 20 ? .white.opacity(0.7) : .red))
                            Text("\(partner.battery_level ?? 100)%")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // PREMIUM FIND CHAT BUTTON (WhatsApp style)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isSearchingChat.toggle()
                        if !isSearchingChat {
                            searchQuery = ""
                        }
                    }
                } label: {
                    Image(systemName: isSearchingChat ? "xmark.circle.fill" : "magnifyingglass")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isSearchingChat ? .electricPurple : .white.opacity(0.8))
                        .padding(8)
                        .background(Color.white.opacity(isSearchingChat ? 0.15 : 0.05))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 50)
            .padding(.bottom, 12)
            
            // EXPANDABLE SEARCH BAR PANEL
            if isSearchingChat {
                HStack(spacing: 10) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                        
                        TextField("Search in chat...", text: $searchQuery)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .tint(.electricPurple)
                            .submitLabel(.search)
                        
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            Color.white.opacity(0.01) // Super transparent base for see-through feel
                .background(.ultraThinMaterial) // Clean glassmorphic transparent blur
        )
        .ignoresSafeArea(edges: .top)
    }
    
    // FLOATING MESSAGE INPUT BAR (Fully floating, glassmorphic, separate rounded capsule and button)
    private var floatingInputBar: some View {
        let isMultiLine = messageInput.contains("\n") || messageInput.count > 26
        let currentRadius: CGFloat = isMultiLine ? 16 : 22
        
        return HStack(spacing: 10) {
            // Dynamically rounded input capsule matching send button height (44)
            HStack {
                TextField("Type a message...", text: $messageInput, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(1...4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .focused($isInputFocused)
            }
            .frame(minHeight: 44)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: currentRadius))
            .overlay(
                RoundedRectangle(cornerRadius: currentRadius)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1.2)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
            
            // Separate Send Button (Outside, Floating on the right)
            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.deepVelvet)
                    .frame(width: 44, height: 44)
                    .background(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white.opacity(0.3) : Color.electricPurple)
                    .clipShape(Circle())
                    .shadow(color: messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.clear : Color.electricPurple.opacity(0.3), radius: 8, y: 3)
            }
            .disabled(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
    }
    
    @ViewBuilder
    private func bubbleBackground(isMe: Bool) -> some View {
        if isMe {
            LinearGradient(colors: [Color.electricPurple, Color.electricPurple.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    // WHATSAPP STYLE CHAT BUBBLES WITH INDIVIDUAL TIME STAMPS
    private func chatBubble(msg: ChatMessage) -> some View {
        let isMe = msg.sender_id == auth.currentUser?.id
        let corners: UIRectCorner = isMe ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]
        let timeStr = formatMessageTime(msg.created_at)
        
        return HStack {
            if isMe {
                Spacer()
            }
            
            if msg.message.contains("[FLASH_ATTACHMENT]") {
                // SPECIAL INTERACTIVE FLASH ATTACHMENT CARD
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        auth.selectedTab = 0 // Switch to Dashboard Tab
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.shutter.button.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(isMe ? .deepVelvet : .activeCyan)
                            Text("Sent a Flash!")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(isMe ? .deepVelvet : .white)
                        }
                        
                        HStack {
                            Text("Tap to view on Dashboard")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(isMe ? .deepVelvet.opacity(0.7) : .white.opacity(0.6))
                            Spacer(minLength: 12)
                            if !timeStr.isEmpty {
                                Text(timeStr)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(isMe ? .deepVelvet.opacity(0.5) : .white.opacity(0.4))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isMe ? 
                        LinearGradient(colors: [Color.electricPurple, Color.electricPurple.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedCorner(radius: 18, corners: corners))
                    .overlay(
                        RoundedCorner(radius: 18, corners: corners)
                            .stroke(isMe ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: isMe ? Color.electricPurple.opacity(0.2) : Color.black.opacity(0.15), radius: 6, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // STANDARD CHAT BUBBLE
                VStack(alignment: .trailing, spacing: 4) {
                    Text(msg.message)
                        .font(.system(size: 13.5))
                        .foregroundColor(isMe ? .deepVelvet : .white)
                        .multilineTextAlignment(.leading)
                    
                    if !timeStr.isEmpty {
                        Text(timeStr)
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundColor(isMe ? .deepVelvet.opacity(0.6) : .white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(bubbleBackground(isMe: isMe))
                .clipShape(RoundedCorner(radius: 15, corners: corners))
                .overlay(
                    RoundedCorner(radius: 15, corners: corners)
                        .stroke(isMe ? Color.clear : Color.white.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: isMe ? Color.electricPurple.opacity(0.15) : Color.clear, radius: 6, y: 3)
            }
            
            if !isMe {
                Spacer()
            }
        }
        .id(msg.id)
    }
    
    // WHATSAPP STYLE DYNAMIC CENTERED DATE BADGE
    private func dateHeaderBadge(for msg: ChatMessage) -> some View {
        guard let raw = msg.created_at else { return AnyView(EmptyView()) }
        let dateStr = formatMessageDayString(raw)
        return AnyView(
            HStack {
                Spacer()
                Text(dateStr)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
                Spacer()
            }
            .padding(.vertical, 8)
        )
    }
    
    private func loadMessages() {
        guard auth.partner != nil && auth.coupleActive else { return }
        Task {
            if let msgs = try? await auth.fetchMessages() {
                await MainActor.run {
                    self.messages = msgs
                }
            }
        }
    }
    
    private func sendMessage() {
        let cleanText = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        isSending = true
        messageInput = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        Task {
            do {
                let sentMsg = try await auth.sendChatMessage(text: cleanText)
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        self.messages.append(sentMsg)
                    }
                    isSending = false
                    
                    // Soft "tek" click sound (Tink: 1104) and haptic "klek" (.rigid) on send
                    AudioServicesPlaySystemSound(1104) // Soft WA-like tek click
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }
            } catch {
                print("Failed to send message: \(error)")
                isSending = false
            }
        }
    }
    
    private func startPolling() {
        timer = Timer.publish(every: 5.0, on: .main, in: .common)
        cancellable = timer.connect()
    }
    
    private func stopPolling() {
        cancellable?.cancel()
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
    
    // FORMAT RAW TIME STRING TO LOCAL HOUR/MINUTE (HH:MM)
    private func formatMessageTime(_ rawDate: String?) -> String {
        guard let rawDate = rawDate else { return "" }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date = formatter.date(from: rawDate)
        
        if date == nil {
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            date = fallbackFormatter.date(from: rawDate)
        }
        
        guard let validDate = date else { return "" }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH:mm"
        outputFormatter.timeZone = TimeZone.current
        return outputFormatter.string(from: validDate)
    }
    
    // FORMAT DATE TO WHATSAPP STYLE LABELS ("Today", "Yesterday", or "16 May 2026")
    private func shouldShowDateHeader(for index: Int) -> Bool {
        let msgList = filteredMessages
        guard index < msgList.count else { return false }
        if index == 0 { return true }
        
        let currentMsg = msgList[index]
        let prevMsg = msgList[index - 1]
        
        guard let currentRaw = currentMsg.created_at, let prevRaw = prevMsg.created_at else { return false }
        
        let currentDay = formatMessageDayString(currentRaw)
        let prevDay = formatMessageDayString(prevRaw)
        
        return currentDay != prevDay
    }
    
    private func formatMessageDayString(_ rawDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date = formatter.date(from: rawDate)
        
        if date == nil {
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            date = fallbackFormatter.date(from: rawDate)
        }
        
        guard let validDate = date else { return "" }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(validDate) {
            return "Today"
        } else if calendar.isDateInYesterday(validDate) {
            return "Yesterday"
        } else {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "d MMMM yyyy"
            return outputFormatter.string(from: validDate)
        }
    }
}

// SwiftUI helper to support customizable individual rounded corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// PREMIUM BOUNCING DOTS TYPING INDICATOR
struct TypingIndicatorView: View {
    @State private var animateDot1 = false
    @State private var animateDot2 = false
    @State private var animateDot3 = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: 6, height: 6)
                .offset(y: animateDot1 ? -4 : 4)
            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: 6, height: 6)
                .offset(y: animateDot2 ? -4 : 4)
            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: 6, height: 6)
                .offset(y: animateDot3 ? -4 : 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedCorner(radius: 14, corners: [.topLeft, .topRight, .bottomRight]))
        .overlay(
            RoundedCorner(radius: 14, corners: [.topLeft, .topRight, .bottomRight])
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(0.0)) {
                animateDot1 = true
            }
            withAnimation(Animation.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(0.15)) {
                animateDot2 = true
            }
            withAnimation(Animation.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(0.3)) {
                animateDot3 = true
            }
        }
    }
}
