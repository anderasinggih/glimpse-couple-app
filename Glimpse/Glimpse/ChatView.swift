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
    @State private var showClearChatConfirmAlert = false
    @State private var roomToClear: GlimpseChatRoom? = nil
    @State private var showRoomOptionsDialog = false
    @State private var roomForOptions: GlimpseChatRoom? = nil
    @State private var showRenameRoomAlert = false
    @State private var roomToRename: GlimpseChatRoom? = nil
    @State private var renameRoomName = ""
    @State private var dragOffset: CGFloat = 0
    @State private var pinnedRoomIds: Set<Int> = []
    @State private var scrollToMessageTrigger: Int? = nil
    
    // Delete Request flows
    @State private var showRequestDeleteAlert = false
    @State private var roomToRequestDelete: GlimpseChatRoom? = nil
    @State private var showRespondDeleteRequestAlert = false
    @State private var roomToRespondDelete: GlimpseChatRoom? = nil
    @State private var showPendingDeleteRequestAlert = false
    @State private var roomToDeleteRequest: GlimpseChatRoom? = nil
    
    @State private var messages: [ChatMessage] = []
    @State private var messagesCache: [Int: [ChatMessage]] = [:] // Local cache for instant message loads
    @State private var messageInput = ""
    @State private var replyMessage: ChatMessage? = nil
    @State private var isSending = false
    @FocusState private var isInputFocused: Bool
    @FocusState private var isSearchFocused: Bool
    @FocusState private var isInsideChatSearchFocused: Bool
    
    @State private var tickCount = 0
    @State private var isSearchingChat = false
    @State private var searchQuery = ""
    @State private var debouncedSearchQuery = ""
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var isShowingScrollToBottomButton = false
    @State private var showNoInternetAlert = false
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var pendingMessages: [ChatMessage] = []
    @State private var highlightedMessageId: Int? = nil
    @State private var roomInitialLastReadId: Int? = nil
    
    // Inside-chat Search & Jump-to-Date State variables
    @State private var localSearchMatchIds: [Int] = []
    @State private var localSearchCurrentIndex: Int = -1
    @State private var showDatePickerForJump = false
    @State private var jumpToDateValue = Date()
    @State private var triggerJumpToDate = false
    
    // Magic Glow States
    @State private var newlySentMessageIds: Set<Int> = []
    @State private var newlyReceivedMessageIds: Set<Int> = []
    
    // Chat Settings & Starred messages
    @State private var showRoomDetailsSheet = false
    @State private var chatTextSize: CGFloat = UserDefaults.standard.object(forKey: "glimpse_chat_text_size") as? CGFloat ?? 14.0
    @State private var starredMessageIds: Set<Int> = []
    @State private var pinnedMessageIds: Set<Int> = []
    
    private var activeRoomThemeColor: Color {
        if let hex = selectedRoom?.theme_color, !hex.isEmpty {
            return Color(hex: hex)
        }
        return Color.activeCyan
    }
    
    private var activeRoomBgColor: Color {
        if let hex = selectedRoom?.background_color, !hex.isEmpty {
            return Color(hex: hex)
        }
        return Color.deepVelvet
    }
    
    var filteredMessages: [ChatMessage] {
        let cleanQuery = debouncedSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanQuery.isEmpty || isSearchingChat {
            return messages
        }
        return messages.filter { $0.message.localizedCaseInsensitiveContains(cleanQuery) }
    }
    
    var sortedChatRooms: [GlimpseChatRoom] {
        chatRooms.sorted { r1, r2 in
            // 1. Main room is always first
            if r1.is_main != r2.is_main {
                return r1.is_main
            }
            // 2. Pinned rooms are next
            let r1Pinned = pinnedRoomIds.contains(r1.id)
            let r2Pinned = pinnedRoomIds.contains(r2.id)
            if r1Pinned != r2Pinned {
                return r1Pinned
            }
            // 3. Sort by latest message or creation time
            let r1Time = r1.latest_message?.created_at ?? r1.created_at
            let r2Time = r2.latest_message?.created_at ?? r2.created_at
            return r1Time > r2Time
        }
    }
    
    struct GlobalSearchResult: Identifiable {
        var id: String { "\(room.id)_\(message.id)" }
        let room: GlimpseChatRoom
        let message: ChatMessage
    }
    
    var globalSearchResults: [GlobalSearchResult] {
        let cleanQuery = debouncedSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return [] }
        
        // Collect all unique messages across caches
        var allCached: [Int: [ChatMessage]] = messagesCache
        for (roomId, msgs) in auth.roomMessagesCache {
            if allCached[roomId] == nil {
                allCached[roomId] = msgs
            } else {
                var merged = allCached[roomId] ?? []
                for m in msgs {
                    if !merged.contains(where: { $0.id == m.id }) {
                        merged.append(m)
                    }
                }
                allCached[roomId] = merged
            }
        }
        
        var uniqueResults: [String: GlobalSearchResult] = [:]
        
        // Filter messages containing query
        for room in chatRooms {
            var msgsToSearch = allCached[room.id] ?? []
            // If main room, also include messages cached under room_id 0
            if room.is_main, let mainMsgs = allCached[0] {
                for m in mainMsgs {
                    if !msgsToSearch.contains(where: { $0.id == m.id }) {
                        msgsToSearch.append(m)
                    }
                }
            }
            
            for msg in msgsToSearch {
                if msg.message.contains("[FLASH_ATTACHMENT]") || msg.message.contains("[KENCAN_INVITATION]") {
                    continue
                }
                if msg.message.localizedCaseInsensitiveContains(cleanQuery) {
                    let result = GlobalSearchResult(room: room, message: msg)
                    uniqueResults[result.id] = result
                }
            }
        }
        
        return uniqueResults.values.sorted { $0.message.id > $1.message.id }
    }
    
    private var swipeProgress: CGFloat {
        min(1.0, max(0.0, dragOffset / UIScreen.main.bounds.width))
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
                ZStack {
                    chatRoomsListView(partner: partner)
                        .alert("Request Clear Chat?", isPresented: $showRequestDeleteAlert, presenting: roomToRequestDelete) { room in
                            Button("Cancel", role: .cancel) { roomToRequestDelete = nil }
                            Button("Request", role: .destructive) {
                                requestDeleteRoom(room)
                            }
                        } message: { room in
                            Text("Requesting to clear general chat will ask your partner for confirmation. If approved, all messages will be permanently cleared.")
                        }
                        .alert("Partner Requested Clear Chat", isPresented: $showRespondDeleteRequestAlert, presenting: roomToRespondDelete) { room in
                            Button("Decline", role: .destructive) {
                                declineDeleteRoom(room)
                            }
                            Button("Accept & Clear", role: .none) {
                                confirmDeleteRoom(room)
                            }
                            Button("Cancel", role: .cancel) { roomToRespondDelete = nil }
                        } message: { room in
                            Text("Your partner has requested to permanently clear the general chat history. Do you accept this request?")
                        }
                        .alert("Clear Chat Request Pending", isPresented: $showPendingDeleteRequestAlert, presenting: roomToDeleteRequest) { room in
                            Button("Cancel Request", role: .destructive) {
                                declineDeleteRoom(room)
                            }
                            Button("OK", role: .cancel) { roomToDeleteRequest = nil }
                        } message: { room in
                            Text("Waiting for your partner to confirm clearing the general chat history. You can cancel your request here.")
                        }
                        .alert("Chat Options", isPresented: $showRoomOptionsDialog, presenting: roomForOptions) { room in
                            Button("Clear Chat", role: .destructive) {
                                roomToClear = room
                                showClearChatConfirmAlert = true
                            }
                            Button("Delete Room", role: .destructive) {
                                roomToDelete = room
                                showDeleteConfirmAlert = true
                            }
                            Button("Cancel", role: .cancel) {
                                roomForOptions = nil
                            }
                        } message: { room in
                            Text("What would you like to do with '\(room.name)'?")
                        }
                        .alert("Clear Chat?", isPresented: $showClearChatConfirmAlert, presenting: roomToClear) { room in
                            Button("Cancel", role: .cancel) { roomToClear = nil }
                            Button("Clear", role: .destructive) {
                                clearRoomChat(room)
                            }
                        } message: { room in
                            Text("Are you sure you want to clear all messages in '\(room.name)'? This action cannot be undone.")
                        }
                        .alert("Delete Room?", isPresented: $showDeleteConfirmAlert, presenting: roomToDelete) { room in
                            Button("Cancel", role: .cancel) { roomToDelete = nil }
                            Button("Delete", role: .destructive) {
                                deleteRoom(room)
                            }
                        } message: { room in
                            Text("Are you sure you want to delete '\(room.name)'? All messages in this room will be permanently lost.")
                        }
                    if let activeRoom = selectedRoom {
                        activeChatRoomView(partner: partner, room: activeRoom)
                            .transition(.move(edge: .trailing))
                    }
                }
            } else {
                notConnectedView
            }
        }
        .toolbar(selectedRoom != nil ? .hidden : .visible, for: .tabBar)
        .onChange(of: selectedRoom) { oldValue, newValue in
            auth.selectedChatRoom = newValue
            auth.activeRoomId = newValue?.id
            self.replyMessage = nil
            if let activeRoom = newValue {

                // Reset unread counter locally upon entering the room
                if let index = chatRooms.firstIndex(where: { $0.id == activeRoom.id }) {
                    chatRooms[index].unread_count = 0
                    auth.chatRooms = chatRooms
                    auth.updateUnreadCount()
                    // Sync theme from latest API data into selectedRoom so it's always fresh
                    selectedRoom = chatRooms[index]
                }
                
                // Load starred & pinned message IDs for this room from local storage
                let roomKey = activeRoom.id
                let starredKey = "glimpse_starred_messages_room_\(roomKey)"
                let pinnedKey = "glimpse_pinned_messages_room_\(roomKey)"
                starredMessageIds = Set(UserDefaults.standard.array(forKey: starredKey) as? [Int] ?? [])
                pinnedMessageIds = Set(UserDefaults.standard.array(forKey: pinnedKey) as? [Int] ?? [])
                
                // Load per-room baseline unread message ID
                let currentUserId = auth.currentUser?.id ?? 0
                let userDefaultsKey = "last_read_message_id_\(currentUserId)_room_\(activeRoom.id)"
                let storedId = UserDefaults.standard.integer(forKey: userDefaultsKey)
                self.roomInitialLastReadId = storedId > 0 ? storedId : (auth.currentUser?.last_seen_message_id ?? 0)
                
                // Sync read status to server using the latest cached room message
                if let lastMsg = (messagesCache[activeRoom.id] ?? auth.roomMessagesCache[activeRoom.id] ?? []).last, lastMsg.id > 0 {
                    Task {
                        await auth.markMessagesAsRead(messageId: lastMsg.id)
                    }
                }
            } else {
                // Leaving the room: save final read state sweep to prevent badges from reappearing
                if let oldRoom = oldValue, let lastMsg = messages.last, lastMsg.id > 0 {
                    let currentUserId = auth.currentUser?.id ?? 0
                    let userDefaultsKey = "last_read_message_id_\(currentUserId)_room_\(oldRoom.id)"
                    UserDefaults.standard.set(lastMsg.id, forKey: userDefaultsKey)
                    Task {
                        await auth.markMessagesAsRead(messageId: lastMsg.id)
                    }
                }
                
                // Clear messages to trigger clean load next time
                self.messages = []
                self.pendingMessages = []
                
                // Clear the divider baseline when leaving the room
                self.roomInitialLastReadId = nil
                
                // Clear search state when exiting the active chat room
                self.isSearchingChat = false
                self.searchQuery = ""
                self.isInsideChatSearchFocused = false
            }
        }
        .onAppear {
            pinnedRoomIds = Set(UserDefaults.standard.array(forKey: "glimpse_pinned_room_ids") as? [Int] ?? [])
            loadChatRooms()
            if selectedRoom != nil {
                loadMessagesForSelectedRoom()
            }
            auth.pushCurrentStatus()
        }
        .sheet(isPresented: $showRoomDetailsSheet) {
            roomDetailsSheetContent()
        }
        // WebSocket synchronization for chat rooms
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlimpseChatRoomCreated"))) { notification in
            self.handleChatRoomCreated(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlimpseChatRoomDeleted"))) { notification in
            self.handleChatRoomDeleted(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlimpseChatRoomUpdated"))) { notification in
            self.handleChatRoomUpdated(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlimpseChatRoomDeleteStatusChanged"))) { notification in
            self.handleChatRoomDeleteStatusChanged(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlimpseChatRoomThemeUpdated"))) { notification in
            self.handleChatRoomThemeUpdated(notification)
        }
        // Listen to live WebSocket message broadcasts from Partner
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlimpseChatMessageReceived"))) { notification in
            self.handleChatMessageReceived(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowCreateChatRoom"))) { _ in
            newRoomName = ""
            showCreateRoomAlert = true
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
        .alert("Rename Chat Room", isPresented: $showRenameRoomAlert, presenting: roomToRename) { room in
            TextField("Room name", text: $renameRoomName)
            Button("Cancel", role: .cancel) {
                roomToRename = nil
                renameRoomName = ""
            }
            Button("Rename") {
                renameRoom(_: room)
            }
        } message: { room in
            Text("Enter a new name for '\(room.name)'.")
        }
        .alert("No Internet Connection", isPresented: $showNoInternetAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No internet connection. Please connect to the internet and try again.")
        }
        .onChange(of: searchQuery) { oldValue, newValue in
            debouncedSearchQuery = newValue
            updateLocalSearchMatches()
        }
    }
    
    // --- 💬 ACTIVE CHAT ROOM SCREEN (Type-safety separated) ---
    @ViewBuilder
    private func activeChatRoomView(partner: GlimpseUser, room: GlimpseChatRoom) -> some View {
        ZStack(alignment: .leading) {
            // Main Chat Room Content
            ZStack(alignment: .top) {
                // Solid Velvet Background to cover the list behind it completely
                ZStack {
                    activeRoomBgColor.ignoresSafeArea()
                    iOS26Background().opacity(0.4)
                }
                .ignoresSafeArea()
                .ignoresSafeArea(.keyboard)
                
                ScrollViewReader { proxy in
                    ZStack(alignment: .bottomTrailing) {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                Spacer().frame(height: isSearchingChat ? 165 : 110)
                                
                            VStack(spacing: 0) {
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
                                            
                                            chatBubble(msg: msg, scrollProxy: proxy)
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
                                    
                                    ForEach(pendingMessages) { msg in
                                        chatBubble(msg: msg, isPending: true)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, -8)
                                .frame(maxWidth: .infinity)
                                
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom_anchor")
                                    .background(
                                        GeometryReader { geo in
                                            let frame = geo.frame(in: .global)
                                            Color.clear
                                                .onChange(of: frame.minY) { _, newValue in
                                                    guard newValue > 0 else { return }
                                                    let screenHeight = UIScreen.main.bounds.height
                                                    let isOff = newValue > (screenHeight + 300)
                                                    if isShowingScrollToBottomButton != isOff {
                                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                                            isShowingScrollToBottomButton = isOff
                                                        }
                                                    }
                                                }
                                        }
                                    )
                            }
                            .background(
                                Color.black.opacity(0.001)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        isInputFocused = false
                                        if isSearchingChat {
                                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                                isSearchingChat = false
                                                searchQuery = ""
                                            }
                                            isInsideChatSearchFocused = false
                                            hideKeyboard()
                                        }
                                    }
                            )
                        }
                        .defaultScrollAnchor(.bottom)
                        .scrollDismissesKeyboard(.interactively)
                        .onAppear {
                            if let highlightId = highlightedMessageId {
                                // Scroll straight to targeted search result message!
                                for delay in [0.05, 0.15, 0.35] {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                        withAnimation(.easeInOut(duration: 0.45)) {
                                            proxy.scrollTo(highlightId, anchor: .center)
                                        }
                                    }
                                }
                                // Auto clear highlight after 2.0s
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        if highlightedMessageId == highlightId {
                                            highlightedMessageId = nil
                                        }
                                    }
                                }
                            } else {
                                // Immediate scroll to bottom on room open
                                self.isShowingScrollToBottomButton = false
                                proxy.scrollTo("bottom_anchor", anchor: .bottom)
                                // Extra delayed scrolls to catch async cache/fetch loads
                                for delay in [0.08, 0.20, 0.40] {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                        self.isShowingScrollToBottomButton = false
                                        proxy.scrollTo("bottom_anchor", anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .safeAreaInset(edge: .bottom) {
                            bottomInputInsetView(proxy: proxy)
                        }
                        .onChange(of: messages) { oldMessages, newMessages in
                            if let highlightId = highlightedMessageId {
                                // Keep highlight scroll target locked, skip bottom anchor scroll
                                for delay in [0.05, 0.15] {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                        withAnimation(.easeInOut(duration: 0.45)) {
                                            proxy.scrollTo(highlightId, anchor: .center)
                                        }
                                    }
                                }
                                return
                            }
                            
                            if oldMessages.isEmpty || oldMessages.count < 3 {
                                // Initial/cache load: scroll instantly to bottom
                                self.isShowingScrollToBottomButton = false
                                proxy.scrollTo("bottom_anchor", anchor: .bottom)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                    self.isShowingScrollToBottomButton = false
                                    proxy.scrollTo("bottom_anchor", anchor: .bottom)
                                }
                                return
                            }
                            
                            if let lastMsg = newMessages.last {
                                let wasMyMessage = lastMsg.sender_id == auth.currentUser?.id
                                
                                // If my message transitioned from pending to sent, skip scrolling to avoid double-scroll jitter!
                                if wasMyMessage {
                                    return
                                }
                                
                                // Scroll smoothly for incoming partner messages with a quick, snappy easeOut animation
                                DispatchQueue.main.async {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        proxy.scrollTo("bottom_anchor", anchor: .bottom)
                                    }
                                }
                                
                                AudioServicesPlaySystemSound(1103)
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            }
                        }
                        .onChange(of: pendingMessages) { oldPending, newPending in
                            // Snappy layout sync when adding pending messages
                            if newPending.count > oldPending.count {
                                DispatchQueue.main.async {
                                    proxy.scrollTo("bottom_anchor", anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: auth.isPartnerTyping) { _, isTyping in
                            if isTyping {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        proxy.scrollTo("bottom_anchor", anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .onChange(of: isInputFocused) { _, isFocused in
                            if isFocused {
                                // Scroll to bottom when keyboard appears — use keyboard animation duration
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    proxy.scrollTo("bottom_anchor", anchor: .bottom)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    withAnimation(.easeOut(duration: 0.18)) {
                                        proxy.scrollTo("bottom_anchor", anchor: .bottom)
                                    }
                                }
                                if !messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    auth.sendTypingStatus(isTyping: true)
                                }
                            } else {
                                auth.sendTypingStatus(isTyping: false)
                            }
                        }
                        .onChange(of: triggerJumpToDate) { _, newValue in
                            if newValue {
                                triggerJumpToDate = false
                                jumpToDate(jumpToDateValue, proxy: proxy)
                            }
                        }
                        .onChange(of: scrollToMessageTrigger) { _, newValue in
                            if let targetId = newValue {
                                highlightedMessageId = targetId
                                withAnimation(.easeInOut(duration: 0.45)) {
                                    proxy.scrollTo(targetId, anchor: .center)
                                }
                                
                                // Reset the trigger immediately so it can be re-triggered on next tap
                                scrollToMessageTrigger = nil
                                
                                // Auto clear highlight after 2.0s
                                let highlightId = targetId
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        if highlightedMessageId == highlightId {
                                            highlightedMessageId = nil
                                        }
                                    }
                                }
                            }
                        }
                        
                        if isShowingScrollToBottomButton {
                            Button {
                                isShowingScrollToBottomButton = false
                                withAnimation(.easeOut(duration: 0.22)) {
                                    proxy.scrollTo("bottom_anchor", anchor: .bottom)
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(activeRoomThemeColor)
                                            .shadow(color: activeRoomThemeColor.opacity(0.6), radius: 8, x: 0, y: 4)
                                    )
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, replyMessage != nil ? 150 : 100)
                        }
                    }
                }
                chatHeader(partner: partner, room: room)
                    .opacity(max(0.0, 1.0 - Double(swipeProgress) * 1.3))
                    .zIndex(10)

            }
            
            // Transparent Left-Edge Swipe Back Interception Zone (width: 42)
            Color.clear
                .frame(width: 42)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 8, coordinateSpace: .global)
                        .onChanged { value in
                            guard value.startLocation.x < 50 else { return }
                            guard value.translation.width > 0 else { return }
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            guard value.startLocation.x < 50 else { return }
                            let screenWidth = UIScreen.main.bounds.width
                            if value.translation.width > 105 {
                                // Dismiss smoothly
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                    dragOffset = screenWidth
                                }
                                // Re-assign selectedRoom to nil after transition finishes
                                // Load from cache instantly if available to prevent 1s blank screen on next tap
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                                        selectedRoom = nil
                                    }
                                    dragOffset = 0
                                    // Don't clear messages — keep auth cache so next entry is instant
                                    messages = []
                                    pendingMessages = []
                                }
                            } else {
                                // Snap back to zero
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                .padding(.top, 100) // Avoid blocking the back button in the header!
        }
        .offset(x: dragOffset)
        .sheet(isPresented: $showDatePickerForJump) {
            ZStack {
                Color.deepVelvet.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    HStack {
                        Text("Jump to Date")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Button("Cancel") {
                            showDatePickerForJump = false
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    DatePicker(
                        "",
                        selection: $jumpToDateValue,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding(.horizontal)
                    
                    Button {
                        showDatePickerForJump = false
                        triggerJumpToDate = true
                    } label: {
                        Text("Jump to Selected Date")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.deepVelvet)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.activeCyan)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: isSearchingChat) { oldValue, newValue in
            if !newValue {
                localSearchMatchIds = []
                localSearchCurrentIndex = -1
                highlightedMessageId = nil
            } else {
                updateLocalSearchMatches()
            }
        }
        .onChange(of: messages) { oldValue, newValue in
            if isSearchingChat {
                updateLocalSearchMatches()
            }
        }
    }
    
    @ViewBuilder
    private func chatRoomsListView(partner: GlimpseUser) -> some View {
        let progress = min(1.0, max(0.0, dragOffset / UIScreen.main.bounds.width))
        let scale: CGFloat = selectedRoom == nil ? 1.0 : (0.96 + (0.04 * progress))
        let opacity: Double = selectedRoom == nil ? 1.0 : (0.8 + (0.2 * Double(progress)))
        
        return ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Header spacer (clears the blurred top header precisely)
                Spacer().frame(height: 104)
                
                // Sleek premium WhatsApp-style search bar
                if !chatRooms.isEmpty {
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.4))
                                .font(.system(size: 14, weight: .bold))
                            
                            TextField("Search rooms or messages...", text: $searchQuery)
                                .focused($isSearchFocused)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            
                            if !searchQuery.isEmpty {
                                Button {
                                    searchQuery = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.4))
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(searchQuery.isEmpty ? Color.clear : Color.activeCyan.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                }
                
                if isLoadingRooms {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(.activeCyan)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if chatRooms.isEmpty {
                    VStack {
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
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            // --- 🔍 SEARCH RESULTS VIEW ---
                            let matchedRooms = sortedChatRooms.filter { $0.name.localizedCaseInsensitiveContains(debouncedSearchQuery) }
                            let matchedMsgs = globalSearchResults
                            
                            if searchQuery != debouncedSearchQuery {
                                VStack(spacing: 16) {
                                    Spacer().frame(height: 40)
                                    ProgressView()
                                        .tint(.activeCyan)
                                        .scaleEffect(1.2)
                                    Text("Searching...")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.4))
                                    Spacer().frame(height: 40)
                                }
                                .frame(maxWidth: .infinity)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            } else if matchedRooms.isEmpty && matchedMsgs.isEmpty {
                                VStack(spacing: 12) {
                                    Spacer().frame(height: 40)
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.15))
                                    Text("No results found for \"\(searchQuery)\"")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("Try searching for a different keyword or room name.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.25))
                                        .multilineTextAlignment(.center)
                                    Spacer().frame(height: 40)
                                }
                                .frame(maxWidth: .infinity)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            } else {
                                if !matchedRooms.isEmpty {
                                    Section(header: Text("Rooms").font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.4))) {
                                        ForEach(matchedRooms) { room in
                                            roomRow(room)
                                                .listRowBackground(Color.clear)
                                                .listRowSeparator(.hidden)
                                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                                .onTapGesture {
                                                    openRoomDirectly(room)
                                                }
                                        }
                                    }
                                }
                                
                                if !matchedMsgs.isEmpty {
                                    Section(header: Text("Messages").font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.4))) {
                                        ForEach(matchedMsgs) { result in
                                            searchMessageRow(result)
                                                .listRowBackground(Color.clear)
                                                .listRowSeparator(.hidden)
                                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                                .onTapGesture {
                                                    highlightedMessageId = result.message.id
                                                    openRoomDirectly(result.room)
                                                }
                                        }
                                    }
                                }
                            }
                        } else {
                            // --- 💬 STANDARD ROOMS LIST ---
                            ForEach(sortedChatRooms) { room in
                                roomRow(room)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                    .onTapGesture {
                                        openRoomDirectly(room)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        let isCurrentUserRequesting = room.delete_requested_by == auth.currentUser?.id
                                        let isPartnerRequesting = room.delete_requested_by != nil && !isCurrentUserRequesting
                                        
                                        Button(role: room.is_main ? .none : .destructive) {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            if room.is_main {
                                                if isCurrentUserRequesting {
                                                    roomToDeleteRequest = room
                                                    showPendingDeleteRequestAlert = true
                                                } else if isPartnerRequesting {
                                                    roomToRespondDelete = room
                                                    showRespondDeleteRequestAlert = true
                                                } else {
                                                    roomToRequestDelete = room
                                                    showRequestDeleteAlert = true
                                                }
                                                return
                                            }
                                            roomForOptions = room
                                            showRoomOptionsDialog = true
                                        } label: {
                                            if room.is_main {
                                                if isCurrentUserRequesting {
                                                    Label("Pending", systemImage: "clock.badge.exclamationmark.fill")
                                                } else if isPartnerRequesting {
                                                    Label("Review", systemImage: "checkmark.circle.fill")
                                                } else {
                                                    Label("Clear Chat", systemImage: "trash.fill")
                                                }
                                            } else {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
                                        }
                                        .tint(room.is_main ? (isCurrentUserRequesting ? .orange : (isPartnerRequesting ? .activeCyan : .red)) : .red)
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        let isPinned = pinnedRoomIds.contains(room.id)
                                        Button {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            togglePinRoom(room)
                                        } label: {
                                            Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash.fill" : "pin.fill")
                                        }
                                        .tint(.orange)
                                        
                                        Button {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            roomToRename = room
                                            renameRoomName = room.name
                                            showRenameRoomAlert = true
                                        } label: {
                                            Label("Rename", systemImage: "square.and.pencil")
                                        }
                                        .tint(.blue)
                                    }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollDismissesKeyboard(.interactively)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            isSearchFocused = false
                            hideKeyboard()
                        }
                    )
                }
            }
            .ignoresSafeArea(edges: .top)
            .scaleEffect(scale, anchor: .top)
            .opacity(opacity)
            
            roomsListHeader(partner: partner)
                .opacity(selectedRoom == nil ? 1.0 : Double(swipeProgress))
                .zIndex(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func openRoomDirectly(_ room: GlimpseChatRoom) {
        isSearchFocused = false
        isInsideChatSearchFocused = false
        hideKeyboard()
        if let authCached = auth.roomMessagesCache[room.id], !authCached.isEmpty {
            self.messages = authCached
            self.messagesCache[room.id] = authCached
        } else if let cached = messagesCache[room.id], !cached.isEmpty {
            self.messages = cached
        } else {
            self.messages = []
        }
        pendingMessages = []
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedRoom = room
        }
        loadMessagesForSelectedRoom()
    }
    
    private func openRoomAndHighlightMessage(room: GlimpseChatRoom, message: ChatMessage) {
        isSearchFocused = false
        isInsideChatSearchFocused = false
        hideKeyboard()
        var cachedMsgs = messagesCache[room.id] ?? auth.roomMessagesCache[room.id] ?? []
        if !cachedMsgs.contains(where: { $0.id == message.id }) {
            cachedMsgs.append(message)
            cachedMsgs.sort { $0.id < $1.id }
        }
        
        self.messages = cachedMsgs
        self.messagesCache[room.id] = cachedMsgs
        self.auth.roomMessagesCache[room.id] = cachedMsgs
        
        pendingMessages = []
        highlightedMessageId = message.id
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedRoom = room
        }
        loadMessagesForSelectedRoom()
    }
    
    @ViewBuilder
    private func searchMessageRow(_ result: GlobalSearchResult) -> some View {
        let isMe = result.message.sender_id == auth.currentUser?.id
        let senderName = isMe ? "You" : (auth.partner?.name ?? "Partner")
        let timeStr = formatMessageTime(result.message.created_at)
        
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.activeCyan.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.activeCyan)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(senderName) in \(result.room.name)")
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timeStr)
                        .font(.system(size: 10.5))
                        .foregroundColor(.white.opacity(0.35))
                }
                
                Text(result.message.cleanDisplayContent)
                    .font(.system(size: 12.5))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
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
    private func bottomInputInsetView(proxy: ScrollViewProxy) -> some View {
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
            
            if isSearchingChat {
                searchNavigationPanel(proxy: proxy)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
            } else {
                if let reply = replyMessage {
                    // Reply Preview Bar right above input field
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            let senderName = reply.sender_id == auth.currentUser?.id ? "You" : (auth.partner?.name ?? "Partner")
                            Text("Replying to \(senderName)")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(.activeCyan)
                            let displayParent = reply.replyInfo?.actualMessage ?? reply.message
                            Text(displayParent)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))
                                .lineLimit(1)
                        }
                        .padding(.leading, 12)
                        .overlay(
                            HStack {
                                Rectangle()
                                    .fill(Color.activeCyan)
                                    .frame(width: 3.5)
                                Spacer()
                            }
                        )
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                replyMessage = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.trailing, 12)
                    }
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                floatingInputBar(proxy: proxy)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
            }
        }
        .background(
            Color.white.opacity(0.01)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func roomsListHeader(partner: GlimpseUser) -> some View {
        Color.clear
            .frame(height: 95)
            .background(
                Color.white.opacity(0.01)
                    .background(.ultraThinMaterial)
            )
            .ignoresSafeArea(edges: .top)
    }
    
    private func roomRow(_ room: GlimpseChatRoom) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Room Icon Container
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: room.is_main ? [.activeCyan.opacity(0.2), .activeCyan.opacity(0.05)] : [.white.opacity(0.08), .white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: room.is_main ? "star.bubble.fill" : "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 19))
                        .foregroundColor(room.is_main ? .activeCyan : .white.opacity(0.8))
                }
                .overlay(
                    Circle()
                        .stroke(room.is_main ? Color.activeCyan.opacity(0.25) : Color.white.opacity(0.08), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(room.name)
                            .font(.system(size: 16, weight: room.unread_count > 0 ? .bold : .semibold))
                            .foregroundColor(room.unread_count > 0 ? .white : .white.opacity(0.9))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let latest = room.latest_message, let rawTime = latest.created_at {
                            Text(formatMessageTime(rawTime))
                                .font(.system(size: 11, weight: room.unread_count > 0 ? .semibold : .regular))
                                .foregroundColor(room.unread_count > 0 ? .activeCyan : .white.opacity(0.4))
                        }
                    }
                    
                    HStack {
                        if let latest = room.latest_message {
                            let senderName = latest.sender_id == auth.currentUser?.id ? "You: " : ""
                            Text("\(senderName)\(latest.cleanDisplayContent)")
                                .font(.system(size: 13, weight: room.unread_count > 0 ? .medium : .regular))
                                .foregroundColor(room.unread_count > 0 ? .white.opacity(0.85) : .white.opacity(0.55))
                                .lineLimit(1)
                        } else {
                            Text("No messages yet")
                                .font(.system(size: 12.5))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        
                        Spacer()
                        
                        if pinnedRoomIds.contains(room.id) {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange.opacity(0.85))
                                .rotationEffect(.degrees(45))
                        }
                        
                        if room.unread_count > 0 {
                            Text("\(room.unread_count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black) // High contrast solid black text!
                                .frame(width: 18, height: 18)
                                .background(Circle().fill(Color.activeCyan))
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear) // Clean and transparent, no glowing background color
            )
            .contentShape(Rectangle())
            
            // Telegram/WhatsApp Style thin divider line below each row
            Divider()
                .background(Color.white.opacity(0.06))
                .padding(.leading, 68)
        }
    }
    
    @ViewBuilder
    private func pinnedMessageBanner(_ msg: ChatMessage) -> some View {
        let displayText = msg.replyInfo?.actualMessage ?? msg.message
        Button {
            // Scroll to pinned message and glow
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            scrollToMessageTrigger = msg.id
        } label: {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(activeRoomThemeColor)
                    .frame(width: 3, height: 34)
                    .cornerRadius(2)

                Image(systemName: "pin.fill")
                    .font(.system(size: 12))
                    .foregroundColor(activeRoomThemeColor)
                    .rotationEffect(.degrees(45))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pinned Message")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(activeRoomThemeColor)
                    Text(displayText)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeOut(duration: 0.25)) {
                        let roomId = selectedRoom?.id ?? 0
                        let pinnedKey = "glimpse_pinned_messages_room_\(roomId)"
                        pinnedMessageIds.remove(msg.id)
                        UserDefaults.standard.set(Array(pinnedMessageIds), forKey: pinnedKey)
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(Color.black.opacity(0.15))
                    .overlay(
                        Rectangle()
                            .fill(activeRoomThemeColor.opacity(0.05))
                    )
            )
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    @ViewBuilder
    private func roomDetailsSheetContent() -> some View {
        if let room = selectedRoom, let partner = auth.partner {
            ChatRoomDetailsSheet(
                room: room,
                partner: partner,
                chatTextSize: $chatTextSize,
                starredMessageIds: starredMessageIds,
                messages: messages,
                currentUserId: auth.currentUser?.id ?? 0,
                apiBaseURL: auth.baseURL,
                myLatitude: auth.currentUser?.latitude,
                myLongitude: auth.currentUser?.longitude,
                onThemeUpdate: { themeColor, bgColor in
                    applyRoomTheme(room: room, themeColor: themeColor, bgColor: bgColor)
                },
                onScrollToStarred: { _ in
                    showRoomDetailsSheet = false
                },
                onRenameRoom: { newName in
                    renameRoomName = newName
                    renameRoom(room)
                }
            )
        }
    }

    private func applyRoomTheme(room: GlimpseChatRoom, themeColor: String?, bgColor: String?) {
        let roomId = room.id
        if let idx = chatRooms.firstIndex(where: { $0.id == roomId }) {
            chatRooms[idx].theme_color = themeColor
            chatRooms[idx].background_color = bgColor
        }
        var updatedRoom = room
        updatedRoom.theme_color = themeColor
        updatedRoom.background_color = bgColor
        selectedRoom = updatedRoom
        Task {
            try? await auth.updateChatRoomTheme(
                roomId: roomId,
                themeColor: themeColor,
                backgroundColor: bgColor
            )
        }
    }

    private func chatHeader(partner: GlimpseUser, room: GlimpseChatRoom) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedRoom = nil
                    }
                    self.messages = [] // Instantly clear messages on exit
                    loadChatRooms()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: formattedUrl(partner.profile_photo_url))) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.white.opacity(0.1)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(activeRoomThemeColor.opacity(0.3), lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(room.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Circle()
                                .fill(partner.isOffline ? Color.gray : Color.green)
                                .frame(width: 5, height: 5)
                        }
                        
                        HStack(spacing: 6) {
                            Text(partner.isOffline ? partner.timeAgoString : "Online")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.3))
                            
                            HStack(spacing: 2) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 9))
                                Text(partner.location_name ?? "Unknown")
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                            }
                            .foregroundColor(activeRoomThemeColor.opacity(0.8))
                            
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.3))
                            
                            HStack(spacing: 2) {
                                Image(systemName: partner.is_charging == true ? "battery.100.bolt" : "battery.75")
                                    .font(.system(size: 10))
                                Text("\(partner.battery_level ?? 100)%")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showRoomDetailsSheet = true
                }
                
                Spacer()
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isSearchingChat.toggle()
                        if !isSearchingChat {
                            searchQuery = ""
                            isInsideChatSearchFocused = false
                        } else {
                            // Automatically focus the search text field when opened
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isInsideChatSearchFocused = true
                            }
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
                            .focused($isInsideChatSearchFocused)
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
            
            if let deleteRequestedBy = room.delete_requested_by {
                let isCurrentUser = deleteRequestedBy == auth.currentUser?.id
                
                HStack(spacing: 12) {
                    Image(systemName: isCurrentUser ? "clock.arrow.circlepath" : "exclamationmark.triangle.fill")
                        .foregroundColor(isCurrentUser ? .orange : .red)
                        .font(.system(size: 14, weight: .bold))
                    
                    Text(isCurrentUser ? "Clear chat request pending..." : "Partner requested to clear chat history")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if isCurrentUser {
                        Button {
                            declineDeleteRoom(room)
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(8)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Button {
                                declineDeleteRoom(room)
                            } label: {
                                Text("Decline")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.red.opacity(0.4), lineWidth: 1)
                                    )
                            }
                            
                            Button {
                                confirmDeleteRoom(room)
                            } label: {
                                Text("Clear")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(Color.activeCyan)
                                    .cornerRadius(6)
                                    .shadow(color: Color.activeCyan.opacity(0.4), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isCurrentUser ? Color.orange.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // WhatsApp-style Pinned Message Banner (directly below header)
            if !pinnedMessageIds.isEmpty, let pinnedMsg = messages.first(where: { pinnedMessageIds.contains($0.id) }) {
                pinnedMessageBanner(pinnedMsg)
            }
        }
        .background(
            Color.white.opacity(0.01)
                .background(.ultraThinMaterial)
        )
        .ignoresSafeArea(edges: .top)
    }
    
    // FLOATING MESSAGE INPUT BAR (Fully floating, glassmorphic, separate rounded capsule and button)
    private func floatingInputBar(proxy: ScrollViewProxy) -> some View {
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
                sendMessage(scrollProxy: proxy)
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.deepVelvet)
                    .frame(width: 44, height: 44)
                    .background(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white.opacity(0.3) : activeRoomThemeColor)
                    .clipShape(Circle())
                    .shadow(color: messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.clear : activeRoomThemeColor.opacity(0.3), radius: 8, y: 3)
            }
            .disabled(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    private func bubbleBackground(isMe: Bool) -> Color {
        if isMe {
            return Color.activeCyan.opacity(0.18)
        } else {
            return Color.white.opacity(0.08)
        }
    }

    @ViewBuilder
    private func flashAttachmentBubble(msg: ChatMessage, isMe: Bool, timeStr: String, corners: UIRectCorner) -> some View {
        let glow = getGlowProperties(msg: msg, isMe: isMe, isHighlighted: false)
        
        return Button {
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
                    .stroke(glow.strokeColor, lineWidth: glow.strokeWidth)
            )
            .scaleEffect(glow.scale)
            .shadow(color: glow.glowColor, radius: glow.glowRadius, y: 3)
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlySentMessageIds.contains(msg.id))
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlyReceivedMessageIds.contains(msg.id))
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func kencanInvitationBubble(msg: ChatMessage, isMe: Bool, timeStr: String, corners: UIRectCorner) -> some View {
        let glow = getGlowProperties(msg: msg, isMe: isMe, isHighlighted: false)
        
        return Button {
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
                    .stroke(glow.strokeColor, lineWidth: glow.strokeWidth)
            )
            .scaleEffect(glow.scale)
            .shadow(color: glow.glowColor, radius: glow.glowRadius, y: 3)
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlySentMessageIds.contains(msg.id))
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlyReceivedMessageIds.contains(msg.id))
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func standardTextChatBubble(msg: ChatMessage, isMe: Bool, isPending: Bool, timeStr: String, corners: UIRectCorner, scrollProxy: ScrollViewProxy?, isHighlighted: Bool) -> some View {
        let glow = getGlowProperties(msg: msg, isMe: isMe, isHighlighted: isHighlighted)
        let displayText = msg.replyInfo?.actualMessage ?? msg.message
        let isShort = displayText.count < 35 && !displayText.contains("\n") && msg.replyInfo == nil && !displayText.containsURL
        
        return Group {
            if isShort {
                HStack(alignment: .bottom, spacing: 8) {
                    LinkedTextView(text: displayText, fontSize: chatTextSize, foregroundColor: .white)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 3) {
                        if starredMessageIds.contains(msg.id) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8.0))
                                .foregroundColor(.yellow)
                        }
                        
                        if !timeStr.isEmpty {
                            Text(timeStr)
                                .font(.system(size: 8.0, weight: .medium))
                                .foregroundColor(isMe ? activeRoomThemeColor.opacity(0.65) : .white.opacity(0.4))
                        }
                        
                        if isPending {
                            Image(systemName: "clock")
                                .font(.system(size: 8.0))
                                .foregroundColor(isMe ? activeRoomThemeColor.opacity(0.65) : .white.opacity(0.4))
                        }
                    }
                    .padding(.bottom, 0.5)
                }
            } else {
                VStack(alignment: .trailing, spacing: 4) {
                    if let reply = msg.replyInfo {
                        Button {
                            if let proxy = scrollProxy {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.45)) {
                                    proxy.scrollTo(reply.parentId, anchor: .center)
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    highlightedMessageId = reply.parentId
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        if highlightedMessageId == reply.parentId {
                                            highlightedMessageId = nil
                                        }
                                    }
                                }
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(reply.senderName)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(activeRoomThemeColor)
                                Text(reply.parentMessage)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.65))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 8)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                            .overlay(
                                HStack {
                                    Rectangle()
                                        .fill(activeRoomThemeColor)
                                        .frame(width: 3)
                                    Spacer()
                                }
                            )
                            .padding(.bottom, 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    LinkedTextView(text: displayText, fontSize: chatTextSize, foregroundColor: .white)
                        .multilineTextAlignment(.leading)

                    // Link preview card
                    if let url = displayText.firstURL {
                        ChatLinkPreviewCard(url: url, themeColor: activeRoomThemeColor)
                            .padding(.top, 2)
                    }
                    
                    HStack(spacing: 3) {
                        if starredMessageIds.contains(msg.id) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8.0))
                                .foregroundColor(.yellow)
                        }
                        
                        if !timeStr.isEmpty {
                            Text(timeStr)
                                .font(.system(size: 8.0, weight: .medium))
                                .foregroundColor(isMe ? activeRoomThemeColor.opacity(0.65) : .white.opacity(0.4))
                        }
                        
                        if isPending {
                            Image(systemName: "clock")
                                .font(.system(size: 8.0))
                                .foregroundColor(isMe ? activeRoomThemeColor.opacity(0.65) : .white.opacity(0.4))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5.5)
        .background(isHighlighted ? activeRoomThemeColor.opacity(0.35) : bubbleBackground(isMe: isMe))
        .clipShape(RoundedCorner(radius: 12, corners: corners))
        .overlay(
            RoundedCorner(radius: 12, corners: corners)
                .stroke(glow.strokeColor, lineWidth: glow.strokeWidth)
        )
        .scaleEffect(glow.scale)
        .shadow(color: glow.glowColor, radius: glow.glowRadius, y: 2)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlySentMessageIds.contains(msg.id))
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlyReceivedMessageIds.contains(msg.id))
    }
    
    // WHATSAPP STYLE CHAT BUBBLES WITH INDIVIDUAL TIME STAMPS & SWIPE TO REPLY
    private func chatBubble(msg: ChatMessage, isPending: Bool = false, scrollProxy: ScrollViewProxy? = nil) -> some View {
        let isMe = msg.sender_id == auth.currentUser?.id
        let isHighlighted = highlightedMessageId == msg.id
        let corners: UIRectCorner = isMe ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]
        let timeStr = formatMessageTime(msg.created_at)
        
        return VStack(alignment: .trailing, spacing: 2) {
            HStack {
                if isMe {
                    Spacer()
                }
                
                SwipeableBubbleView(msg: msg, isMe: isMe, onReplyTriggered: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        replyMessage = msg
                    }
                }) {
                    Group {
                        if msg.message.contains("[FLASH_ATTACHMENT]") {
                            flashAttachmentBubble(msg: msg, isMe: isMe, timeStr: timeStr, corners: corners)
                        } else if msg.message.contains("[KENCAN_INVITATION]") {
                            kencanInvitationBubble(msg: msg, isMe: isMe, timeStr: timeStr, corners: corners)
                        } else {
                            standardTextChatBubble(msg: msg, isMe: isMe, isPending: isPending, timeStr: timeStr, corners: corners, scrollProxy: scrollProxy, isHighlighted: isHighlighted)
                        }
                    }
                }
                .contextMenu {
                    Button {
                        toggleStarMessage(msg)
                    } label: {
                        Label(starredMessageIds.contains(msg.id) ? "Unstar" : "Star", systemImage: starredMessageIds.contains(msg.id) ? "star.slash" : "star")
                    }

                    Button {
                        togglePinMessage(msg)
                    } label: {
                        Label(pinnedMessageIds.contains(msg.id) ? "Unpin" : "Pin", systemImage: pinnedMessageIds.contains(msg.id) ? "pin.slash" : "pin")
                    }

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            replyMessage = msg
                        }
                    } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                    }

                    Button {
                        copyMessageToClipboard(msg)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
                
                if !isMe {
                    Spacer()
                }
            }
            
            let isLatestSeen = isMe && msg.id == messages.last(where: {
                $0.sender_id == (auth.currentUser?.id ?? 0) &&
                $0.id <= (auth.partner?.last_seen_message_id ?? 0)
            })?.id
            
            if isLatestSeen {
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
        guard !dateStr.isEmpty else { return AnyView(EmptyView()) }
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
        
        let roomId = selectedRoom?.id
        
        // 1. Load from SQLite database (or memory cache) transparently
        let cached = auth.getCachedMessages(for: roomId)
        self.messages = cached
        if let rId = roomId {
            self.messagesCache[rId] = cached
        }
        
        // 2. Fetch fresh from server, MERGE with local state
        Task { @MainActor in
            if let serverMsgs = try? await auth.fetchMessages(roomId: roomId) {
                let localMsgs = self.messagesCache[roomId ?? 0] ?? self.messages
                var merged = serverMsgs
                for localMsg in localMsgs {
                    if localMsg.id > 0 && !merged.contains(where: { $0.id == localMsg.id }) {
                        merged.append(localMsg)
                    }
                }
                merged.sort { $0.id < $1.id }
                self.messages = merged
                self.messagesCache[roomId ?? 0] = merged
                // Also sync back to auth-level cache
                if let rId = roomId {
                    auth.roomMessagesCache[rId] = merged
                }
            }
        }
    }
    
    private func loadChatRooms() {
        guard auth.partner != nil && auth.coupleActive else { return }
        
        // Stale-While-Revalidate: load memory cache instantly
        if !auth.chatRooms.isEmpty {
            self.chatRooms = auth.chatRooms
            self.isLoadingRooms = false
        } else {
            self.isLoadingRooms = true
        }
        
        Task { @MainActor in
            do {
                var rooms = try await auth.fetchChatRooms()
                
                // Bulletproof race-condition protection: override unread count if latest message is already read locally
                let currentUserId = auth.currentUser?.id ?? 0
                for i in 0..<rooms.count {
                    let r = rooms[i]
                    let userDefaultsKey = "last_read_message_id_\(currentUserId)_room_\(r.id)"
                    let storedId = UserDefaults.standard.integer(forKey: userDefaultsKey)
                    if let latestId = r.latest_message?.id, latestId > 0 && latestId <= storedId {
                        rooms[i].unread_count = 0
                    }
                    
                    if let activeRoom = selectedRoom, r.id == activeRoom.id {
                        rooms[i].unread_count = 0
                    }
                }
                
                self.chatRooms = rooms
                self.auth.chatRooms = rooms
                self.isLoadingRooms = false
                auth.updateUnreadCount()
            } catch {
                print("❌ Failed to load chat rooms: \(error)")
                self.isLoadingRooms = false
            }
        }
    }
    
    private func loadMessagesForSelectedRoom() {
        guard let activeRoom = selectedRoom else { return }
        
        // Show auth-level persistent cache instantly (survives tab switching)
        if let authCached = auth.roomMessagesCache[activeRoom.id], !authCached.isEmpty {
            self.messages = authCached
            self.messagesCache[activeRoom.id] = authCached
        }
        
        Task { @MainActor in
            do {
                let msgs = try await auth.fetchMessages(roomId: activeRoom.id)
                // Merge with any locally-added messages to avoid losing them
                var merged = msgs
                let localMsgs = self.messagesCache[activeRoom.id] ?? []
                for localMsg in localMsgs {
                    if localMsg.id > 0 && !merged.contains(where: { $0.id == localMsg.id }) {
                        merged.append(localMsg)
                    }
                }
                merged.sort { $0.id < $1.id }
                self.messages = merged
                self.messagesCache[activeRoom.id] = merged
                auth.roomMessagesCache[activeRoom.id] = merged
                // Reset unread counter locally upon entering the room
                if let index = chatRooms.firstIndex(where: { $0.id == activeRoom.id }) {
                    chatRooms[index].unread_count = 0
                    auth.chatRooms = chatRooms
                    auth.updateUnreadCount()
                }
                
                // Sync read status to server up to the latest fetched message
                if let lastMsg = merged.last, lastMsg.id > 0 {
                    Task {
                        await auth.markMessagesAsRead(messageId: lastMsg.id)
                        
                        // Persist last read message ID for this room session
                        let currentUserId = auth.currentUser?.id ?? 0
                        let userDefaultsKey = "last_read_message_id_\(currentUserId)_room_\(activeRoom.id)"
                        UserDefaults.standard.set(lastMsg.id, forKey: userDefaultsKey)
                    }
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
                    if !self.chatRooms.contains(where: { $0.id == newRoom.id }) {
                        self.chatRooms.append(newRoom)
                        auth.chatRooms = self.chatRooms
                        auth.updateUnreadCount()
                    }
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

    private func clearRoomChat(_ room: GlimpseChatRoom) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { @MainActor in
            do {
                try await auth.clearChatRoom(roomId: room.id)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    // Update cache for this room to empty array
                    self.messagesCache[room.id] = []
                    self.auth.roomMessagesCache[room.id] = []
                    // Clear active messages if this room is currently selected
                    if selectedRoom?.id == room.id {
                        self.messages = []
                    }
                    
                    // Reset the latest_message in chatRooms list
                    if let idx = self.chatRooms.firstIndex(where: { $0.id == room.id }) {
                        self.chatRooms[idx].latest_message = nil
                        self.chatRooms[idx].unread_count = 0
                        self.auth.chatRooms = self.chatRooms
                        self.auth.updateUnreadCount()
                    }
                }
                roomToClear = nil
            } catch {
                print("❌ Failed to clear chat room: \(error)")
            }
        }
    }

    private func requestDeleteRoom(_ room: GlimpseChatRoom) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { @MainActor in
            do {
                try await auth.requestDeleteChatRoom(roomId: room.id)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    for i in 0..<chatRooms.count {
                        if chatRooms[i].id == room.id {
                            chatRooms[i].delete_requested_by = auth.currentUser?.id
                        }
                    }
                    auth.chatRooms = chatRooms
                    
                    if selectedRoom?.id == room.id {
                        selectedRoom?.delete_requested_by = auth.currentUser?.id
                    }
                }
                roomToRequestDelete = nil
            } catch {
                print("❌ Failed to request room deletion: \(error)")
            }
        }
    }

    private func declineDeleteRoom(_ room: GlimpseChatRoom) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { @MainActor in
            do {
                try await auth.declineDeleteChatRoom(roomId: room.id)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    for i in 0..<chatRooms.count {
                        if chatRooms[i].id == room.id {
                            chatRooms[i].delete_requested_by = nil
                        }
                    }
                    auth.chatRooms = chatRooms
                    
                    if selectedRoom?.id == room.id {
                        selectedRoom?.delete_requested_by = nil
                    }
                }
                roomToRespondDelete = nil
                roomToDeleteRequest = nil
            } catch {
                print("❌ Failed to decline room deletion: \(error)")
            }
        }
    }

    private func confirmDeleteRoom(_ room: GlimpseChatRoom) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { @MainActor in
            do {
                try await auth.confirmDeleteChatRoom(roomId: room.id)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if room.is_main {
                        self.messages = []
                        self.messagesCache[room.id] = []
                        auth.roomMessagesCache[room.id] = []
                        
                        for i in 0..<chatRooms.count {
                            if chatRooms[i].id == room.id {
                                chatRooms[i].delete_requested_by = nil
                                chatRooms[i].latest_message = nil
                            }
                        }
                        auth.chatRooms = chatRooms
                        
                        if selectedRoom?.id == room.id {
                            selectedRoom?.delete_requested_by = nil
                            selectedRoom?.latest_message = nil
                        }
                    } else {
                        var filtered: [GlimpseChatRoom] = []
                        for r in self.chatRooms {
                            if r.id != room.id {
                                filtered.append(r)
                            }
                        }
                        self.chatRooms = filtered
                        auth.chatRooms = filtered
                        auth.updateUnreadCount()
                        
                        if selectedRoom?.id == room.id {
                            selectedRoom = nil
                        }
                    }
                }
                roomToRespondDelete = nil
            } catch {
                print("❌ Failed to confirm room deletion: \(error)")
            }
        }
    }

    private func renameRoom(_ room: GlimpseChatRoom) {
        let name = renameRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { @MainActor in
            do {
                try await auth.renameChatRoom(roomId: room.id, newName: name)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    var updatedRooms: [GlimpseChatRoom] = []
                    for var r in self.chatRooms {
                        if r.id == room.id {
                            r.name = name
                        }
                        updatedRooms.append(r)
                    }
                    self.chatRooms = updatedRooms
                    auth.chatRooms = updatedRooms
                }
                roomToRename = nil
                renameRoomName = ""
            } catch {
                print("❌ Failed to rename room: \(error)")
            }
        }
    }
    
    private func togglePinRoom(_ room: GlimpseChatRoom) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // Delay the sorting change slightly to let the swipe action close cleanly first!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                if self.pinnedRoomIds.contains(room.id) {
                    self.pinnedRoomIds.remove(room.id)
                } else {
                    self.pinnedRoomIds.insert(room.id)
                }
                UserDefaults.standard.set(Array(self.pinnedRoomIds), forKey: "glimpse_pinned_room_ids")
            }
        }
    }
    
    private func sendMessage(scrollProxy: ScrollViewProxy? = nil) {
        let cleanText = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        messageInput = ""
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        
        // Instantly clear unread message divider baseline when sending a message
        roomInitialLastReadId = nil
        
        let tempId = Int.random(in: -100000...(-1))
        let formatter = ISO8601DateFormatter()
        let createdAtStr = formatter.string(from: Date())
        
        // Format message with parent reference if replying
        let finalMessage: String
        if let reply = replyMessage {
            let senderName = reply.sender_id == auth.currentUser?.id ? "You" : (auth.partner?.name ?? "Partner")
            let parentMsgText = reply.replyInfo?.actualMessage ?? reply.message
            finalMessage = "{{reply:\(reply.id)|\(senderName)|\(parentMsgText)}}\(cleanText)"
        } else {
            finalMessage = cleanText
        }
        
        // Reset reply state
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            replyMessage = nil
        }
        
        let tempMsg = ChatMessage(
            id: tempId,
            couple_id: auth.currentUser?.couple_id ?? 0,
            sender_id: auth.currentUser?.id ?? 0,
            message: finalMessage,
            room_id: selectedRoom?.id,
            created_at: createdAtStr,
            updated_at: createdAtStr
        )
        
        // Append directly to avoid competing/overlapping spring animations that cause layout shifts
        self.pendingMessages.append(tempMsg)
        
        // Perform an instant snappy scroll to bottom to eliminate any blink or lag
        if let proxy = scrollProxy {
            proxy.scrollTo("bottom_anchor", anchor: .bottom)
        }
        
        Task {
            await attemptSendPendingMessage(tempMsg)
        }
    }
    
    @MainActor
    private func attemptSendPendingMessage(_ msg: ChatMessage) async {
        guard NetworkMonitor.shared.isConnected else { return }
        do {
            // Fix: Use msg.room_id instead of selectedRoom?.id in case user exits the room while sending
            let sentMsg = try await auth.sendChatMessage(text: msg.message, roomId: msg.room_id)
            
            // Play sound only when confirmed sent by server!
            AudioServicesPlaySystemSound(1104)
            
            // Trigger temporary glow for the newly sent message
            let sentId = sentMsg.id
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                self.newlySentMessageIds.insert(sentId)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 1.0)) {
                    _ = self.newlySentMessageIds.remove(sentId)
                }
            }
            
            // Update the pending queue instantly
            var newPending: [ChatMessage] = []
            for p in self.pendingMessages {
                if p.id != msg.id {
                    newPending.append(p)
                }
            }
            self.pendingMessages = newPending
            
            // Sync local cache instantly to prevent sent messages from disappearing!
            let roomIdKey = sentMsg.room_id ?? 0
            var cachedArray = self.messagesCache[roomIdKey] ?? auth.roomMessagesCache[roomIdKey] ?? []
            if !cachedArray.contains(where: { $0.id == sentMsg.id }) {
                cachedArray.append(sentMsg)
                self.messagesCache[roomIdKey] = cachedArray
                // Also write to auth-level persistent cache
                if roomIdKey > 0 {
                    auth.roomMessagesCache[roomIdKey] = cachedArray
                }
            }
            
            // If the user is still viewing the room, update the active messages list
            let isMainActive = selectedRoom?.is_main ?? false
            let isSameRoomActive = selectedRoom?.id == roomIdKey
            if isSameRoomActive || (isMainActive && roomIdKey == 0) {
                self.messages = cachedArray
            }
            
            // Update local room list with the sent message instantly, marking it as read
            if let idx = self.chatRooms.firstIndex(where: { $0.id == roomIdKey || ($0.is_main && roomIdKey == 0) }) {
                var updatedRoom = self.chatRooms[idx]
                updatedRoom.latest_message = RoomLatestMessage(
                    id: sentMsg.id,
                    message: sentMsg.message,
                    sender_id: sentMsg.sender_id,
                    created_at: sentMsg.created_at
                )
                updatedRoom.unread_count = 0 // Sent by self, so auto-seen/read!
                self.chatRooms[idx] = updatedRoom
                self.auth.chatRooms = self.chatRooms
                self.auth.updateUnreadCount()
            }
            
            // Instantly persist in UserDefaults to keep room baseline in sync
            let currentUserId = auth.currentUser?.id ?? 0
            let userDefaultsKey = "last_read_message_id_\(currentUserId)_room_\(roomIdKey)"
            UserDefaults.standard.set(sentMsg.id, forKey: userDefaultsKey)
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
    

    
    private func formattedUrl(_ urlString: String) -> String {
        if urlString.hasPrefix("http") {
            return urlString
        } else {
            let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
            let baseURL = AuthManager.shared.baseURL.replacingOccurrences(of: "/api", with: "")
            return cleanPath.contains("storage/") ? "\(baseURL)/\(cleanPath)" : "\(baseURL)/storage/\(cleanPath)"
        }
    }
    
    private func toggleStarMessage(_ msg: ChatMessage) {
        guard let roomId = selectedRoom?.id else { return }
        let starredKey = "glimpse_starred_messages_room_\(roomId)"
        var current = starredMessageIds
        if current.contains(msg.id) {
            current.remove(msg.id)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            current.insert(msg.id)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        starredMessageIds = current
        UserDefaults.standard.set(Array(current), forKey: starredKey)
    }

    private func togglePinMessage(_ msg: ChatMessage) {
        guard let roomId = selectedRoom?.id else { return }
        let pinnedKey = "glimpse_pinned_messages_room_\(roomId)"
        var current = pinnedMessageIds
        if current.contains(msg.id) {
            current.remove(msg.id)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            current.insert(msg.id)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        pinnedMessageIds = current
        UserDefaults.standard.set(Array(current), forKey: pinnedKey)
    }

    private func copyMessageToClipboard(_ msg: ChatMessage) {
        let displayText = msg.replyInfo?.actualMessage ?? msg.message
        UIPasteboard.general.string = displayText
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    private func formatMessageTime(_ rawDate: String?) -> String {
        guard let rawDate = rawDate else { return "" }
        let formatter = ISO8601DateFormatter()
        
        // Try parsing with fractional seconds first
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: rawDate)
        
        // Try parsing without fractional seconds as fallback
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: rawDate)
        }
        
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
    
    struct BubbleGlowProperties {
        let glowColor: Color
        let glowRadius: CGFloat
        let strokeColor: Color
        let strokeWidth: CGFloat
        let scale: CGFloat
    }
    
    private func parseMessageDate(_ rawDate: String?) -> Date? {
        guard let rawDate = rawDate else { return nil }
        let formatter = ISO8601DateFormatter()
        
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: rawDate) {
            return date
        }
        
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: rawDate) {
            return date
        }
        
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return fallbackFormatter.date(from: rawDate)
    }
    
    private func getGlowProperties(msg: ChatMessage, isMe: Bool, isHighlighted: Bool) -> BubbleGlowProperties {
        let newlySent = newlySentMessageIds.contains(msg.id)
        let newlyReceived = newlyReceivedMessageIds.contains(msg.id)
        
        let glowColor: Color
        let glowRadius: CGFloat
        let strokeColor: Color
        let strokeWidth: CGFloat
        let scale: CGFloat
        
        if isHighlighted {
            glowColor = Color.activeCyan.opacity(0.4)
            glowRadius = 8
            strokeColor = Color.activeCyan
            strokeWidth = 2.0
            scale = 1.03
        } else if newlySent {
            glowColor = Color.activeCyan.opacity(0.85)
            glowRadius = 12
            strokeColor = Color.activeCyan
            strokeWidth = 1.5
            scale = 1.02
        } else if newlyReceived {
            glowColor = Color.electricPurple.opacity(0.85)
            glowRadius = 12
            strokeColor = Color.electricPurple
            strokeWidth = 1.5
            scale = 1.02
        } else {
            glowColor = isMe ? Color.activeCyan.opacity(0.1) : Color.clear
            glowRadius = isMe ? 4 : 0
            strokeColor = isMe ? Color.activeCyan.opacity(0.35) : Color.white.opacity(0.05)
            strokeWidth = 1.0
            scale = 1.0
        }
        
        return BubbleGlowProperties(glowColor: glowColor, glowRadius: glowRadius, strokeColor: strokeColor, strokeWidth: strokeWidth, scale: scale)
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
        
        // Try parsing with fractional seconds first
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: rawDate)
        
        // Try parsing without fractional seconds as fallback
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: rawDate)
        }
        
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
        guard let initialReadId = roomInitialLastReadId else { return nil }
        let partnerId = auth.partner?.id ?? 0
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

    private func handleChatRoomUpdated(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let roomId = userInfo["room_id"] as? Int,
              let newName = userInfo["name"] as? String else { return }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            var updatedRooms: [GlimpseChatRoom] = []
            for var room in chatRooms {
                if room.id == roomId {
                    room.name = newName
                }
                updatedRooms.append(room)
            }
            chatRooms = updatedRooms
            
            // Also update selected room name instantly if it is actively open!
            if let active = selectedRoom, active.id == roomId {
                var updatedSelected = active
                updatedSelected.name = newName
                selectedRoom = updatedSelected
            }
        }
    }

    private func handleChatRoomDeleteStatusChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let roomId = userInfo["room_id"] as? Int else { return }
        
        let deleteRequestedBy = userInfo["delete_requested_by"] as? Int
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            var updatedRooms: [GlimpseChatRoom] = []
            for var room in chatRooms {
                if room.id == roomId {
                    room.delete_requested_by = deleteRequestedBy
                }
                updatedRooms.append(room)
            }
            chatRooms = updatedRooms
            auth.chatRooms = updatedRooms
            
            if let active = selectedRoom, active.id == roomId {
                var updatedSelected = active
                updatedSelected.delete_requested_by = deleteRequestedBy
                selectedRoom = updatedSelected
            }
        }
    }

    private func handleChatRoomThemeUpdated(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let roomId = userInfo["room_id"] as? Int else { return }
        let themeColor = userInfo["theme_color"] as? String
        let bgColor = userInfo["background_color"] as? String
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            var updatedRooms: [GlimpseChatRoom] = []
            for var room in chatRooms {
                if room.id == roomId {
                    room.theme_color = themeColor
                    room.background_color = bgColor
                }
                updatedRooms.append(room)
            }
            chatRooms = updatedRooms
            if let active = selectedRoom, active.id == roomId {
                var updatedSelected = active
                updatedSelected.theme_color = themeColor
                updatedSelected.background_color = bgColor
                selectedRoom = updatedSelected
            }
        }
    }

    private func handleChatMessageReceived(_ notification: Notification) {
        guard let newMsg = notification.object as? ChatMessage else { return }
        let isMainRoom = selectedRoom?.is_main ?? false
        let isSameRoom = selectedRoom?.id == newMsg.room_id
        let isCurrentRoom = isSameRoom || (isMainRoom && newMsg.room_id == nil)
        
        let partnerId = auth.partner?.id ?? 0
        let isPartnerMessage = newMsg.sender_id == partnerId
        let isMyMessage = !isPartnerMessage
        
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
                    if !foundTemp {
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
                } else {
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
                    
                    // Live-mark partner message as read if we are inside the active room
                    if isPartnerMessage {
                        // Trigger temporary glow for the newly received partner message
                        let rcvId = newMsg.id
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                            self.newlyReceivedMessageIds.insert(rcvId)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeOut(duration: 1.0)) {
                                _ = self.newlyReceivedMessageIds.remove(rcvId)
                            }
                        }
                        
                        Task {
                            await auth.markMessagesAsRead(messageId: newMsg.id)
                            
                            // Instantly update the local UserDefaults session for this room
                            let currentUserId = auth.currentUser?.id ?? 0
                            let userDefaultsKey = "last_read_message_id_\(currentUserId)_room_\(selectedRoom?.id ?? 0)"
                            UserDefaults.standard.set(newMsg.id, forKey: userDefaultsKey)
                        }
                    }
                }
            }
            
            // Sync local cache and auth-level persistent cache for the active room
            let activeRoomKey = selectedRoom?.id ?? 0
            self.messagesCache[activeRoomKey] = self.messages
            if activeRoomKey > 0 {
                auth.roomMessagesCache[activeRoomKey] = self.messages
            }
        } else {
            // Even if the room is NOT active, append the new message to its cached array
            let targetRoomKey = newMsg.room_id ?? 0
            var cachedArray = self.messagesCache[targetRoomKey] ?? auth.roomMessagesCache[targetRoomKey] ?? []
            if !cachedArray.contains(where: { $0.id == newMsg.id }) {
                cachedArray.append(newMsg)
                self.messagesCache[targetRoomKey] = cachedArray
                if targetRoomKey > 0 {
                    auth.roomMessagesCache[targetRoomKey] = cachedArray
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
        
        guard isInputFocused else { return }
        
        if !cleanNew.isEmpty && cleanOld.isEmpty {
            auth.sendTypingStatus(isTyping: true)
        } else if cleanNew.isEmpty && !cleanOld.isEmpty {
            auth.sendTypingStatus(isTyping: false)
        }
    }
    
    // --- 🔍 LOCAL CHAT SEARCH & NAVIGATION HELPERS ---
    
    private func updateLocalSearchMatches() {
        let cleanQuery = debouncedSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanQuery.isEmpty || !isSearchingChat {
            localSearchMatchIds = []
            localSearchCurrentIndex = -1
            highlightedMessageId = nil
            return
        }
        
        // Filter messages and keep their chronological order (oldest first).
        let matches = messages.filter { msg in
            msg.message.localizedCaseInsensitiveContains(cleanQuery)
        }
        localSearchMatchIds = matches.map { $0.id }
        
        if !localSearchMatchIds.isEmpty {
            // Default focus to the latest matched message (bottom-most)
            localSearchCurrentIndex = localSearchMatchIds.count - 1
            highlightedMessageId = localSearchMatchIds[localSearchCurrentIndex]
        } else {
            localSearchCurrentIndex = -1
            highlightedMessageId = nil
        }
    }
    
    private func jumpToLocalSearchMatch(index: Int, proxy: ScrollViewProxy) {
        guard index >= 0, index < localSearchMatchIds.count else { return }
        localSearchCurrentIndex = index
        let targetId = localSearchMatchIds[index]
        highlightedMessageId = targetId
        
        withAnimation(.easeInOut(duration: 0.35)) {
            proxy.scrollTo(targetId, anchor: .center)
        }
    }
    
    private func parseMessageDate(_ rawDate: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        
        // Try parsing with fractional seconds first
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: rawDate) {
            return date
        }
        
        // Try parsing without fractional seconds as fallback
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: rawDate) {
            return date
        }
        
        // YYYY-MM-DD HH:MM:SS fallback
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return fallbackFormatter.date(from: rawDate)
    }
    
    private func jumpToDate(_ targetDate: Date, proxy: ScrollViewProxy) {
        var closestMsg: ChatMessage? = nil
        var minDiff: TimeInterval = .infinity
        
        for msg in messages {
            guard let raw = msg.created_at, let msgDate = parseMessageDate(raw) else { continue }
            let diff = abs(msgDate.timeIntervalSince(targetDate))
            if diff < minDiff {
                minDiff = diff
                closestMsg = msg
            }
        }
        
        if let targetMsg = closestMsg {
            highlightedMessageId = targetMsg.id
            withAnimation(.easeInOut(duration: 0.45)) {
                proxy.scrollTo(targetMsg.id, anchor: .center)
            }
            
            // Automatically clear highlighted message after 2.0s
            let highlightId = targetMsg.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    if highlightedMessageId == highlightId {
                        highlightedMessageId = nil
                    }
                }
            }
        }
    }
    
    private func searchNavigationPanel(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 12) {
            // Calendar Icon Button
            Button {
                showDatePickerForJump = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1.2))
            }
            
            // Match Count Badge/Pill
            HStack {
                if localSearchMatchIds.isEmpty {
                    Text(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Type to search" : "No results")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text("\(localSearchCurrentIndex + 1) of \(localSearchMatchIds.count)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.activeCyan)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.black.opacity(0.2))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1.2))
            
            // Up Arrow (Older match)
            Button {
                if !localSearchMatchIds.isEmpty {
                    // Up arrow goes to older matches (towards index 0)
                    let nextIndex = (localSearchCurrentIndex - 1 + localSearchMatchIds.count) % localSearchMatchIds.count
                    jumpToLocalSearchMatch(index: nextIndex, proxy: proxy)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(localSearchMatchIds.isEmpty ? .white.opacity(0.2) : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(localSearchMatchIds.isEmpty ? 0.03 : 0.08))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(localSearchMatchIds.isEmpty ? 0.05 : 0.12), lineWidth: 1.2))
            }
            .disabled(localSearchMatchIds.isEmpty)
            
            // Down Arrow (Newer match)
            Button {
                if !localSearchMatchIds.isEmpty {
                    // Down arrow goes to newer matches (towards index count-1)
                    let nextIndex = (localSearchCurrentIndex + 1) % localSearchMatchIds.count
                    jumpToLocalSearchMatch(index: nextIndex, proxy: proxy)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(localSearchMatchIds.isEmpty ? .white.opacity(0.2) : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(localSearchMatchIds.isEmpty ? 0.03 : 0.08))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(localSearchMatchIds.isEmpty ? 0.05 : 0.12), lineWidth: 1.2))
            }
            .disabled(localSearchMatchIds.isEmpty)
        }
        .frame(height: 54)
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

struct FlatLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background(Color.clear)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SwipeableBubbleView<Content: View>: View {
    let msg: ChatMessage
    let isMe: Bool
    let onReplyTriggered: () -> Void
    let content: Content
    
    @State private var localSwipeOffset: CGFloat = 0
    @State private var isSwiping = false
    
    init(msg: ChatMessage, isMe: Bool, onReplyTriggered: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.msg = msg
        self.isMe = isMe
        self.onReplyTriggered = onReplyTriggered
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if isMe {
                // MY bubble: slides LEFT (localSwipeOffset < 0) towards the center of the screen
                ZStack(alignment: .trailing) {
                    if localSwipeOffset < -5 {
                        Image(systemName: "arrow.uturn.left.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.activeCyan)
                            .shadow(color: .activeCyan.opacity(0.35), radius: 6)
                            .opacity(min(1.0, Double(abs(localSwipeOffset) / 45.0)))
                            .scaleEffect(min(1.0, 0.5 + 0.5 * (abs(localSwipeOffset) / 50.0)))
                            .offset(x: 28 + (localSwipeOffset * 0.12))
                    }
                    
                    content
                        .offset(x: localSwipeOffset)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 8, coordinateSpace: .local)
                        .onChanged { value in
                            let width = value.translation.width
                            guard width < 0 else { return }
                            isSwiping = true
                            let limit: CGFloat = -60
                            if width < limit {
                                let excess = width - limit
                                localSwipeOffset = limit + excess * 0.35
                            } else {
                                localSwipeOffset = width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < -35 {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onReplyTriggered()
                            }
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                localSwipeOffset = 0
                            }
                            isSwiping = false
                        }
                )
            } else {
                // PARTNER bubble: slides RIGHT (localSwipeOffset > 0) towards the center of the screen
                ZStack(alignment: .leading) {
                    if localSwipeOffset > 5 {
                        Image(systemName: "arrow.uturn.left.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.activeCyan)
                            .shadow(color: .activeCyan.opacity(0.35), radius: 6)
                            .opacity(min(1.0, Double(localSwipeOffset / 45.0)))
                            .scaleEffect(min(1.0, 0.5 + 0.5 * (localSwipeOffset / 50.0)))
                            .offset(x: -28 + (localSwipeOffset * 0.12))
                    }
                    
                    content
                        .offset(x: localSwipeOffset)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 8, coordinateSpace: .local)
                        .onChanged { value in
                            let width = value.translation.width
                            guard width > 0 else { return }
                            isSwiping = true
                            let limit: CGFloat = 60
                            if width > limit {
                                let excess = width - limit
                                localSwipeOffset = limit + excess * 0.35
                            } else {
                                localSwipeOffset = width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width > 35 {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onReplyTriggered()
                            }
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                localSwipeOffset = 0
                            }
                            isSwiping = false
                        }
                )
            }
        }
    }
}
