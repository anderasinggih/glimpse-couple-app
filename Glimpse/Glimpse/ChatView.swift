import SwiftUI
import Combine
import AudioToolbox

struct ChatView: View {
    @State private var auth = AuthManager.shared
    
    // Multi-room Chat state
    @State private var chatRooms: [GlimpseChatRoom] = []
    @State private var selectedRoom: GlimpseChatRoom? = nil
    @State private var isLoadingRooms = false
    @State private var showCreateRoomAlert = false
    @State private var newRoomName = ""
    @State private var showDeleteConfirmAlert = false
    @State private var roomToDelete: GlimpseChatRoom? = nil
    
    @State private var messages: [ChatMessage] = []
    @State private var messageInput = ""
    @State private var isSending = false
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 5.0, on: .main, in: .common)
    @State private var cancellable: Cancellable?
    @FocusState private var isInputFocused: Bool
    
    @State private var tickCount = 0
    @State private var isSearchingChat = false
    @State private var searchQuery = ""
    @State private var isShowingScrollToBottomButton = false
    @State private var showNoInternetAlert = false
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var pendingMessages: [ChatMessage] = []
    
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
                if let activeRoom = selectedRoom {
                    activeChatRoomView(partner: partner, room: activeRoom)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else {
                    chatRoomsListView(partner: partner)
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                }
            } else {
                notConnectedView
            }
        }
        .onChange(of: selectedRoom) { oldValue, newValue in
            auth.activeRoomId = newValue?.id
            if let activeRoom = newValue {
                // Reset unread counter locally upon entering the room
                if let index = chatRooms.firstIndex(where: { $0.id == activeRoom.id }) {
                    chatRooms[index].unread_count = 0
                    auth.chatRooms = chatRooms
                    auth.updateUnreadCount()
                }
            }
        }
        .onAppear {
            loadChatRooms()
            if selectedRoom != nil {
                loadMessagesForSelectedRoom()
            }
            startPolling()
            auth.pushCurrentStatus()
        }
        .onDisappear {
            stopPolling()
        }
        .onReceive(timer) { _ in
            if auth.partner != nil, auth.coupleActive {
                tickCount += 1
                if tickCount >= 2 {
                    tickCount = 0
                    auth.pushCurrentStatus()
                }
                // Refresh rooms list in background periodically
                if selectedRoom == nil {
                    Task { @MainActor in
                        if let rooms = try? await auth.fetchChatRooms() {
                            self.chatRooms = rooms
                        }
                    }
                } else {
                    loadMessagesForSelectedRoom()
                }
            }
        }
        // WebSocket synchronization for chat rooms
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlimpseChatRoomCreated"))) { notification in
            self.handleChatRoomCreated(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlimpseChatRoomDeleted"))) { notification in
            self.handleChatRoomDeleted(notification)
        }
        // Listen to live WebSocket message broadcasts from Partner
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlimpseChatMessageReceived"))) { notification in
            self.handleChatMessageReceived(notification)
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if isConnected {
                processPendingQueue()
            }
        }
        .onChange(of: messageInput) { oldValue, newValue in
            self.handleMessageInputChanged(oldValue: oldValue, newValue: newValue)
        }
        // Custom creation and deletion alerts
        .alert("New Chat Room", isPresented: $showCreateRoomAlert) {
            TextField("Room name", text: $newRoomName)
            Button("Cancel", role: .cancel) { newRoomName = "" }
            Button("Create") {
                createRoom()
            }
        } message: {
            Text("Create a new chat room to discuss a different topic with your partner.")
        }
        .alert("Delete Room?", isPresented: $showDeleteConfirmAlert, presenting: roomToDelete) { room in
            Button("Cancel", role: .cancel) { roomToDelete = nil }
            Button("Delete", role: .destructive) {
                deleteRoom(room)
            }
        } message: { room in
            Text("Are you sure you want to delete '\(room.name)'? All messages in this room will be permanently lost.")
        }
        .alert("No Internet Connection", isPresented: $showNoInternetAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No internet connection. Please connect to the internet and try again.")
        }
    }
    
    // --- 💬 ACTIVE CHAT ROOM SCREEN (Type-safety separated) ---
    @ViewBuilder
    private func activeChatRoomView(partner: GlimpseUser, room: GlimpseChatRoom) -> some View {
        ZStack(alignment: .top) {
            ScrollViewReader { proxy in
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            Spacer().frame(height: isSearchingChat ? 165 : 110)
                            
                            ForEach(Array(filteredMessages.enumerated()), id: \.element.id) { index, msg in
                                VStack(spacing: 12) {
                                    if shouldShowDateHeader(for: index) {
                                        dateHeaderBadge(for: msg)
                                    }
                                    
                                    if msg.id == firstUnreadMessageId {
                                        unreadMessagesDivider()
                                    }
                                    
                                    chatBubble(msg: msg)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.8, anchor: msg.sender_id == auth.currentUser?.id ? .bottomTrailing : .bottomLeading)
                                                .combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }
                            }
                            
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
                            }
                            
                            if auth.isPartnerTyping {
                                HStack {
                                    TypingIndicatorView()
                                    Spacer()
                                }
                                .padding(.leading, 4)
                                .padding(.top, 4)
                            }
                            
                            if !pendingMessages.isEmpty {
                                VStack(spacing: 12) {
                                    HStack {
                                        Rectangle()
                                            .fill(LinearGradient(colors: [.clear, .electricPurple.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                                            .frame(height: 1)
                                        Text("Sending...")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundColor(.electricPurple.opacity(0.8))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(.ultraThinMaterial)
                                            .cornerRadius(10)
                                        Rectangle()
                                            .fill(LinearGradient(colors: [.electricPurple.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing))
                                            .frame(height: 1)
                                    }
                                    .padding(.vertical, 8)
                                    
                                    ForEach(pendingMessages) { msg in
                                        chatBubble(msg: msg, isPending: true)
                                    }
                                }
                            }
                            
                            Spacer().frame(height: 15)
                            
                            Color.clear
                                .frame(height: 1)
                                .id("bottom_anchor")
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
                    }
                    .safeAreaInset(edge: .bottom) {
                        bottomInputInsetView
                    }
                    .onChange(of: messages) { oldMessages, newMessages in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                proxy.scrollTo("bottom_anchor", anchor: .bottom)
                            }
                        }
                        if let lastMsg = newMessages.last {
                            if !oldMessages.isEmpty && lastMsg.sender_id == auth.partner?.id {
                                AudioServicesPlaySystemSound(1103)
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            }
                        }
                    }
                    .onChange(of: pendingMessages) { _, _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                proxy.scrollTo("bottom_anchor", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: auth.isPartnerTyping) { _, isTyping in
                        if isTyping {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                    proxy.scrollTo("bottom_anchor", anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: isInputFocused) { _, isFocused in
                        if isFocused {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                    proxy.scrollTo("bottom_anchor", anchor: .bottom)
                                }
                            }
                        }
                    }
                    
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
                                        .fill(Color.activeCyan)
                                        .shadow(color: .activeCyan.opacity(0.6), radius: 8, x: 0, y: 4)
                                )
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 90)
                    }
                }
            }
            chatHeader(partner: partner, room: room)
                .zIndex(10)
        }
    }
    
    // --- 🗂️ CHAT ROOMS LIST SCREEN (Type-safety separated) ---
    @ViewBuilder
    private func chatRoomsListView(partner: GlimpseUser) -> some View {
        VStack(spacing: 0) {
            roomsListHeader(partner: partner)
                .zIndex(10)
            
            if isLoadingRooms {
                Spacer()
                ProgressView()
                    .tint(.activeCyan)
                Spacer()
            } else if chatRooms.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.2))
                    Text("No chat rooms yet")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
            } else {
                List {
                    ForEach(chatRooms) { room in
                        roomRow(room)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedRoom = room
                                }
                                loadMessagesForSelectedRoom()
                            }
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            let room = chatRooms[index]
                            if room.is_main {
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                return
                            }
                            roomToDelete = room
                            showDeleteConfirmAlert = true
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.top, 8)
            }
        }
    }
    
    // --- 🚫 NOT CONNECTED VIEW ---
    @ViewBuilder
    private var notConnectedView: some View {
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
    
    // --- 📥 BOTTOM INPUT INSET VIEW ---
    @ViewBuilder
    private var bottomInputInsetView: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.8)
            
            if !NetworkMonitor.shared.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.red)
                        .font(.system(size: 13, weight: .bold))
                    Text("No Internet Connection")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.15))
                .cornerRadius(10)
                .padding(.top, 8)
            }
            
            floatingInputBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
        .background(
            Color.white.opacity(0.01)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // --- 🗂️ ROOMS LIST HEADER ---
    private func roomsListHeader(partner: GlimpseUser) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                AsyncImage(url: URL(string: formattedUrl(partner.profile_photo_url))) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.white.opacity(0.1)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.activeCyan.opacity(0.3), lineWidth: 1.5))
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Chat Rooms")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 5) {
                        Circle()
                            .fill(partner.isOffline ? Color.gray : Color.green)
                            .frame(width: 6, height: 6)
                        Text(partner.isOffline ? "Offline" : "Online")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
                
                Spacer()
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    newRoomName = ""
                    showCreateRoomAlert = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 50)
            .padding(.bottom, 12)
        }
        .background(
            Color.white.opacity(0.01)
                .background(.ultraThinMaterial)
        )
        .ignoresSafeArea(edges: .top)
    }
    
    // --- 🏷️ ROOM ROW COMPONENT (WhatsApp style row) ---
    private func roomRow(_ room: GlimpseChatRoom) -> some View {
        HStack(spacing: 14) {
            // Room Icon Container
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: room.is_main ? [.activeCyan.opacity(0.2), .activeCyan.opacity(0.05)] : [.white.opacity(0.12), .white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 46, height: 46)
                
                Image(systemName: room.is_main ? "star.bubble.fill" : "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 18))
                    .foregroundColor(room.is_main ? .activeCyan : .white.opacity(0.8))
            }
            .overlay(
                Circle()
                    .stroke(room.is_main ? Color.activeCyan.opacity(0.2) : Color.white.opacity(0.08), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(room.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let latest = room.latest_message, let rawTime = latest.created_at {
                        Text(formatMessageTime(rawTime))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                HStack {
                    if let latest = room.latest_message {
                        let senderName = latest.sender_id == auth.currentUser?.id ? "You: " : ""
                        Text("\(senderName)\(latest.message)")
                            .font(.system(size: 12.5))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(1)
                    } else {
                        Text("No messages yet")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    
                    Spacer()
                    
                    if room.unread_count > 0 {
                        Text("\(room.unread_count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.activeCyan))
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(room.is_main ? 0.05 : 0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(room.is_main ? Color.activeCyan.opacity(0.12) : Color.white.opacity(0.04), lineWidth: 1)
        )
    }
    
    // --- 💬 ACTIVE ROOM HEADER WITH BACK BUTTON ---
    private func chatHeader(partner: GlimpseUser, room: GlimpseChatRoom) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedRoom = nil
                    }
                    loadChatRooms()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                
                AsyncImage(url: URL(string: formattedUrl(partner.profile_photo_url))) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.white.opacity(0.1)
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.activeCyan.opacity(0.3), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(room.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(partner.isOffline ? Color.gray : Color.green)
                            .frame(width: 5, height: 5)
                        Text(partner.isOffline ? "Offline" : "Online")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
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
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSearchingChat ? .activeCyan : .white.opacity(0.8))
                        .padding(6)
                        .background(Color.white.opacity(isSearchingChat ? 0.15 : 0.05))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 50)
            .padding(.bottom, 10)
            
            if isSearchingChat {
                HStack(spacing: 10) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                        
                        TextField("Search in chat...", text: $searchQuery)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .tint(.activeCyan)
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
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            Color.white.opacity(0.01)
                .background(.ultraThinMaterial)
        )
        .ignoresSafeArea(edges: .top)
    }
    
    // FLOATING MESSAGE INPUT BAR (Fully floating, glassmorphic, separate rounded capsule and button)
    private var floatingInputBar: some View {
        let isMultiLine = messageInput.contains("\n") || messageInput.count > 26
        let currentRadius: CGFloat = isMultiLine ? 16 : 22
        
        return HStack(spacing: 10) {
            HStack {
                TextField("Type a message...", text: $messageInput, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(1...4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .focused($isInputFocused)
                    .onChange(of: messageInput) { oldValue, newValue in
                        if newValue.count > 500 {
                            messageInput = String(newValue.prefix(500))
                        }
                    }
            }
            .frame(minHeight: 44)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: currentRadius))
            .overlay(
                RoundedRectangle(cornerRadius: currentRadius)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1.2)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.deepVelvet)
                    .frame(width: 44, height: 44)
                    .background(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white.opacity(0.3) : Color.activeCyan)
                    .clipShape(Circle())
                    .shadow(color: messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.clear : Color.activeCyan.opacity(0.3), radius: 8, y: 3)
            }
            .disabled(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    @ViewBuilder
    private func bubbleBackground(isMe: Bool) -> some View {
        if isMe {
            Color.activeCyan.opacity(0.18)
        } else {
            Color.white.opacity(0.08)
        }
    }
    
    // WHATSAPP STYLE CHAT BUBBLES WITH INDIVIDUAL TIME STAMPS
    private func chatBubble(msg: ChatMessage, isPending: Bool = false) -> some View {
        let isMe = msg.sender_id == auth.currentUser?.id
        let corners: UIRectCorner = isMe ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]
        let timeStr = formatMessageTime(msg.created_at)
        
        return VStack(alignment: .trailing, spacing: 2) {
            HStack {
                if isMe {
                    Spacer()
                }
                
                if msg.message.contains("[FLASH_ATTACHMENT]") {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            auth.selectedTab = 0
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.shutter.button.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.activeCyan)
                                Text("Sent a Flash!")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("Tap to view on Dashboard")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer(minLength: 8)
                                if !timeStr.isEmpty {
                                    Text(timeStr)
                                        .font(.system(size: 7.5, weight: .medium))
                                        .foregroundColor(isMe ? .activeCyan.opacity(0.65) : .white.opacity(0.4))
                                }
                            }
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .frame(width: 175)
                        .background(
                            isMe ? Color.activeCyan.opacity(0.18) : Color.white.opacity(0.12)
                        )
                        .clipShape(RoundedCorner(radius: 18, corners: corners))
                        .overlay(
                            RoundedCorner(radius: 18, corners: corners)
                                .stroke(isMe ? Color.activeCyan.opacity(0.35) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: isMe ? Color.activeCyan.opacity(0.1) : Color.black.opacity(0.15), radius: 6, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if msg.message.contains("[KENCAN_INVITATION]") {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            auth.showScheduleSheet = true
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.activeCyan)
                                Text("New Kencan Invite!")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            let cleanMsg = msg.message.replacingOccurrences(of: "[KENCAN_INVITATION] ", with: "")
                            Text(cleanMsg)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.leading)
                            
                            HStack {
                                Text("Tap to respond & set Alarm")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.activeCyan)
                                Spacer(minLength: 8)
                                if !timeStr.isEmpty {
                                    Text(timeStr)
                                        .font(.system(size: 7.5, weight: .medium))
                                        .foregroundColor(isMe ? .activeCyan.opacity(0.65) : .white.opacity(0.4))
                                }
                            }
                            .padding(.top, 2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .frame(width: 220)
                        .background(
                            isMe ? Color.activeCyan.opacity(0.18) : Color.white.opacity(0.12)
                        )
                        .clipShape(RoundedCorner(radius: 18, corners: corners))
                        .overlay(
                            RoundedCorner(radius: 18, corners: corners)
                                .stroke(isMe ? Color.activeCyan.opacity(0.45) : Color.white.opacity(0.12), lineWidth: 1.2)
                        )
                        .shadow(color: isMe ? Color.activeCyan.opacity(0.15) : Color.black.opacity(0.15), radius: 6, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(msg.message)
                            .font(.system(size: 12.5))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 3) {
                            if !timeStr.isEmpty {
                                Text(timeStr)
                                    .font(.system(size: 8.0, weight: .medium))
                                    .foregroundColor(isMe ? .activeCyan.opacity(0.65) : .white.opacity(0.4))
                            }
                            
                            if isPending {
                                Image(systemName: "clock")
                                    .font(.system(size: 8.0))
                                    .foregroundColor(isMe ? .activeCyan.opacity(0.65) : .white.opacity(0.4))
                            }
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5.5)
                    .background(bubbleBackground(isMe: isMe))
                    .clipShape(RoundedCorner(radius: 15, corners: corners))
                    .overlay(
                        RoundedCorner(radius: 15, corners: corners)
                            .stroke(isMe ? Color.activeCyan.opacity(0.35) : Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .shadow(color: isMe ? Color.activeCyan.opacity(0.1) : Color.clear, radius: 4, y: 2)
                }
                
                if !isMe {
                    Spacer()
                }
            }
            
            if isMe && msg.id == auth.partner?.last_seen_message_id {
                HStack(spacing: 3.5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 8))
                    Text("Seen")
                        .font(.system(size: 9.5, weight: .semibold))
                }
                .foregroundColor(.activeCyan.opacity(0.85))
                .padding(.trailing, 6)
                .padding(.top, 1)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
        if !auth.latestFetchedMessages.isEmpty {
            self.messages = auth.latestFetchedMessages
        }
        Task { @MainActor in
            if let msgs = try? await auth.fetchMessages() {
                self.messages = msgs
            }
        }
    }
    
    private func loadChatRooms() {
        guard auth.partner != nil && auth.coupleActive else { return }
        isLoadingRooms = true
        Task { @MainActor in
            do {
                let rooms = try await auth.fetchChatRooms()
                self.chatRooms = rooms
                self.isLoadingRooms = false
            } catch {
                print("❌ Failed to load chat rooms: \(error)")
                self.isLoadingRooms = false
            }
        }
    }
    
    private func loadMessagesForSelectedRoom() {
        guard let activeRoom = selectedRoom else { return }
        Task { @MainActor in
            do {
                let msgs = try await auth.fetchMessages(roomId: activeRoom.id)
                self.messages = msgs
                // Reset unread counter locally upon entering the room
                if let index = chatRooms.firstIndex(where: { $0.id == activeRoom.id }) {
                    chatRooms[index].unread_count = 0
                    auth.chatRooms = chatRooms
                    auth.updateUnreadCount()
                }
            } catch {
                print("❌ Failed to fetch messages for room \(activeRoom.name): \(error)")
            }
        }
    }
    
    private func createRoom() {
        let name = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { @MainActor in
            if let newRoom = try? await auth.createChatRoom(name: name) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.chatRooms.append(newRoom)
                    auth.chatRooms = self.chatRooms
                    auth.updateUnreadCount()
                }
                newRoomName = ""
            }
        }
    }
    
    private func deleteRoom(_ room: GlimpseChatRoom) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { @MainActor in
            do {
                try await auth.deleteChatRoom(roomId: room.id)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    var filtered: [GlimpseChatRoom] = []
                    for r in self.chatRooms {
                        if r.id != room.id {
                            filtered.append(r)
                        }
                    }
                    self.chatRooms = filtered
                    auth.chatRooms = filtered
                    auth.updateUnreadCount()
                }
                roomToDelete = nil
            } catch {
                print("❌ Failed to delete room: \(error)")
            }
        }
    }
    
    private func sendMessage() {
        let cleanText = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        messageInput = ""
        AudioServicesPlaySystemSound(1104)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        
        let tempId = Int.random(in: -100000...(-1))
        let formatter = ISO8601DateFormatter()
        let createdAtStr = formatter.string(from: Date())
        
        let tempMsg = ChatMessage(
            id: tempId,
            couple_id: auth.currentUser?.couple_id ?? 0,
            sender_id: auth.currentUser?.id ?? 0,
            message: cleanText,
            room_id: selectedRoom?.id,
            created_at: createdAtStr,
            updated_at: createdAtStr
        )
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.pendingMessages.append(tempMsg)
        }
        
        Task {
            await attemptSendPendingMessage(tempMsg)
        }
    }
    
    @MainActor
    private func attemptSendPendingMessage(_ msg: ChatMessage) async {
        guard NetworkMonitor.shared.isConnected else { return }
        do {
            let sentMsg = try await auth.sendChatMessage(text: msg.message, roomId: selectedRoom?.id)
            withAnimation(.easeOut(duration: 0.2)) {
                var newPending: [ChatMessage] = []
                for p in self.pendingMessages {
                    if p.id != msg.id {
                        newPending.append(p)
                    }
                }
                self.pendingMessages = newPending
                
                var exists = false
                for m in self.messages {
                    if m.id == sentMsg.id {
                        exists = true
                        break
                    }
                }
                if !exists {
                    self.messages.append(sentMsg)
                }
            }
        } catch {
            print("❌ Failed to send pending message: \(error)")
        }
    }
    
    private func processPendingQueue() {
        guard NetworkMonitor.shared.isConnected, !pendingMessages.isEmpty else { return }
        Task {
            let currentPending = pendingMessages
            for msg in currentPending {
                await attemptSendPendingMessage(msg)
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
    
    private var firstUnreadMessageId: Int? {
        let partnerId = auth.partner?.id ?? 0
        let initialReadId = auth.initialLastReadId
        return messages.first(where: { msg in
            msg.sender_id == partnerId && msg.id > initialReadId
        })?.id
    }
    
    private func unreadMessagesDivider() -> some View {
        HStack {
            VStack { Divider().background(Color(hex: "FF4D6D").opacity(0.3)) }
            Text("New Messages")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "FF4D6D"))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: "FF4D6D").opacity(0.1))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "FF4D6D").opacity(0.2), lineWidth: 1)
                )
            
            VStack { Divider().background(Color(hex: "FF4D6D").opacity(0.3)) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .transition(.opacity)
    }
    
    // --- 📡 WEBSOCKET & STATE CHANGE HANDLERS (Decoupled from SwiftUI hierarchy) ---
    private func handleChatRoomCreated(_ notification: Notification) {
        guard let newRoom = notification.object as? GlimpseChatRoom else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            var exists = false
            for room in chatRooms {
                if room.id == newRoom.id {
                    exists = true
                    break
                }
            }
            if !exists {
                chatRooms.append(newRoom)
            }
        }
    }
    
    private func handleChatRoomDeleted(_ notification: Notification) {
        guard let deletedId = notification.object as? Int else { return }
        var shouldResetSelected = false
        if let activeRoom = selectedRoom {
            shouldResetSelected = activeRoom.id == deletedId
        }
        
        var filteredRooms: [GlimpseChatRoom] = []
        for room in chatRooms {
            if room.id != deletedId {
                filteredRooms.append(room)
            }
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            chatRooms = filteredRooms
            if shouldResetSelected {
                selectedRoom = nil
            }
        }
    }
    
    private func handleChatMessageReceived(_ notification: Notification) {
        guard let newMsg = notification.object as? ChatMessage else { return }
        let isMainRoom = selectedRoom?.is_main ?? false
        let isSameRoom = selectedRoom?.id == newMsg.room_id
        let isCurrentRoom = isSameRoom || (isMainRoom && newMsg.room_id == nil)
        
        let currentUserId = auth.currentUser?.id ?? 0
        let partnerId = auth.partner?.id ?? 0
        let isMyMessage = newMsg.sender_id == currentUserId
        let isPartnerMessage = newMsg.sender_id == partnerId
        
        if isCurrentRoom {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                if isMyMessage {
                    var foundTemp = false
                    for i in 0..<self.messages.count {
                        if self.messages[i].id < 0 {
                            self.messages[i] = newMsg
                            foundTemp = true
                            break
                        }
                    }
                    if foundTemp {
                        return
                    }
                }
                
                var alreadyExists = false
                for m in self.messages {
                    if m.id == newMsg.id {
                        alreadyExists = true
                        break
                    }
                }
                if !alreadyExists {
                    self.messages.append(newMsg)
                }
            }
        }
        
        // Update latest message in rooms list
        var targetIndex: Int? = nil
        for i in 0..<chatRooms.count {
            let r = chatRooms[i]
            if r.id == newMsg.room_id || (r.is_main && newMsg.room_id == nil) {
                targetIndex = i
                break
            }
        }
        
        if let index = targetIndex {
            var updated = chatRooms[index]
            updated.latest_message = RoomLatestMessage(
                id: newMsg.id,
                message: newMsg.message,
                sender_id: newMsg.sender_id,
                created_at: newMsg.created_at
            )
            
            let isDifferentRoom = selectedRoom?.id != updated.id
            if isDifferentRoom && isPartnerMessage {
                updated.unread_count += 1
            }
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                chatRooms[index] = updated
            }
        }
    }
    
    private func handleMessageInputChanged(oldValue: String, newValue: String) {
        let cleanNew = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanOld = oldValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !cleanNew.isEmpty && cleanOld.isEmpty {
            auth.sendTypingStatus(isTyping: true)
        } else if cleanNew.isEmpty && !cleanOld.isEmpty {
            auth.sendTypingStatus(isTyping: false)
        }
    }
}

struct TypingIndicatorView: View {
    @State private var animateDot1 = false
    @State private var animateDot2 = false
    @State private var animateDot3 = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 5, height: 5)
                .scaleEffect(animateDot1 ? 1.4 : 0.8)
                .offset(y: animateDot1 ? -3 : 0)
            
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 5, height: 5)
                .scaleEffect(animateDot2 ? 1.4 : 0.8)
                .offset(y: animateDot2 ? -3 : 0)
            
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 5, height: 5)
                .scaleEffect(animateDot3 ? 1.4 : 0.8)
                .offset(y: animateDot3 ? -3 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
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

// SwiftUI helper to support customizable individual rounded corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
