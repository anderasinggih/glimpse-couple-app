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
                    let event = self.parseWebSocketString(text)
                    Task { @MainActor in
                        self.handleParsedWebSocketEvent(event)
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        let event = self.parseWebSocketString(text)
                        Task { @MainActor in
                            self.handleParsedWebSocketEvent(event)
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
    
    enum ParsedWebSocketEvent {
        case ping
        case connectionEstablished
        case subscriptionSucceeded
        case partnerStateUpdated(GlimpsePartnerStateUpdate)
        case syncLocationRequested(Int) // targetUserId
        case chatRoomCreated(GlimpseChatRoom)
        case chatRoomDeleted(Int) // roomId
        case chatRoomUpdated(roomId: Int, name: String)
        case chatRoomThemeUpdated(roomId: Int, themeColor: String?, backgroundColor: String?)
        case chatRoomDeleteStatusChanged(roomId: Int, deleteRequestedBy: Int?)
        case messageSent(ChatMessage)
        case loveBurstSent(timestamp: Double, senderId: Int, reaction: String?)
        case loveBumpSent(timestamp: Double, senderId: Int, totalMeetings: Int)
        case partnerTyping(userId: Int, isTyping: Bool, roomId: Int?)
        case unknown
    }
    
    private func parseWebSocketString(_ text: String) -> ParsedWebSocketEvent {
        guard let data = text.data(using: .utf8) else { return .unknown }
        do {
            let pusherEvent = try JSONDecoder().decode(PusherEvent.self, from: data)
            
            switch pusherEvent.event {
            case "pusher:ping":
                return .ping
                
            case "pusher:pong":
                return .ping // Triggers pong
                
            case "pusher:connection_established":
                return .connectionEstablished
                
            case "pusher_internal:subscription_succeeded":
                return .subscriptionSucceeded
                
            case "App\\Events\\PartnerStateUpdated":
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct ProtobufPayload: Codable {
                        let pb: String?
                    }
                    if let pbPayload = try? JSONDecoder().decode(ProtobufPayload.self, from: eventData),
                       let pbString = pbPayload.pb,
                       let update = GlimpsePartnerStateUpdate.decodeProtobuf(from: pbString) {
                        return .partnerStateUpdated(update)
                    }
                }
                
            case "App\\Events\\SyncLocationRequested":
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct SyncPayload: Codable {
                        let targetUserId: Int
                    }
                    if let payload = try? JSONDecoder().decode(SyncPayload.self, from: eventData) {
                        return .syncLocationRequested(payload.targetUserId)
                    }
                }
                
            case "App\\Events\\ChatRoomCreated":
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct RoomPayload: Codable {
                        let room: GlimpseChatRoom
                    }
                    if let payload = try? JSONDecoder().decode(RoomPayload.self, from: eventData) {
                        return .chatRoomCreated(payload.room)
                    }
                }
                
            case "App\\Events\\ChatRoomDeleted":
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct RoomIdPayload: Codable {
                        let room_id: Int
                    }
                    if let payload = try? JSONDecoder().decode(RoomIdPayload.self, from: eventData) {
                        return .chatRoomDeleted(payload.room_id)
                    }
                }

            case "App\\Events\\ChatRoomUpdated":
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct RoomUpdatePayload: Codable {
                        let room_id: Int
                        let name: String
                    }
                    if let payload = try? JSONDecoder().decode(RoomUpdatePayload.self, from: eventData) {
                        return .chatRoomUpdated(roomId: payload.room_id, name: payload.name)
                    }
                }

            case "App\\Events\\ChatRoomThemeUpdated":
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct ThemeUpdatePayload: Codable {
                        let room_id: Int
                        let theme_color: String?
                        let background_color: String?
                    }
                    if let payload = try? JSONDecoder().decode(ThemeUpdatePayload.self, from: eventData) {
                        return .chatRoomThemeUpdated(roomId: payload.room_id, themeColor: payload.theme_color, backgroundColor: payload.background_color)
                    }
                }

            case "App\\Events\\ChatRoomDeleteStatusChanged":
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct StatusPayload: Codable {
                        let room_id: Int
                        let delete_requested_by: Int?
                    }
                    if let payload = try? JSONDecoder().decode(StatusPayload.self, from: eventData) {
                        return .chatRoomDeleteStatusChanged(roomId: payload.room_id, deleteRequestedBy: payload.delete_requested_by)
                    }
                }

            case "App\\Events\\MessageSent":
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct ProtobufPayload: Codable {
                        let pb: String?
                    }
                    if let pbPayload = try? JSONDecoder().decode(ProtobufPayload.self, from: eventData),
                       let pbString = pbPayload.pb,
                       let pbMessage = ChatMessage.decodeProtobuf(from: pbString) {
                        return .messageSent(pbMessage)
                    }
                }
                
            case "App\\Events\\LoveBurstSent":
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct LoveBurstPayload: Codable {
                        let timestamp: Double
                        let sender_id: Int
                        let reaction: String?
                    }
                    if let payload = try? JSONDecoder().decode(LoveBurstPayload.self, from: eventData) {
                        return .loveBurstSent(timestamp: payload.timestamp, senderId: payload.sender_id, reaction: payload.reaction)
                    }
                }
                
            case "App\\Events\\LoveBumpSent":
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct LoveBumpPayload: Codable {
                        let timestamp: Double
                        let sender_id: Int
                        let total_meetings: Int
                    }
                    if let payload = try? JSONDecoder().decode(LoveBumpPayload.self, from: eventData) {
                        return .loveBumpSent(timestamp: payload.timestamp, senderId: payload.sender_id, totalMeetings: payload.total_meetings)
                    }
                }
                
            case "App\\Events\\PartnerTyping":
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct ProtobufPayload: Codable {
                        let pb: String?
                    }
                    if let pbPayload = try? JSONDecoder().decode(ProtobufPayload.self, from: eventData),
                       let pbString = pbPayload.pb,
                       let state = GlimpseTypingState.decodeProtobuf(from: pbString) {
                        return .partnerTyping(userId: state.userId, isTyping: state.isTyping, roomId: state.roomId)
                    }
                }
                
            default:
                break
            }
        } catch {
            print("⚠️ Failed to parse incoming socket event: \(error)")
        }
        return .unknown
    }
    
    @MainActor
    private func handleParsedWebSocketEvent(_ event: ParsedWebSocketEvent) {
        switch event {
        case .ping:
            self.sendPongFrame()
            
        case .connectionEstablished:
            print("✅ WebSocket handshake established!")
            self.isConnecting = false
            self.isWebSocketConnected = true
            if let coupleId = self.currentUser?.couple_id {
                self.sendSubscribeFrame(channel: "couple.\(coupleId)")
            }
            
        case .subscriptionSucceeded:
            print("❤️ Subscribed successfully to Glimpse Live Channel!")
            
        case .partnerStateUpdated(let update):
            print("🔔 Live State Updated from partner!")
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
            
            NotificationCenter.default.post(name: Notification.Name("GlimpseLiveStateUpdated"), object: nil)
            Task {
                try? await self.fetchFlashes()
            }
            
        case .syncLocationRequested(let targetUserId):
            print("🔄 Sync Location Requested received from Pusher!")
            if targetUserId == self.currentUser?.id {
                print("🛰️ Forcing GPS Location Sync as requested by Web/Partner!")
                LiveLocationManager.shared.forceWakeGPSAndSync(bypassCooldown: true)
            }
            
        case .chatRoomCreated(let room):
            print("🆕 Chat room created broadcast received!")
            NotificationCenter.default.post(name: Notification.Name("GlimpseChatRoomCreated"), object: room)
            
        case .chatRoomDeleted(let roomId):
            print("🗑️ Chat room deleted broadcast received!")
            NotificationCenter.default.post(name: Notification.Name("GlimpseChatRoomDeleted"), object: roomId)

        case .chatRoomUpdated(let roomId, let name):
            print("🔄 Chat room renamed broadcast received!")
            NotificationCenter.default.post(
                name: Notification.Name("GlimpseChatRoomUpdated"),
                object: nil,
                userInfo: ["room_id": roomId, "name": name]
            )

        case .chatRoomThemeUpdated(let roomId, let themeColor, let backgroundColor):
            print("🎨 Chat room theme updated broadcast received!")
            NotificationCenter.default.post(
                name: Notification.Name("GlimpseChatRoomThemeUpdated"),
                object: nil,
                userInfo: [
                    "room_id": roomId,
                    "theme_color": themeColor as Any,
                    "background_color": backgroundColor as Any
                ]
            )

        case .chatRoomDeleteStatusChanged(let roomId, let deleteRequestedBy):
            print("⚠️ Chat room delete status changed broadcast received!")
            NotificationCenter.default.post(
                name: Notification.Name("GlimpseChatRoomDeleteStatusChanged"),
                object: nil,
                userInfo: ["room_id": roomId, "delete_requested_by": deleteRequestedBy as Any]
            )

        case .messageSent(let finalMsg):
            print("💬 New message broadcast received!")
            GlimpseDatabase.shared.saveMessage(finalMsg)
            
            if finalMsg.sender_id != self.currentUser?.id, var p = self.partner, p.id == finalMsg.sender_id {
                p.last_active_at = ISO8601DateFormatter().string(from: Date())
                self.partner = p
            }
            if finalMsg.room_id == nil {
                if !self.latestFetchedMessages.contains(where: { $0.id == finalMsg.id }) {
                    self.latestFetchedMessages.append(finalMsg)
                }
            } else {
                if let rId = finalMsg.room_id {
                    var currentRoomMsgs = self.roomMessagesCache[rId] ?? []
                    if !currentRoomMsgs.contains(where: { $0.id == finalMsg.id }) {
                        currentRoomMsgs.append(finalMsg)
                        self.roomMessagesCache[rId] = currentRoomMsgs
                    }
                }
            }
            
            NotificationCenter.default.post(name: Notification.Name("GlimpseChatMessageReceived"), object: finalMsg)
            
            Task {
                let isCurrentActiveRoom = self.selectedTab == 3 && self.activeRoomId == finalMsg.room_id
                let isMyOwnMessage = finalMsg.sender_id == self.currentUser?.id
                
                if (isCurrentActiveRoom && !isMyOwnMessage) || isMyOwnMessage {
                    if !isMyOwnMessage {
                        await self.markMessagesAsRead(messageId: finalMsg.id)
                    }
                    let currentUserId = self.currentUser?.id ?? 0
                    let userDefaultsKey = "last_read_message_id_\(currentUserId)_room_\(finalMsg.room_id ?? 0)"
                    UserDefaults.standard.set(finalMsg.id, forKey: userDefaultsKey)
                }
                
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
            
            if finalMsg.sender_id != self.currentUser?.id {
                AudioServicesPlaySystemSound(1103)
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
            
        case .loveBurstSent(let timestamp, let senderId, let reaction):
            print("💖 Live Love Burst broadcast received!")
            self.lastLoveBurstReaction = reaction
            self.lastLoveBurstTimestamp = timestamp
            if senderId != self.currentUser?.id, var p = self.partner, p.id == senderId {
                p.last_active_at = ISO8601DateFormatter().string(from: Date())
                self.partner = p
            }
            
        case .loveBumpSent(let timestamp, let senderId, let totalMeetings):
            print("🤜🤛 Live Love Bump broadcast received!")
            self.totalMeetings = totalMeetings
            self.lastLoveBumpTimestamp = timestamp
            if senderId != self.currentUser?.id, var p = self.partner, p.id == senderId {
                p.last_active_at = ISO8601DateFormatter().string(from: Date())
                self.partner = p
            }
            
        case .partnerTyping(let userId, let isTyping, let roomId):
            print("⌨️ Live typing status broadcast received!")
            if userId != self.currentUser?.id {
                self.isPartnerTyping = isTyping
                self.partnerTypingRoomId = roomId
                if var p = self.partner, p.id == userId {
                    p.last_active_at = ISO8601DateFormatter().string(from: Date())
                    self.partner = p
                }
            }
            
        case .unknown:
            break
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
