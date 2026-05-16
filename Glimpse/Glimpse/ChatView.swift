import SwiftUI
import Combine

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
    
    var body: some View {
        ZStack {
            // LAYER 1: Background
            ZStack {
                Color.deepVelvet.ignoresSafeArea()
                iOS26Background().opacity(0.4)
            }
            .ignoresSafeArea()
            .ignoresSafeArea(.keyboard)
            
            // LAYER 2: Main Content
            if let partner = auth.partner, auth.coupleActive {
                VStack(spacing: 0) {
                    // Premium Small Header
                    chatHeader(partner: partner)
                        .zIndex(10)
                    
                    // Messages and Floating Input
                    ZStack(alignment: .bottom) {
                        // Scrollable Messages List
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(messages) { msg in
                                        chatBubble(msg: msg)
                                    }
                                    
                                    // Space to avoid being covered by floating input bar
                                    Spacer().frame(height: 85)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 15)
                            }
                            .onChange(of: messages) { _, newMessages in
                                if let lastMsg = newMessages.last {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        proxy.scrollTo(lastMsg.id, anchor: .bottom)
                                    }
                                }
                            }
                            .onAppear {
                                if let lastMsg = messages.last {
                                    proxy.scrollTo(lastMsg.id, anchor: .bottom)
                                }
                            }
                        }
                        
                        // Floating Message Input (Frosted Glass Container)
                        floatingInputBar
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                }
                .ignoresSafeArea(edges: .top)
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
            if auth.partner != nil && auth.coupleActive {
                tickCount += 1
                
                // 1. Every tick (1.5s): Fetch messages and full partner state
                Task {
                    if let newMsgs = try? await auth.fetchMessages(), newMsgs != self.messages {
                        await MainActor.run {
                            self.messages = newMsgs
                        }
                    }
                    try? await auth.fetchState()
                }
                
                // 2. Every 8 ticks (~12s): Push our current battery/charging status to partner
                if tickCount >= 8 {
                    tickCount = 0
                    auth.pushCurrentStatus()
                }
            }
        }
    }
    
    // PREMIUM TINY HEADER
    private func chatHeader(partner: GlimpseUser) -> some View {
        HStack(spacing: 12) {
            // Profile Photo (Small circle)
            AsyncImage(url: URL(string: formattedUrl(partner.profile_photo_url))) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.white.opacity(0.1)
            }
            .frame(width: 38, height: 38)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.electricPurple.opacity(0.3), lineWidth: 1.5))
            
            // Partner Details (Tiny & Compact)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(partner.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Online Indicator Dot
                    Circle()
                        .fill(partner.isOffline ? Color.gray : Color.green)
                        .frame(width: 6, height: 6)
                }
                
                // Status, Location, and Battery
                HStack(spacing: 8) {
                    // 1. Online / Offline Status
                    Text(partner.isOffline ? "Offline" : "Online")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                    
                    // 2. Location
                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 8))
                        Text(partner.location_name ?? "Unknown")
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                    .foregroundColor(.electricPurple.opacity(0.8))
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                    
                    // 3. Battery with Charging Support
                    HStack(spacing: 2) {
                        Image(systemName: partner.is_charging == true ? "battery.100.bolt" : "battery.75")
                            .font(.system(size: 10))
                            .foregroundColor(partner.is_charging == true ? .green : (partner.battery_level ?? 100 > 20 ? .white.opacity(0.6) : .red))
                        Text("\(partner.battery_level ?? 100)%")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .ignoresSafeArea(edges: .top)
        .overlay(
            VStack {
                Spacer()
                Divider().background(Color.white.opacity(0.08))
            }
        )
    }
    
    // FLOATING MESSAGE INPUT BAR (Fully floating, glassmorphic, no outer border block)
    private var floatingInputBar: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $messageInput)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color.white.opacity(0.06))
                .cornerRadius(20)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .focused($isInputFocused)
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.deepVelvet)
                    .padding(11)
                    .background(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white.opacity(0.3) : Color.electricPurple)
                    .clipShape(Circle())
            }
            .disabled(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.12), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 12, y: 6)
    }
    
    @ViewBuilder
    private func bubbleBackground(isMe: Bool) -> some View {
        if isMe {
            LinearGradient(colors: [Color.electricPurple, Color.electricPurple.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private func chatBubble(msg: ChatMessage) -> some View {
        let isMe = msg.sender_id == auth.currentUser?.id
        let corners: UIRectCorner = isMe ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]
        
        return HStack {
            if isMe {
                Spacer()
            }
            
            Text(msg.message)
                .font(.system(size: 15))
                .foregroundColor(isMe ? .deepVelvet : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(bubbleBackground(isMe: isMe))
                .clipShape(RoundedCorner(radius: 18, corners: corners))
                .overlay(
                    RoundedCorner(radius: 18, corners: corners)
                        .stroke(isMe ? Color.clear : Color.white.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: isMe ? Color.electricPurple.opacity(0.2) : Color.clear, radius: 8, y: 4)
            
            if !isMe {
                Spacer()
            }
        }
        .id(msg.id)
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
                    self.messages.append(sentMsg)
                    isSending = false
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
