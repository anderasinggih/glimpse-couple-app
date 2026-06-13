#if !WIDGET
import Foundation
import SwiftUI
import AudioToolbox

extension AuthManager {
    // MARK: - WEBSOCKET INTEGRATION
    @MainActor
    func connectWebSocket() {
        // If already connected, do nothing
        if isWebSocketConnected && webSocketTask != nil && webSocketTask?.state == .running {
            print("🔌 WebSocket already connected, ignoring connect request.")
            return
        }
        
        // If already in the process of connecting, do nothing
        if isConnecting {
            print("🔌 WebSocket is currently connecting, ignoring duplicate request.")
            return
        }
        
        // Close any existing connection first
        disconnectWebSocket()
        
        // Restore shouldReconnect to true since disconnectWebSocket sets it to false
        shouldReconnect = true
        isConnecting = true
        
        guard let _ = currentUser?.couple_id, coupleActive else {
            isConnecting = false
            return
        }
        
        // Parse host from baseURL
        guard let urlComponents = URLComponents(string: baseURL),
              let host = urlComponents.host else {
            isConnecting = false
            return
        }
        
        let appKey = "u1eadho8wbhzv2mcnlfy"
        let isLocal = host.contains("localhost") || host.contains("127.0.0.1") || host.contains("192.168.")
        let wsScheme = urlComponents.scheme == "https" ? "wss" : "ws"
        
        let wsUrlString = isLocal ?
            "\(wsScheme)://\(host):8080/app/\(appKey)?protocol=7&client=js&version=8.4.0-reverb" :
            "\(wsScheme)://\(host)/app/\(appKey)?protocol=7&client=js&version=8.4.0-reverb"
        guard let url = URL(string: wsUrlString) else {
            isConnecting = false
            return
        }
        
        print("🔌 Connecting to WebSockets at: \(wsUrlString)")
        
        let originScheme = wsScheme == "wss" ? "https" : "http"
        var request = URLRequest(url: url)
        request.setValue("\(originScheme)://\(host)", forHTTPHeaderField: "Origin")
        request.setValue("Glimpse/1.0 (iOS; Mobile)", forHTTPHeaderField: "User-Agent")
        
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        
        listenWebSocketMessages()
        startPingTimer()
    }
    
    @MainActor
    func disconnectWebSocket() {
        shouldReconnect = false
        isConnecting = false
        stopPingTimer()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        self.isWebSocketConnected = false
        print("🔌 WebSocket disconnected manually.")
    }
    
    @MainActor
    private func startPingTimer() {
        stopPingTimer()
        self.pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendPingFrame()
            }
        }
    }
    
    @MainActor
    private func stopPingTimer() {
        self.pingTimer?.invalidate()
        self.pingTimer = nil
    }
    
    private func sendPingFrame() {
        let payload = ["event": "pusher:ping", "data": [String: String]()] as [String : Any]
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            webSocketTask?.send(.string(jsonString)) { error in
                if let error = error {
                    print("⚠️ Failed to send ping: \(error)")
                } else {
                    print("📤 Sent websocket ping.")
                }
            }
        }
    }
    
    private func sendPongFrame() {
        let payload = ["event": "pusher:pong", "data": [String: String]()] as [String : Any]
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            webSocketTask?.send(.string(jsonString)) { error in
                if let error = error {
                    print("⚠️ Failed to send pong: \(error)")
                } else {
                    print("📤 Sent websocket pong.")
                }
            }
        }
    }
    
    private func listenWebSocketMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    Task { @MainActor in
                        self.handleWebSocketString(text)
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        Task { @MainActor in
                            self.handleWebSocketString(text)
                        }
                    }
                @unknown default:
                    break
                }
                
                // Continue listening recursively
                self.listenWebSocketMessages()
                
            case .failure(let error):
                print("❌ WebSocket connection failed/disconnected: \(error)")
                Task { @MainActor in
                    self.isConnecting = false
                    self.handleWebSocketDisconnection()
                }
            }
        }
    }
    
    struct PusherEvent: Codable {
        let event: String
        let channel: String?
        let data: String?
    }
    
    @MainActor
    private func handleWebSocketString(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        do {
            let pusherEvent = try JSONDecoder().decode(PusherEvent.self, from: data)
            
            switch pusherEvent.event {
            case "pusher:ping":
                self.sendPongFrame()
                
            case "pusher:pong":
                print("📥 Received websocket pong.")
                
            case "pusher:connection_established":
                print("✅ WebSocket handshake established!")
                self.isConnecting = false
                self.isWebSocketConnected = true
                if let coupleId = self.currentUser?.couple_id {
                    self.sendSubscribeFrame(channel: "couple.\(coupleId)")
                }
                
            case "pusher_internal:subscription_succeeded":
                print("❤️ Subscribed successfully to Glimpse Live Channel!")
                
            case "App\\Events\\PartnerStateUpdated":
                print("🔔 Live State Updated from partner!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct ProtobufPayload: Codable {
                        let pb: String?
                    }
                    if let pbPayload = try? JSONDecoder().decode(ProtobufPayload.self, from: eventData),
                       let pbString = pbPayload.pb,
                       let update = GlimpsePartnerStateUpdate.decodeProtobuf(from: pbString) {
                        if var p = self.partner, p.id == update.userId {
                            if let lat = update.latitude { p.latitude = lat }
                            if let lon = update.longitude { p.longitude = lon }
                            if let batt = update.batteryLevel { p.battery_level = batt }
                            if let char = update.isCharging { p.is_charging = char }
                            if let lastSeen = update.lastSeenMessageId { p.last_seen_message_id = lastSeen }
                            if let active = update.lastActiveAt { p.last_active_at = active }
                            if let sleep = update.isSleeping { p.is_sleeping = sleep }
                            p.status_note = update.statusNote
                            p.location_name = update.locationName
                            p.wifi_bssid = update.wifiBssid
                            p.last_updated = ISO8601DateFormatter().string(from: Date())
                            self.partner = p
                        }
                        
                        // Trigger immediate local state notification
                        NotificationCenter.default.post(name: Notification.Name("GlimpseLiveStateUpdated"), object: nil)
                        Task {
                            try? await self.fetchFlashes()
                        }
                    }
                }
                
            case "App\\Events\\SyncLocationRequested":
                print("🔄 Sync Location Requested received from Pusher!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct SyncPayload: Codable {
                        let targetUserId: Int
                    }
                    if let payload = try? JSONDecoder().decode(SyncPayload.self, from: eventData) {
                        // Only force sync if the target user ID matches my current user ID
                        if payload.targetUserId == self.currentUser?.id {
                            print("🛰️ Forcing GPS Location Sync as requested by Web/Partner!")
                            // Wake up GPS immediately to get fresh satellite coordinates
                            LiveLocationManager.shared.forceWakeGPSAndSync(bypassCooldown: true)
                        }
                    }
                }
                
            case "App\\Events\\ChatRoomCreated":
                print("🆕 Chat room created broadcast received!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct RoomPayload: Codable {
                        let room: GlimpseChatRoom
                    }
                    if let payload = try? JSONDecoder().decode(RoomPayload.self, from: eventData) {
                        NotificationCenter.default.post(name: Notification.Name("GlimpseChatRoomCreated"), object: payload.room)
                    }
                }
                
            case "App\\Events\\ChatRoomDeleted":
                print("🗑️ Chat room deleted broadcast received!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct RoomIdPayload: Codable {
                        let room_id: Int
                    }
                    if let payload = try? JSONDecoder().decode(RoomIdPayload.self, from: eventData) {
                        NotificationCenter.default.post(name: Notification.Name("GlimpseChatRoomDeleted"), object: payload.room_id)
                    }
                }

            case "App\\Events\\ChatRoomUpdated":
                print("🔄 Chat room renamed broadcast received!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct RoomUpdatePayload: Codable {
                        let room_id: Int
                        let name: String
                    }
                    if let payload = try? JSONDecoder().decode(RoomUpdatePayload.self, from: eventData) {
                        NotificationCenter.default.post(
                            name: Notification.Name("GlimpseChatRoomUpdated"),
                            object: nil,
                            userInfo: ["room_id": payload.room_id, "name": payload.name]
                        )
                    }
                }

            case "App\\Events\\ChatRoomThemeUpdated":
                print("🎨 Chat room theme updated broadcast received!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct ThemeUpdatePayload: Codable {
                        let room_id: Int
                        let theme_color: String?
                        let background_color: String?
                    }
                    if let payload = try? JSONDecoder().decode(ThemeUpdatePayload.self, from: eventData) {
                        NotificationCenter.default.post(
                            name: Notification.Name("GlimpseChatRoomThemeUpdated"),
                            object: nil,
                            userInfo: [
                                "room_id": payload.room_id,
                                "theme_color": payload.theme_color as Any,
                                "background_color": payload.background_color as Any
                            ]
                        )
                    }
                }

            case "App\\Events\\ChatRoomDeleteStatusChanged":
                print("⚠️ Chat room delete status changed broadcast received!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct StatusPayload: Codable {
                        let room_id: Int
                        let delete_requested_by: Int?
                    }
                    if let payload = try? JSONDecoder().decode(StatusPayload.self, from: eventData) {
                        NotificationCenter.default.post(
                            name: Notification.Name("GlimpseChatRoomDeleteStatusChanged"),
                            object: nil,
                            userInfo: ["room_id": payload.room_id, "delete_requested_by": payload.delete_requested_by as Any]
                        )
                    }
                }

            case "App\\Events\\MessageSent":
                print("💬 New message broadcast received!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    
                    var decodedMessage: ChatMessage? = nil
                    
                    // High-Performance Pure Protocol Buffers decoding
                    struct ProtobufPayload: Codable {
                        let pb: String?
                    }
                    if let pbPayload = try? JSONDecoder().decode(ProtobufPayload.self, from: eventData),
                       let pbString = pbPayload.pb,
                       let pbMessage = ChatMessage.decodeProtobuf(from: pbString) {
                        decodedMessage = pbMessage
                        print("⚡️ Decoded message instantly using High-Speed Protobuf binary!")
                    } else {
                        print("⚠️ Received MessageSent broadcast, but it was missing or had invalid Protobuf data.")
                    }
                    
                    if let finalMsg = decodedMessage {
                        // Persist in local SQLite database instantly
                        GlimpseDatabase.shared.saveMessage(finalMsg)
                        
                        if finalMsg.sender_id != self.currentUser?.id, var p = self.partner, p.id == finalMsg.sender_id {
                            p.last_active_at = ISO8601DateFormatter().string(from: Date())
                            self.partner = p
                        }
                        // If it belongs to the main chat room, append to latestFetchedMessages
                        if finalMsg.room_id == nil {
                            if !self.latestFetchedMessages.contains(where: { $0.id == finalMsg.id }) {
                                self.latestFetchedMessages.append(finalMsg)
                            }
                        } else {
                            // If it belongs to a subroom, append to the in-memory roomMessagesCache
                            if let rId = finalMsg.room_id {
                                var currentRoomMsgs = self.roomMessagesCache[rId] ?? []
                                if !currentRoomMsgs.contains(where: { $0.id == finalMsg.id }) {
                                    currentRoomMsgs.append(finalMsg)
                                    self.roomMessagesCache[rId] = currentRoomMsgs
                                }
                            }
                        }
                        
                        // Always notify the UI view so it can render the message live
                        NotificationCenter.default.post(name: Notification.Name("GlimpseChatMessageReceived"), object: finalMsg)
                        
                        // Unified coordinated Task to sync chat rooms and read state without double-fetching race conditions
                        Task {
                            let isCurrentActiveRoom = self.selectedTab == 3 && self.activeRoomId == finalMsg.room_id
                            let isMyOwnMessage = finalMsg.sender_id == self.currentUser?.id
                            
                            if (isCurrentActiveRoom && !isMyOwnMessage) || isMyOwnMessage {
                                if !isMyOwnMessage {
                                    await self.markMessagesAsRead(messageId: finalMsg.id)
                                }
                                // Instantly update the local UserDefaults session for this room
                                let currentUserId = self.currentUser?.id ?? 0
                                let userDefaultsKey = "last_read_message_id_\(currentUserId)_room_\(finalMsg.room_id ?? 0)"
                                UserDefaults.standard.set(finalMsg.id, forKey: userDefaultsKey)
                            }
                            
                            // Now safe to fetch room updates
                            if var rooms = try? await self.fetchChatRooms() {
                                await MainActor.run {
                                    let currentUserId = self.currentUser?.id ?? 0
                                    for i in 0..<rooms.count {
                                        let r = rooms[i]
                                        let userDefaultsKey = "last_read_message_id_\(currentUserId)_room_\(r.id)"
                                        let storedId = UserDefaults.standard.integer(forKey: userDefaultsKey)
                                        if let latestId = r.latest_message?.id, latestId > 0 && latestId <= storedId {
                                            rooms[i].unread_count = 0
                                        }
                                        if (isCurrentActiveRoom || isMyOwnMessage) && r.id == finalMsg.room_id {
                                            rooms[i].unread_count = 0
                                        }
                                    }
                                    self.chatRooms = rooms
                                    self.updateUnreadCount()
                                }
                            }
                        }
                        
                        // Global sound & haptic alert for incoming messages from partner!
                        if finalMsg.sender_id != self.currentUser?.id {
                            AudioServicesPlaySystemSound(1103) // Soft ting/ping sound as requested by user
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        }
                    }
                }
                
            case "App\\Events\\LoveBurstSent":
                print("💖 Live Love Burst broadcast received!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct LoveBurstPayload: Codable {
                        let timestamp: Double
                        let sender_id: Int
                        let reaction: String?
                    }
                    if let payload = try? JSONDecoder().decode(LoveBurstPayload.self, from: eventData) {
                        // Update lastLoveBurstTimestamp in real-time!
                        self.lastLoveBurstReaction = payload.reaction
                        self.lastLoveBurstTimestamp = payload.timestamp
                        if payload.sender_id != self.currentUser?.id, var p = self.partner, p.id == payload.sender_id {
                            p.last_active_at = ISO8601DateFormatter().string(from: Date())
                            self.partner = p
                        }
                    }
                }
                
            case "App\\Events\\LoveBumpSent":
                print("🤜🤛 Live Love Bump broadcast received!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct LoveBumpPayload: Codable {
                        let timestamp: Double
                        let sender_id: Int
                        let total_meetings: Int
                    }
                    if let payload = try? JSONDecoder().decode(LoveBumpPayload.self, from: eventData) {
                        self.totalMeetings = payload.total_meetings
                        self.lastLoveBumpTimestamp = payload.timestamp
                        if payload.sender_id != self.currentUser?.id, var p = self.partner, p.id == payload.sender_id {
                            p.last_active_at = ISO8601DateFormatter().string(from: Date())
                            self.partner = p
                        }
                    }
                }
                
            case "App\\Events\\PartnerTyping":
                print("⌨️ Live typing status broadcast received!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct ProtobufPayload: Codable {
                        let pb: String?
                    }
                    if let pbPayload = try? JSONDecoder().decode(ProtobufPayload.self, from: eventData),
                       let pbString = pbPayload.pb,
                       let state = GlimpseTypingState.decodeProtobuf(from: pbString) {
                        if state.userId != self.currentUser?.id {
                            self.isPartnerTyping = state.isTyping
                            self.partnerTypingRoomId = state.roomId
                            if var p = self.partner, p.id == state.userId {
                                p.last_active_at = ISO8601DateFormatter().string(from: Date())
                                self.partner = p
                            }
                        }
                    }
                }
                
            default:
                break
            }
        } catch {
            print("⚠️ Failed to parse incoming socket event: \(error)")
        }
    }
    
    private func sendSubscribeFrame(channel: String) {
        struct SubscribePayload: Codable {
            let event: String
            let data: SubscribeData
        }
        struct SubscribeData: Codable {
            let channel: String
        }
        
        let payload = SubscribePayload(event: "pusher:subscribe", data: SubscribeData(channel: channel))
        if let jsonData = try? JSONEncoder().encode(payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            webSocketTask?.send(.string(jsonString)) { error in
                if let error = error {
                    print("⚠️ Failed to send subscribe frame: \(error)")
                } else {
                    print("📤 Sent subscription frame for: \(channel)")
                }
            }
        }
    }
    
    @MainActor
    private func handleWebSocketDisconnection() {
        self.isWebSocketConnected = false
        guard shouldReconnect else { return }
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(reconnectInterval * 1_000_000_000))
            await MainActor.run {
                print("🔄 Attempting to reconnect to WebSocket...")
                self.connectWebSocket()
            }
        }
    }
}
#endif
