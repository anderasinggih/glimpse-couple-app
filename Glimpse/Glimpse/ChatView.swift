import SwiftUI
import Combine
import AudioToolbox

struct ChatView: View {
    @State private var auth = AuthManager.shared
    @State private var messages: [ChatMessage] = []
    @State private var messageInput = ""
    @State private var isSending = false
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 1.5, on: .main, in: .common)
    @State private var cancellable: Cancellable?
    @FocusState private var isInputFocused: Bool
    
    // To track when to push status (every 8 ticks of the 1.5s timer = ~12s)
    @State private var tickCount = 0
    @State private var isPartnerTyping = false
    
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
                        ScrollView {
                            VStack(spacing: 12) {
                                // Top space to offset first message below the frosted header
                                Spacer().frame(height: 110)
                                
                                ForEach(Array(messages.enumerated()), id: \.element.id) { index, msg in
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
                                
                                if isPartnerTyping {
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
                                
                                // Space at bottom to prevent floating bar overlapping last message
                                Spacer().frame(height: 95)
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 600)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isInputFocused = false
                            }
                        }
                        .onChange(of: messages) { oldMessages, newMessages in
                            if let lastMsg = newMessages.last {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    proxy.scrollTo(lastMsg.id, anchor: .bottom)
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
                    }
                    
                    // Frosted Glass Bottom Panel covering Input Bar & Safe Area
                    VStack {
                        Spacer()
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
                            Color.deepVelvet.opacity(0.6)
                                .background(.ultraThickMaterial)
                                .ignoresSafeArea(edges: .bottom)
                        )
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
        // Poll for updates in real-time
        .onReceive(timer) { _ in
            if let partner = auth.partner, auth.coupleActive {
                tickCount += 1
                
                // 1. Every tick (1.5s): Fetch messages and full partner state
                Task {
                    if let newMsgs = try? await auth.fetchMessages(), newMsgs != self.messages {
                        await MainActor.run {
                            let oldMsgsCount = self.messages.count
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                self.messages = newMsgs
                            }
                            
                            // Play soft "ting" sound (1103) and tactile "klek" haptic (.rigid) on background messages
                            if oldMsgsCount > 0, let lastMsg = newMsgs.last, lastMsg.sender_id == partner.id {
                                AudioServicesPlaySystemSound(1103) // Soft ting/chime
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            }
                        }
                    }
                    try? await auth.fetchState()
                }
                
                // Simulate typing animation occasionally when partner is online
                if !partner.isOffline {
                    if Double.random(in: 0...1) < 0.15 && !isPartnerTyping {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            isPartnerTyping = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                isPartnerTyping = false
                            }
                        }
                    }
                }
                
                // 2. Every 8 ticks (~12s): Push our current battery/charging status to partner
                if tickCount >= 8 {
                    tickCount = 0
                    auth.pushCurrentStatus()
                }
            }
        }
    }
    
    // PREMIUM TINY HEADER WITH INTEGRATED BLUR EFFECT (Bleeds to top edge)
    private func chatHeader(partner: GlimpseUser) -> some View {
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
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
        .padding(.bottom, 12)
        .background(Color.deepVelvet.opacity(0.65).background(.ultraThickMaterial))
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
        timer = Timer.publish(every: 1.5, on: .main, in: .common)
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
        guard index < messages.count else { return false }
        if index == 0 { return true }
        
        let currentMsg = messages[index]
        let prevMsg = messages[index - 1]
        
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
