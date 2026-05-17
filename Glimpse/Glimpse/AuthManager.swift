import Foundation
import SwiftUI
import WidgetKit

@Observable
class AuthManager {
    static let shared = AuthManager()
    
    var isAuthenticated = false
    var currentUser: GlimpseUser?
    var partner: GlimpseUser?
    var anniversaryDate: Date?
    var disconnectRequestedBy: Int?
    var coupleActive = false
    var invitedBy: Int?
    var isTogether = false
    var togetherStreak = 0
    var totalMeetings = 0
    var lastLoveBurstTimestamp: Double = 0.0
    var showInviteDeclinedAlert = false
    private var _selectedTab = 0
    var selectedTab: Int {
        get { _selectedTab }
        set {
            _selectedTab = newValue
            if newValue == 3 {
                clearUnreadMessages()
            }
        }
    }
    
    var unreadMessagesCount = 0
    var latestFetchedMessages: [ChatMessage] = []
    var flashes: [GlimpseFlash] = []
    
    // WEBSOCKET PROPERTIES
    private var webSocketTask: URLSessionWebSocketTask?
    var isWebSocketConnected = false
    var isPartnerTyping = false
    private var shouldReconnect = true
    private var reconnectInterval: TimeInterval = 2.0
    
    var userToken: String? {
        UserDefaults.standard.string(forKey: "auth_token")
    }
    
    let baseURL = "http://172.20.10.2:8000/api"
    
    init() {
        // FAST START: Don't do heavy work here
        let token = UserDefaults.standard.string(forKey: "auth_token")
        if token != nil {
            self.isAuthenticated = true
            Task {
                try? await self.fetchState()
                self.connectWebSocket()
            }
        }
    }
    
    func fetchState() async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/state") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let wasPending = self.partner != nil && !self.coupleActive
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return
        }
        
        let responseData = try JSONDecoder().decode(CoupleResponse.self, from: data)
        await MainActor.run {
            let isNowDisconnected = responseData.partner_data == nil
            
            self.currentUser = responseData.user
            self.partner = responseData.partner_data
            self.anniversaryDate = responseData.anniversaryDate
            self.disconnectRequestedBy = responseData.disconnect_requested_by
            self.coupleActive = responseData.couple_active ?? false
            self.invitedBy = responseData.invited_by
            self.isTogether = responseData.is_together ?? false
            self.togetherStreak = responseData.together_streak ?? 0
            self.totalMeetings = responseData.total_meetings ?? 0
            self.lastLoveBurstTimestamp = responseData.love_burst_timestamp ?? 0.0
            
            if wasPending && isNowDisconnected {
                self.showInviteDeclinedAlert = true
            }
            
            // SAVE DATA FOR WIDGET
            let sharedDefaults = UserDefaults(suiteName: "group.glimpse.app")
            if let partner = responseData.partner_data,
               let encoded = try? JSONEncoder().encode(partner) {
                sharedDefaults?.set(encoded, forKey: "latest_partner_data")
                
                // Main App men-download foto untuk Widget agar menghindari error ATS dan menghemat baterai Widget
                Task {
                    var urlString = partner.latest_photo_url ?? partner.profile_photo_url
                    
                    if !urlString.hasPrefix("http") {
                        let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
                        let base = "http://172.20.10.2:8000"
                        urlString = cleanPath.contains("storage/") ? "\(base)/\(cleanPath)" : "\(base)/storage/\(cleanPath)"
                    }
                    
                    if let url = URL(string: urlString) {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
                                let fileURL = groupURL.appendingPathComponent("widget_photo.jpg")
                                try data.write(to: fileURL)
                            }
                        } catch {
                            print("Widget Photo Download Error: \(error)")
                        }
                    }
                    WidgetCenter.shared.reloadAllTimelines() // Force widget refresh setelah foto siap
                }
            } else {
                // Clear widget data if there is no partner
                sharedDefaults?.removeObject(forKey: "latest_partner_data")
                if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
                    let fileURL = groupURL.appendingPathComponent("widget_photo.jpg")
                    try? FileManager.default.removeItem(at: fileURL)
                }
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    func connectPartner(inviteCode: String) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/connect") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = ["invite_code": inviteCode]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid invite code or already connected"])
        }
        
        try await fetchState()
    }
    
    func acceptConnectRequest() async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/connect/accept") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to accept connection request"])
        }
        
        try await fetchState()
    }
    
    func declineConnectRequest() async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/connect/decline") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to decline connection request"])
        }
        
        try await fetchState()
    }
    
    func disconnectPartner() async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/disconnect") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to request disconnect"])
        }
        
        try await fetchState()
    }
    
    func approveDisconnectPartner() async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/disconnect/approve") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to approve disconnect"])
        }
        
        // Clear shared container data on disconnect
        let sharedDefaults = UserDefaults(suiteName: "group.glimpse.app")
        sharedDefaults?.removeObject(forKey: "latest_partner_data")
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
            let fileURL = groupURL.appendingPathComponent("widget_photo.jpg")
            try? FileManager.default.removeItem(at: fileURL)
        }
        WidgetCenter.shared.reloadAllTimelines()
        
        try await fetchState()
    }
    
    func cancelDisconnectPartner() async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/disconnect/cancel") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to cancel disconnect request"])
        }
        
        try await fetchState()
    }
    
    func pushCurrentStatus() {
        guard isAuthenticated else { return }
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = Int(UIDevice.current.batteryLevel * 100)
        let isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        
        Task {
            guard let url = URL(string: "\(baseURL)/glimpse/status") else { return }
            guard let token = userToken else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let body: [String: Any] = [
                "battery_level": batteryLevel,
                "is_charging": isCharging
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            _ = try? await URLSession.shared.data(for: request)
        }
    }
    
    func fetchMessages() async throws -> [ChatMessage] {
        guard let url = URL(string: "\(baseURL)/glimpse/chat") else { return [] }
        guard let token = userToken else { return [] }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }
        
        let decoded = try JSONDecoder().decode([ChatMessage].self, from: data)
        await MainActor.run {
            self.latestFetchedMessages = decoded
            self.updateUnreadCount()
        }
        return decoded
    }
    
    func fetchFlashes() async throws -> [GlimpseFlash] {
        guard let url = URL(string: "\(baseURL)/glimpse/flashes") else { return [] }
        guard let token = userToken else { return [] }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }
        
        let decoded = try JSONDecoder().decode([GlimpseFlash].self, from: data)
        await MainActor.run {
            self.flashes = decoded
        }
        return decoded
    }
    
    func updateUnreadCount() {
        if selectedTab == 3 {
            if let lastMsg = latestFetchedMessages.last {
                UserDefaults.standard.set(lastMsg.id, forKey: "last_read_message_id")
            }
            unreadMessagesCount = 0
            return
        }
        
        let lastReadId = UserDefaults.standard.integer(forKey: "last_read_message_id")
        let partnerId = partner?.id ?? 0
        
        let unread = latestFetchedMessages.filter { msg in
            msg.sender_id == partnerId && msg.id > lastReadId
        }
        
        unreadMessagesCount = unread.count
    }
    
    func clearUnreadMessages() {
        if let lastMsg = latestFetchedMessages.last {
            UserDefaults.standard.set(lastMsg.id, forKey: "last_read_message_id")
        }
        unreadMessagesCount = 0
    }
    
    func sendChatMessage(text: String) async throws -> ChatMessage {
        guard let url = URL(string: "\(baseURL)/glimpse/chat") else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        guard let token = userToken else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = ["message": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to send message"])
        }
        
        return try JSONDecoder().decode(ChatMessage.self, from: data)
    }

    func updateProfile(name: String?, email: String?, photo: UIImage?) async throws {
        guard let url = URL(string: "\(baseURL)/user/update") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        if let name = name {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(name)\r\n".data(using: .utf8)!)
        }
        
        if let email = email {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"email\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(email)\r\n".data(using: .utf8)!)
        }
        
        if let photo = photo, let imageData = photo.compressedForApp(maxDimension: 400, targetBytes: 100_000) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"profile_photo\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
        }
        
        try await fetchState()
    }

    func updateAnniversary(date: Date) async throws {
        guard let url = URL(string: "\(baseURL)/couple/anniversary") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let formatter = ISO8601DateFormatter()
        let body = ["anniversary_date": formatter.string(from: date)]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
        }
        
        try await fetchState()
    }
    
    func login(email: String, password: String) async throws {
        guard let url = URL(string: "\(baseURL)/login") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                errorMsg = message
            } else {
                errorMsg = "Invalid credentials"
            }
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["access_token"] as? String {
            UserDefaults.standard.set(token, forKey: "auth_token")
            withAnimation {
                self.isAuthenticated = true
            }
            Task {
                try? await self.fetchState()
                self.connectWebSocket()
            }
        }
    }
    
    func register(name: String, email: String, password: String) async throws {
        guard let url = URL(string: "\(baseURL)/register") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = ["name": name, "email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Registration failed"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["access_token"] as? String {
            UserDefaults.standard.set(token, forKey: "auth_token")
            withAnimation {
                self.isAuthenticated = true
            }
            Task {
                try? await self.fetchState()
                self.connectWebSocket()
            }
        }
    }
    
    func logout() {
        self.disconnectWebSocket()
        UserDefaults.standard.removeObject(forKey: "auth_token")
        
        let sharedDefaults = UserDefaults(suiteName: "group.glimpse.app")
        sharedDefaults?.removeObject(forKey: "latest_partner_data")
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
            let fileURL = groupURL.appendingPathComponent("widget_photo.jpg")
            try? FileManager.default.removeItem(at: fileURL)
        }
        WidgetCenter.shared.reloadAllTimelines()
        
        withAnimation {
            self.isAuthenticated = false
        }
    }
    
    func uploadPhoto(_ image: UIImage, latitude: Double? = nil, longitude: Double? = nil, battery: Int? = nil, note: String? = nil, locationName: String? = nil) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/photo") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 1. COMPRESS: Scale down to 800px and compress to under 100KB
        guard let finalData = image.compressedForApp(maxDimension: 800, targetBytes: 100_000) else { return }
        
        var body = Data()
        
        // 1. Photo data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"flash.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(finalData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 2. Latitude
        if let lat = latitude {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"latitude\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(lat)\r\n".data(using: .utf8)!)
        }
        
        // 3. Longitude
        if let lon = longitude {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"longitude\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(lon)\r\n".data(using: .utf8)!)
        }
        
        // 4. Battery
        if let batt = battery {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"battery_level\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(batt)\r\n".data(using: .utf8)!)
        }
        
        // 5. Note (Kabar)
        if let status = note {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"status_note\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(status)\r\n".data(using: .utf8)!)
        }
        
        // 6. Location Name
        if let loc = locationName {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"location_name\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(loc)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
        
        // 1. Send automatic flash attachment message
        _ = try? await sendChatMessage(text: "📷 Sent a Flash! [FLASH_ATTACHMENT]")
        
        // 2. Refresh state after upload to reflect changes
        try? await fetchState()
    }
    
    func triggerServerLoveBurst() async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/love-burst") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Love burst failed"])
        }
    }
    
    func sendTypingStatus(isTyping: Bool) {
        guard isAuthenticated else { return }
        
        Task {
            guard let url = URL(string: "\(baseURL)/glimpse/typing") else { return }
            guard let token = userToken else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let body = ["is_typing": isTyping]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            _ = try? await URLSession.shared.data(for: request)
        }
    }
    
    // MARK: - WEBSOCKET INTEGRATION
    func connectWebSocket() {
        // Close any existing connection first
        disconnectWebSocket()
        
        guard let coupleId = currentUser?.couple_id, coupleActive else { return }
        
        // Parse host from baseURL
        guard let urlComponents = URLComponents(string: baseURL),
              let host = urlComponents.host else { return }
        
        let appKey = "u1eadho8wbhzv2mcnlfy"
        let wsPort = 8080
        let wsScheme = urlComponents.scheme == "https" ? "wss" : "ws"
        
        let wsUrlString = "\(wsScheme)://\(host):\(wsPort)/app/\(appKey)?protocol=7&client=js&version=8.4.0-reverb"
        guard let url = URL(string: wsUrlString) else { return }
        
        print("🔌 Connecting to WebSockets at: \(wsUrlString)")
        
        shouldReconnect = true
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        
        listenWebSocketMessages()
    }
    
    func disconnectWebSocket() {
        shouldReconnect = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        DispatchQueue.main.async {
            self.isWebSocketConnected = false
        }
        print("🔌 WebSocket disconnected manually.")
    }
    
    private func listenWebSocketMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleWebSocketString(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleWebSocketString(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue listening recursively
                self.listenWebSocketMessages()
                
            case .failure(let error):
                print("❌ WebSocket connection failed/disconnected: \(error)")
                self.handleWebSocketDisconnection()
            }
        }
    }
    
    struct PusherEvent: Codable {
        let event: String
        let channel: String?
        let data: String?
    }
    
    private func handleWebSocketString(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        do {
            let pusherEvent = try JSONDecoder().decode(PusherEvent.self, from: data)
            
            switch pusherEvent.event {
            case "pusher:connection_established":
                print("✅ WebSocket handshake established!")
                DispatchQueue.main.async {
                    self.isWebSocketConnected = true
                }
                if let coupleId = self.currentUser?.couple_id {
                    self.sendSubscribeFrame(channel: "couple.\(coupleId)")
                }
                
            case "pusher_internal:subscription_succeeded":
                print("❤️ Subscribed successfully to Glimpse Live Channel!")
                
            case "App\\Events\\PartnerStateUpdated":
                print("🔔 Live State Updated from partner!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct StatePayload: Codable {
                        let user: GlimpseUser
                    }
                    if let payload = try? JSONDecoder().decode(StatePayload.self, from: eventData) {
                        DispatchQueue.main.async {
                            self.partner = payload.user
                            // Trigger immediate local state notification
                            NotificationCenter.default.post(name: Notification.Name("GlimpseLiveStateUpdated"), object: nil)
                        }
                    }
                }
                
            case "App\\Events\\MessageSent":
                print("💬 New message broadcast received!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct MessagePayload: Codable {
                        let message: ChatMessage
                    }
                    if let payload = try? JSONDecoder().decode(MessagePayload.self, from: eventData) {
                        DispatchQueue.main.async {
                            if !self.latestFetchedMessages.contains(where: { $0.id == payload.message.id }) {
                                self.latestFetchedMessages.append(payload.message)
                                self.updateUnreadCount()
                                NotificationCenter.default.post(name: Notification.Name("GlimpseChatMessageReceived"), object: payload.message)
                            }
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
                    }
                    if let payload = try? JSONDecoder().decode(LoveBurstPayload.self, from: eventData) {
                        DispatchQueue.main.async {
                            // Update lastLoveBurstTimestamp in real-time!
                            self.lastLoveBurstTimestamp = payload.timestamp
                        }
                    }
                }
                
            case "App\\Events\\PartnerTyping":
                print("⌨️ Live typing status broadcast received!")
                if let eventDataString = pusherEvent.data,
                   let eventData = eventDataString.data(using: .utf8) {
                    struct TypingPayload: Codable {
                        let user_id: Int
                        let is_typing: Bool
                    }
                    if let payload = try? JSONDecoder().decode(TypingPayload.self, from: eventData) {
                        DispatchQueue.main.async {
                            // Update partner typing status in real-time!
                            self.isPartnerTyping = payload.is_typing
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
    
    private func handleWebSocketDisconnection() {
        DispatchQueue.main.async {
            self.isWebSocketConnected = false
        }
        guard shouldReconnect else { return }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + reconnectInterval) { [weak self] in
            print("🔄 Attempting to reconnect to WebSocket...")
            self?.connectWebSocket()
        }
    }
}

extension UIImage {
    func compressedForApp(maxDimension: CGFloat, targetBytes: Int) -> Data? {
        var targetSize = self.size
        if self.size.width > maxDimension || self.size.height > maxDimension {
            let aspectRatio = self.size.width / self.size.height
            if aspectRatio > 1 {
                targetSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                targetSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }
        }
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        var compression: CGFloat = 0.7
        var imageData = resizedImage.jpegData(compressionQuality: compression)
        
        while (imageData?.count ?? 0) > targetBytes && compression > 0.05 {
            compression -= 0.1
            imageData = resizedImage.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
}
