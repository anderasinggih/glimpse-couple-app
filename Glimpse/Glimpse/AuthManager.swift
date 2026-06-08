#if !WIDGET
import Foundation
import SwiftUI
import WidgetKit
import AudioToolbox
import Combine
import ImageIO
import UniformTypeIdentifiers
import SQLite3

enum ActivityMode: String, Codable {
    case unknown, walking, cycling, car
}

@Observable
class AuthManager {
    static let shared = AuthManager()
    
    var isAuthenticated = false
    var isInitialStateLoaded = false
    var currentUser: GlimpseUser?
    var partner: GlimpseUser?
    var partnerSpeedKmH: Double? = nil
    var mySpeedKmH: Double? = nil
    var partnerSpeedHistory: [Double] = []
    var mySpeedHistory: [Double] = []
    
    // Speed zero persistence & Activity Mode State Machine
    var partnerActivityMode: ActivityMode = .unknown
    var partnerLockedActivityMode: ActivityMode = .unknown
    var partnerSpeedRangeSince: Date? = nil
    var partnerLastSpeedRange: ActivityMode = .unknown
    var partnerZeroSpeedStart: Date? = nil
    
    var myActivityMode: ActivityMode = .unknown
    var myLockedActivityMode: ActivityMode = .unknown
    var mySpeedRangeSince: Date? = nil
    var myLastSpeedRange: ActivityMode = .unknown
    var myZeroSpeedStart: Date? = nil
    
    func updatePartnerSpeed(_ speed: Double?) {
        let now = Date()
        
        // 1. Handle Speed Value & 2-Minute 0 km/h Persistence
        var effectiveSpeed: Double? = speed
        if speed == nil || speed! < 3.0 {
            if partnerZeroSpeedStart == nil {
                partnerZeroSpeedStart = now
            }
            
            let elapsedZero = now.timeIntervalSince(partnerZeroSpeedStart!)
            if elapsedZero < 120.0 { // 2 minutes persistence
                effectiveSpeed = 0.0
            } else {
                effectiveSpeed = nil
            }
        } else {
            partnerZeroSpeedStart = nil
        }
        
        self.partnerSpeedKmH = effectiveSpeed
        
        if let spd = effectiveSpeed {
            partnerSpeedHistory.append(spd)
            if partnerSpeedHistory.count > 12 {
                partnerSpeedHistory.removeFirst()
            }
        }
        
        // 2. Determine Current Speed Range / Mode
        let currentRange: ActivityMode
        if effectiveSpeed == nil || effectiveSpeed! < 3.0 {
            currentRange = .unknown
        } else if effectiveSpeed! < 10.0 {
            currentRange = .walking
        } else if effectiveSpeed! <= 20.0 {
            currentRange = .cycling
        } else {
            currentRange = .car
        }
        
        // 3. Process Activity Mode State Machine (3-Minute Lock & Unlock)
        if currentRange != partnerLastSpeedRange {
            partnerLastSpeedRange = currentRange
            partnerSpeedRangeSince = now
        }
        
        let rangeDuration = now.timeIntervalSince(partnerSpeedRangeSince ?? now)
        
        if currentRange != .unknown {
            if rangeDuration >= 180.0 {
                partnerLockedActivityMode = currentRange
                partnerActivityMode = currentRange
            } else if partnerLockedActivityMode != .unknown {
                partnerActivityMode = partnerLockedActivityMode
            } else {
                partnerActivityMode = currentRange
            }
        } else {
            if partnerLockedActivityMode != .unknown {
                partnerActivityMode = partnerLockedActivityMode
                
                if let zeroStart = partnerZeroSpeedStart {
                    let elapsedZero = now.timeIntervalSince(zeroStart)
                    if elapsedZero >= 180.0 {
                        partnerLockedActivityMode = .unknown
                        partnerActivityMode = .unknown
                    }
                }
            } else {
                partnerActivityMode = .unknown
            }
        }
    }
    
    func updateMySpeed(_ speed: Double?) {
        let now = Date()
        
        // 1. Handle Speed Value & 2-Minute 0 km/h Persistence
        var effectiveSpeed: Double? = speed
        if speed == nil || speed! < 3.0 {
            if myZeroSpeedStart == nil {
                myZeroSpeedStart = now
            }
            
            let elapsedZero = now.timeIntervalSince(myZeroSpeedStart!)
            if elapsedZero < 120.0 { // 2 minutes persistence
                effectiveSpeed = 0.0
            } else {
                effectiveSpeed = nil
            }
        } else {
            myZeroSpeedStart = nil
        }
        
        self.mySpeedKmH = effectiveSpeed
        
        if let spd = effectiveSpeed {
            mySpeedHistory.append(spd)
            if mySpeedHistory.count > 12 {
                mySpeedHistory.removeFirst()
            }
        }
        
        // 2. Determine Current Speed Range / Mode
        let currentRange: ActivityMode
        if effectiveSpeed == nil || effectiveSpeed! < 3.0 {
            currentRange = .unknown
        } else if effectiveSpeed! < 10.0 {
            currentRange = .walking
        } else if effectiveSpeed! <= 20.0 {
            currentRange = .cycling
        } else {
            currentRange = .car
        }
        
        // 3. Process Activity Mode State Machine (3-Minute Lock & Unlock)
        if currentRange != myLastSpeedRange {
            myLastSpeedRange = currentRange
            mySpeedRangeSince = now
        }
        
        let rangeDuration = now.timeIntervalSince(mySpeedRangeSince ?? now)
        
        if currentRange != .unknown {
            if rangeDuration >= 180.0 {
                myLockedActivityMode = currentRange
                myActivityMode = currentRange
            } else if myLockedActivityMode != .unknown {
                myActivityMode = myLockedActivityMode
            } else {
                myActivityMode = currentRange
            }
        } else {
            if myLockedActivityMode != .unknown {
                myActivityMode = myLockedActivityMode
                
                if let zeroStart = myZeroSpeedStart {
                    let elapsedZero = now.timeIntervalSince(zeroStart)
                    if elapsedZero >= 180.0 {
                        myLockedActivityMode = .unknown
                        myActivityMode = .unknown
                    }
                }
            } else {
                myActivityMode = .unknown
            }
        }
    }
    
    var partnerAverageSpeedKmH: Double? {
        guard !partnerSpeedHistory.isEmpty else { return partnerSpeedKmH }
        return partnerSpeedHistory.reduce(0.0, +) / Double(partnerSpeedHistory.count)
    }
    
    var myAverageSpeedKmH: Double? {
        guard !mySpeedHistory.isEmpty else { return mySpeedKmH }
        return mySpeedHistory.reduce(0.0, +) / Double(mySpeedHistory.count)
    }
    
    func checkStationarySpeedTimeouts() {
        let now = Date()
        
        // 1. Partner Check
        if let zeroStart = partnerZeroSpeedStart {
            let elapsedZero = now.timeIntervalSince(zeroStart)
            
            if elapsedZero >= 120.0 && partnerSpeedKmH != nil {
                partnerSpeedKmH = nil
                print("⏱️ Partner stationary 2m: speed set to nil")
            }
            
            if elapsedZero >= 180.0 && partnerLockedActivityMode != .unknown {
                partnerLockedActivityMode = .unknown
                partnerActivityMode = .unknown
                print("⏱️ Partner stationary 3m: activity lock released")
            }
        }
        
        // 2. My Check
        if let zeroStart = myZeroSpeedStart {
            let elapsedZero = now.timeIntervalSince(zeroStart)
            
            if elapsedZero >= 120.0 && mySpeedKmH != nil {
                mySpeedKmH = nil
                print("⏱️ My stationary 2m: speed set to nil")
            }
            
            if elapsedZero >= 180.0 && myLockedActivityMode != .unknown {
                myLockedActivityMode = .unknown
                myActivityMode = .unknown
                print("⏱️ My stationary 3m: activity lock released")
            }
        }
    }
    var anniversaryDate: Date?
    var pairedDate: Date?
    var disconnectRequestedBy: Int?
    var coupleActive = false
    var invitedBy: Int?
    var isTogether = false
    var togetherStreak = 0
    var highestTogetherStreak = 0
    var totalMeetings = 0
    var lastLoveBurstTimestamp: Double = 0.0
    var lastLoveBumpTimestamp: Double = 0.0
    var lastLoveBurstReaction: String? = nil
    var activeSchedule: GlimpseSchedule? = nil
    var pendingInvitation: GlimpseSchedule? = nil
    var selectedChatRoom: GlimpseChatRoom? = nil
    var showScheduleSheet = false
    var showInviteDeclinedAlert = false
    var showSessionTerminatedAlert = false
    let chatTabDoubleTapPublisher = PassthroughSubject<Void, Never>()
    
    private var _selectedTab = 0
    var selectedTab: Int {
        get { _selectedTab }
        set {
            if _selectedTab == newValue {
                if newValue == 3 {
                    chatTabDoubleTapPublisher.send()
                }
            }
            _selectedTab = newValue
            if newValue == 3 {
                let currentUserId = currentUser?.id ?? 0
                if currentUserId > 0 {
                    let userDefaultsKey = "last_read_message_id_\(currentUserId)"
                    let localLastReadId = UserDefaults.standard.integer(forKey: userDefaultsKey)
                    let dbLastReadId = currentUser?.last_seen_message_id ?? 0
                    initialLastReadId = max(localLastReadId, dbLastReadId)
                } else {
                    initialLastReadId = 0
                }
            }
        }
    }
    
    var unreadMessagesCount = 0
    var initialLastReadId = 0
    var latestFetchedMessages: [ChatMessage] = []
    var flashes: [GlimpseFlash] = []
    var chatRooms: [GlimpseChatRoom] = [] {
        didSet {
            saveChatRoomsCache()
        }
    }
    var activeRoomId: Int? = nil
    /// Persistent cache for room-specific messages — survives tab switching and view recreation
    var roomMessagesCache: [Int: [ChatMessage]] = [:]
    
    // UPLOAD PROGRESS
    var isUploadingFlash: Bool = false
    var uploadProgress: Double = 0.0
    var uploadFailed: Bool = false
    var uploadSuccess: Bool = false
    var uploadTask: Task<Void, Never>? = nil
    var uploadQueueTotal: Int = 0
    var uploadQueueCurrent: Int = 0
    
    // WEBSOCKET PROPERTIES
    var webSocketTask: URLSessionWebSocketTask?
    var isWebSocketConnected = false
    var isPartnerTyping = false
    var partnerTypingRoomId: Int? = nil
    var shouldReconnect = true
    var reconnectInterval: TimeInterval = 2.0
    var pingTimer: Timer?
    var isConnecting = false
    var dailyBumps: Int = 0
    
    var userToken: String? {
        UserDefaults.standard.string(forKey: "auth_token")
    }
    
    var dashboardRefreshTrigger = false
    
    var baseURL: String {
        get {
            UserDefaults.standard.string(forKey: "glimpse_api_base_url") ?? "https://api.galleryfortwo.my.id/api"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "glimpse_api_base_url")
        }
    }
    
    init() {
        // FAST START: Don't do heavy work here
        let token = UserDefaults.standard.string(forKey: "auth_token")
        if token != nil {
            self.isAuthenticated = true
            
            // 1. Instantly load cached session for offline resilience
            loadCachedSession()
            loadCachedMessages()
            loadCachedChatRooms()
            loadCachedFlashes()
            
            Task {
                try? await self.fetchState()
                self.connectWebSocket()
                self.processPendingFlashes()
            }
        }
        
        // Reconnect WebSocket and sync state immediately when returning to foreground
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            print("📱 App entered foreground. Reconnecting WebSockets...")
            if self.isAuthenticated {
                self.connectWebSocket()
                Task {
                    try? await self.fetchState()
                    _ = try? await self.fetchFlashes()
                }
            }
        }
        
        // Gracefully disconnect WebSocket on background to prevent socket leaks and waste of battery
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            print("📱 App entered background. Disconnecting WebSockets gracefully...")
            self.disconnectWebSocket()
        }
        
        // Start a 1-second timer to check and update stationary speed and activity lock timeout
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.checkStationarySpeedTimeouts()
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
        
        guard await checkResponseStatus(response) else { return }
        
        let responseData = try JSONDecoder().decode(CoupleResponse.self, from: data)
        saveSessionCache(data)
        await MainActor.run {
            let isNowDisconnected = responseData.partner_data == nil
            
            self.currentUser = responseData.user
            self.partner = responseData.partner_data
            self.anniversaryDate = responseData.anniversaryDate
            self.pairedDate = responseData.pairedDate
            self.disconnectRequestedBy = responseData.disconnect_requested_by
            self.coupleActive = responseData.couple_active ?? false
            self.invitedBy = responseData.invited_by
            self.isTogether = responseData.is_together ?? false
            self.togetherStreak = responseData.together_streak ?? 0
            self.highestTogetherStreak = responseData.highest_together_streak ?? 0
            self.totalMeetings = responseData.total_meetings ?? 0
            self.lastLoveBurstTimestamp = responseData.love_burst_timestamp ?? 0.0
            self.activeSchedule = responseData.active_schedule
            self.pendingInvitation = responseData.pending_invitation
            
            if wasPending && isNowDisconnected {
                self.showInviteDeclinedAlert = true
            }
            
            self.isInitialStateLoaded = true
            
            // SAVE DATA FOR WIDGET
            let sharedDefaults = UserDefaults(suiteName: "group.glimpse.app")
            if var partner = responseData.partner_data {
                // Strip large data not needed by widget
                partner.location_history = nil
                
                if let encoded = try? JSONEncoder().encode(partner) {
                    sharedDefaults?.set(encoded, forKey: "latest_partner_data")
                }
                
                // Main App men-sync/download foto untuk Widget agar menghindari error ATS dan menghemat baterai Widget
                Task {
                    var urlString = partner.latest_photo_url ?? partner.profile_photo_url
                    
                    if !urlString.hasPrefix("http") {
                        let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
                        let base = "https://api.galleryfortwo.my.id"
                        urlString = cleanPath.contains("storage/") ? "\(base)/\(cleanPath)" : "\(base)/storage/\(cleanPath)"
                    }
                    
                    let cleanName = urlString.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
                    let filename = "img_cache_\(cleanName).jpg"
                    let fileManager = FileManager.default
                    
                    var cachedData: Data? = nil
                    if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
                        let cachedURL = groupURL.appendingPathComponent(filename)
                        cachedData = try? Data(contentsOf: cachedURL)
                    }
                    if cachedData == nil, let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                        let cachedURL = cachesURL.appendingPathComponent(filename)
                        cachedData = try? Data(contentsOf: cachedURL)
                    }
                    
                    var syncSuccessful = false
                    if let data = cachedData {
                        if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
                            let fileURL = groupURL.appendingPathComponent("widget_photo.jpg")
                            do {
                                try data.write(to: fileURL)
                                print("💾 Synced widget_photo.jpg from local cache.")
                                syncSuccessful = true
                            } catch {
                                print("⚠️ Failed to write cached data to widget_photo.jpg: \(error)")
                            }
                        }
                    }
                    
                    if !syncSuccessful, let url = URL(string: urlString) {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
                                let fileURL = groupURL.appendingPathComponent("widget_photo.jpg")
                                try data.write(to: fileURL)
                                print("💾 Downloaded and wrote widget_photo.jpg from server.")
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
            
            let status = GlimpseUserStatus(
                latitude: nil,
                longitude: nil,
                batteryLevel: batteryLevel,
                isCharging: isCharging,
                statusNote: nil,
                locationName: nil,
                wifiBssid: nil
            )
            let protoData = status.encodeProtobuf()
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = protoData
            
            _ = try? await URLSession.shared.data(for: request)
        }
    }
    
    func pushLocationAndStatus(latitude: Double?, longitude: Double?, locationName: String?, gpsTimestamp: TimeInterval? = nil) {
        guard isAuthenticated else { return }
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = Int(UIDevice.current.batteryLevel * 100)
        let isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        let wifi = LiveLocationManager.shared.currentWiFiBSSID
        
        // Update local currentUser state immediately so the map renders "Me" in real-time
        Task { @MainActor in
            if let lat = latitude, let lon = longitude {
                self.currentUser?.latitude = lat
                self.currentUser?.longitude = lon
                if let name = locationName {
                    self.currentUser?.location_name = name
                }
                self.currentUser?.battery_level = batteryLevel
                self.currentUser?.is_charging = isCharging
            }
        }
        
        Task {
            guard let url = URL(string: "\(baseURL)/glimpse/status") else { return }
            guard let token = userToken else { return }
            
            let status = GlimpseUserStatus(
                latitude: latitude,
                longitude: longitude,
                batteryLevel: batteryLevel,
                isCharging: isCharging,
                statusNote: nil,
                locationName: locationName,
                wifiBssid: wifi,
                gpsTimestamp: gpsTimestamp ?? Date().timeIntervalSince1970
            )
            let protoData = status.encodeProtobuf()
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = protoData
            
            _ = try? await URLSession.shared.data(for: request)
        }
    }
    
    func fetchMessages(roomId: Int? = nil) async throws -> [ChatMessage] {
        var urlString = "\(baseURL)/glimpse/chat"
        if let rId = roomId {
            urlString += "?room_id=\(rId)"
        }
        guard let url = URL(string: urlString) else { return [] }
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
            // Save directly to native SQLite database
            GlimpseDatabase.shared.saveMessages(decoded)
            
            if let rId = roomId {
                // Persist room-specific messages in AuthManager-level cache (survives view lifecycle)
                self.roomMessagesCache[rId] = decoded
            } else {
                self.latestFetchedMessages = decoded
                self.updateUnreadCount()
            }
        }
        if let lastMsg = decoded.last {
            Task {
                await self.markMessagesAsRead(messageId: lastMsg.id)
            }
        }
        return decoded
    }
    
    func fetchFlashes() async throws -> [GlimpseFlash] {
        print("🔍 fetchFlashes() triggered.")
        guard let url = URL(string: "\(baseURL)/glimpse/flashes") else { return [] }
        guard let token = userToken else { return [] }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("⚠️ fetchFlashes got non-200 response: \(String(describing: response))")
            return []
        }
        
        let decoded = try JSONDecoder().decode([GlimpseFlash].self, from: data)
        let currentUserId = currentUser?.id ?? 0
        print("🔍 fetchFlashes: Decoded \(decoded.count) flashes. Current User ID: \(currentUserId)")
        
        var newFlashes: [GlimpseFlash] = []
        await MainActor.run {
            for flash in decoded {
                let alreadyCached = self.flashes.contains(where: { $0.id == flash.id })
                print("   - Flash ID: \(flash.id), Sender: \(flash.sender_id), Already Cached locally: \(alreadyCached)")
                if !alreadyCached {
                    newFlashes.append(flash)
                }
            }
        }
        
        print("🔍 fetchFlashes: Identified \(newFlashes.count) new flashes.")
        
        for flash in newFlashes {
            let flashUrlStr = flash.photo_url
            let finalUrlStr = flashUrlStr.hasPrefix("http") ? flashUrlStr : {
                let cleanPath = flashUrlStr.hasPrefix("/") ? String(flashUrlStr.dropFirst()) : flashUrlStr
                let base = baseURL.replacingOccurrences(of: "/api", with: "")
                return cleanPath.contains("storage/") ? "\(base)/\(cleanPath)" : "\(base)/storage/\(cleanPath)"
            }()
            
            print("🔍 fetchFlashes: Downloading image from URL: \(finalUrlStr)")
            var downloadSuccessful = false
            if let downloadUrl = URL(string: finalUrlStr) {
                do {
                    let (imgData, _) = try await URLSession.shared.data(from: downloadUrl)
                    if UIImage(data: imgData) != nil {
                        let cleanName = finalUrlStr.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
                        let filename = "img_cache_\(cleanName).jpg"
                        let fileManager = FileManager.default
                        
                        var primaryURL: URL? = nil
                        if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
                            primaryURL = groupURL.appendingPathComponent(filename)
                        }
                        
                        var fallbackURL: URL? = nil
                        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                            fallbackURL = cachesURL.appendingPathComponent(filename)
                        }
                        
                        var successWrite = false
                        if let primaryURL = primaryURL {
                            do {
                                try imgData.write(to: primaryURL)
                                print("💾 Cached image to primary App Group path: \(filename)")
                                successWrite = true
                                
                                // Sync to widget_photo.jpg for Widget filesystem access
                                if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
                                    let widgetURL = groupURL.appendingPathComponent("widget_photo.jpg")
                                    try? imgData.write(to: widgetURL)
                                    print("💾 Also synced image to widget_photo.jpg for Widget access.")
                                }
                            } catch {
                                print("⚠️ Failed to write to primary App Group path: \(error)")
                            }
                        }
                        
                        if !successWrite, let fallbackURL = fallbackURL {
                            do {
                                try imgData.write(to: fallbackURL)
                                print("💾 Cached image to local fallback path: \(filename)")
                                successWrite = true
                                
                                // Sync to widget_photo.jpg for Widget access
                                if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
                                    let widgetURL = groupURL.appendingPathComponent("widget_photo.jpg")
                                    try? imgData.write(to: widgetURL)
                                    print("💾 Also synced image to widget_photo.jpg for Widget access.")
                                }
                            } catch {
                                print("⚠️ Failed to write to local fallback path: \(error)")
                            }
                        }
                        
                        if successWrite {
                            downloadSuccessful = true
                        }
                    } else {
                        print("⚠️ Downloaded data is not a valid image.")
                    }
                } catch {
                    print("⚠️ Failed to proactively download and cache flash image: \(error)")
                }
            }
            
            if flash.sender_id != currentUserId {
                if downloadSuccessful {
                    print("🔍 fetchFlashes: Sender ID \(flash.sender_id) is NOT current user \(currentUserId). Triggering ACK...")
                    await sendFlashAcknowledgement(flashId: flash.id)
                } else {
                    print("🔍 fetchFlashes: Download failed or could not write cache. Postponing ACK to prevent data loss.")
                }
            } else {
                print("🔍 fetchFlashes: Sender ID matches current user. No ACK required.")
            }
        }
        
        await MainActor.run {
            var merged = self.flashes
            for flash in decoded {
                if !merged.contains(where: { $0.id == flash.id }) {
                    merged.append(flash)
                }
            }
            merged.sort(by: { $0.createdDate > $1.createdDate })
            self.flashes = merged
            
            // If the latest flash is from our partner, update the partner's latest_photo_url!
            if let latestFlash = merged.first(where: { $0.sender_id != currentUserId }) {
                if var p = self.partner, p.id == latestFlash.sender_id {
                    p.latest_photo_url = latestFlash.photo_url
                    self.partner = p
                    print("🔄 Updated partner.latest_photo_url to: \(latestFlash.photo_url)")
                }
            }
            
            self.saveFlashesCache()
            print("💾 Merged flashes cache updated. Total count: \(self.flashes.count)")
        }
        return decoded
    }
    
    func sendFlashAcknowledgement(flashId: Int) async {
        print("🔍 sendFlashAcknowledgement: Sending ACK for flash ID \(flashId)...")
        guard let url = URL(string: "\(baseURL)/glimpse/flashes/\(flashId)/ack") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 sendFlashAcknowledgement: Server response status code: \(httpResponse.statusCode)")
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("🔍 sendFlashAcknowledgement: Server body response: \(responseStr)")
                }
                if httpResponse.statusCode == 200 {
                    print("👍 Acknowledged flash \(flashId) to server. File deleted from server SSD!")
                } else {
                    print("⚠️ Failed to acknowledge flash \(flashId)")
                }
            }
        } catch {
            print("❌ Error acknowledging flash \(flashId): \(error)")
        }
    }
    
    func updateUnreadCount() {
        let totalUnread = chatRooms.reduce(0) { $0 + $1.unread_count }
        unreadMessagesCount = totalUnread
    }
    
    func clearUnreadMessages() {
        let currentUserId = currentUser?.id ?? 0
        if currentUserId > 0 {
            let userDefaultsKey = "last_read_message_id_\(currentUserId)"
            if let lastMsg = latestFetchedMessages.last {
                UserDefaults.standard.set(lastMsg.id, forKey: userDefaultsKey)
            }
        }
        unreadMessagesCount = 0
    }
    
    func markMessagesAsRead(messageId: Int) async {
        guard let url = URL(string: "\(baseURL)/glimpse/chat/read") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["message_id": messageId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        _ = try? await URLSession.shared.data(for: request)
    }
    
    func sendChatMessage(text: String, roomId: Int? = nil) async throws -> ChatMessage {
        guard let url = URL(string: "\(baseURL)/glimpse/chat") else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        guard let token = userToken else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
        }
        
        let tempMessage = ChatMessage(
            id: 0,
            couple_id: 0,
            sender_id: currentUser?.id ?? 0,
            message: text,
            room_id: roomId,
            created_at: nil,
            updated_at: nil
        )
        let protoData = tempMessage.encodeProtobuf()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        request.addValue("application/x-protobuf", forHTTPHeaderField: "Accept")
        request.httpBody = protoData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to send message"])
        }
        
        guard let sentMsg = ChatMessage.decodeProtobuf(from: data) else {
            throw NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response Protobuf"])
        }
        
        return sentMsg
    }
    
    func uploadAudioMessage(fileUrl: URL, duration: TimeInterval, roomId: Int? = nil) async throws -> ChatMessage {
        guard let url = URL(string: "\(baseURL)/glimpse/chat/audio") else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        guard let token = userToken else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-protobuf", forHTTPHeaderField: "Accept")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Duration
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"duration\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(duration)\r\n".data(using: .utf8)!)
        
        // Room ID if present
        if let roomId = roomId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"room_id\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(roomId)\r\n".data(using: .utf8)!)
        }
        
        // Audio file
        if let audioData = try? Data(contentsOf: fileUrl) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to upload audio message"])
        }
        
        guard let sentMsg = ChatMessage.decodeProtobuf(from: data) else {
            throw NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response Protobuf"])
        }
        
        return sentMsg
    }

    func fetchChatRooms() async throws -> [GlimpseChatRoom] {
        guard let url = URL(string: "\(baseURL)/glimpse/chat-rooms") else { return [] }
        guard let token = userToken else { return [] }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }
        
        return try JSONDecoder().decode([GlimpseChatRoom].self, from: data)
    }

    func createChatRoom(name: String) async throws -> GlimpseChatRoom {
        guard let url = URL(string: "\(baseURL)/glimpse/chat-rooms") else {
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
        
        let body = ["name": name]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to create room"])
        }
        
        return try JSONDecoder().decode(GlimpseChatRoom.self, from: data)
    }

    func deleteChatRoom(roomId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/chat-rooms/\(roomId)") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to delete room"])
        }
    }

    func clearChatRoom(roomId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/chat-rooms/\(roomId)/clear") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to clear chat room"])
        }
    }

    func requestDeleteChatRoom(roomId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/chat-rooms/\(roomId)/request-delete") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to request room deletion"])
        }
    }

    func declineDeleteChatRoom(roomId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/chat-rooms/\(roomId)/decline-delete") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to decline room deletion"])
        }
    }

    func confirmDeleteChatRoom(roomId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/chat-rooms/\(roomId)/confirm-delete") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to confirm room deletion"])
        }
    }

    func renameChatRoom(roomId: Int, newName: String) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/chat-rooms/\(roomId)/rename") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = ["name": newName]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to rename room"])
        }
    }

    func updateChatRoomTheme(roomId: Int, themeColor: String?, backgroundColor: String?) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/chat-rooms/\(roomId)/theme") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var body: [String: Any] = [:]
        body["theme_color"] = themeColor as Any
        body["background_color"] = backgroundColor as Any
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to update room theme"])
        }
    }

    func updateProfile(name: String?, email: String?, bornDate: String?, gender: String?, photo: UIImage?) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/user/update") else { return false }
        guard let token = userToken else { return false }
        
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
        
        if let bornDate = bornDate {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"born_date\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(bornDate)\r\n".data(using: .utf8)!)
        }
        
        if let gender = gender {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"gender\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(gender)\r\n".data(using: .utf8)!)
        }
        
        if let photo = photo, let imageData = photo.cropAndCompressAvatar(targetBytes: 10_000) {
            let isWebP = imageData.isWebP
            let filename = isWebP ? "avatar.webp" : "avatar.jpg"
            let contentType = isWebP ? "image/webp" : "image/jpeg"
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"profile_photo\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
        }
        
        try await fetchState()
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let pending = json["email_change_pending"] as? Bool {
            return pending
        }
        return false
    }

    func updateAnniversary(date: Date) async throws {
        guard let url = URL(string: "\(baseURL)/couple/anniversary") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        
        let body = ["anniversary_date": formatter.string(from: date)]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            print("❌ updateAnniversary failed. Status: \((response as? HTTPURLResponse)?.statusCode ?? -1), Body: \(bodyStr)")
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Update failed: \(bodyStr)"])
        }
        
        try await fetchState()
    }
    
    // MARK: - SCHEDULE PLANNER API Calls
    func createSchedule(title: String, date: Date, reminderMinutes: Int) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/schedule") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        
        let body: [String: Any] = [
            "title": title,
            "scheduled_at": formatter.string(from: date),
            "reminder_minutes": reminderMinutes
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            print("❌ createSchedule failed: \(bodyStr)")
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to create kencan: \(bodyStr)"])
        }
        
        try await fetchState()
    }
    
    func respondToSchedule(id: Int, accept: Bool) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/schedule/\(id)/respond") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = ["response": accept ? "accepted" : "declined"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            print("❌ respondToSchedule failed: \(bodyStr)")
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to respond to kencan: \(bodyStr)"])
        }
        
        try await fetchState()
    }
    
    func fetchSchedules() async throws -> [GlimpseSchedule] {
        guard let url = URL(string: "\(baseURL)/glimpse/schedules") else { return [] }
        guard let token = userToken else { return [] }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            print("❌ fetchSchedules failed: \(bodyStr)")
            return []
        }
        
        return try JSONDecoder().decode([GlimpseSchedule].self, from: data)
    }
    
    func deleteSchedule(id: Int) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/schedule/\(id)") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            print("❌ deleteSchedule failed: \(bodyStr)")
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to delete schedule: \(bodyStr)"])
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
            UserDefaults(suiteName: "group.glimpse.app")?.set(token, forKey: "auth_token")
            withAnimation {
                self.isAuthenticated = true
            }
            Task {
                try? await self.fetchState()
                self.connectWebSocket()
            }
        }
    }
    
    func register(name: String, email: String, bornDate: String?, gender: String?, password: String) async throws {
        guard let url = URL(string: "\(baseURL)/register") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var body: [String: Any] = ["name": name, "email": email, "password": password]
        if let bd = bornDate {
            body["born_date"] = bd
        }
        if let g = gender {
            body["gender"] = g
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Registration failed"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["access_token"] as? String {
            UserDefaults.standard.set(token, forKey: "auth_token")
            UserDefaults(suiteName: "group.glimpse.app")?.set(token, forKey: "auth_token")
            withAnimation {
                self.isAuthenticated = true
            }
            Task {
                try? await self.fetchState()
                self.connectWebSocket()
            }
        }
    }
    
    func forgotPassword(email: String) async throws {
        guard let url = URL(string: "\(baseURL)/forgot-password") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                errorMsg = message
            } else {
                errorMsg = "Failed to send reset code"
            }
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    func resetPassword(email: String, otp: String, newPassword: String) async throws {
        guard let url = URL(string: "\(baseURL)/reset-password") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = ["email": email, "otp": otp, "password": newPassword]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                errorMsg = message
            } else {
                errorMsg = "Failed to reset password"
            }
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    func verifyEmail(otp: String) async throws {
        guard let url = URL(string: "\(baseURL)/verify-email") else { return }
        guard let token = userToken else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = ["otp": otp]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                errorMsg = message
            } else {
                errorMsg = "Invalid or expired verification code"
            }
            throw NSError(domain: "Auth", code: 422, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        try await fetchState()
    }
    
    func resendVerification() async throws {
        guard let url = URL(string: "\(baseURL)/resend-verification") else { return }
        guard let token = userToken else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                errorMsg = message
            } else {
                errorMsg = "Failed to resend verification code"
            }
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    func verifyEmailChange(otp: String) async throws {
        guard let url = URL(string: "\(baseURL)/user/update/verify-email") else { return }
        guard let token = userToken else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = ["otp": otp]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                errorMsg = message
            } else {
                errorMsg = "Failed to verify email change"
            }
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        try await fetchState()
    }
    
    func resendEmailChangeVerification() async throws {
        guard let url = URL(string: "\(baseURL)/user/update/resend-email-change") else { return }
        guard let token = userToken else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                errorMsg = message
            } else {
                errorMsg = "Failed to resend email change verification"
            }
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let url = URL(string: "\(baseURL)/user/change-password") else { return }
        guard let token = userToken else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = ["current_password": currentPassword, "new_password": newPassword]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                errorMsg = message
            } else {
                errorMsg = "Failed to update password"
            }
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    func sendDeleteAccountOtp() async throws {
        guard let url = URL(string: "\(baseURL)/user/delete/send-otp") else { return }
        guard let token = userToken else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                errorMsg = message
            } else {
                errorMsg = "Failed to send deletion OTP"
            }
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    func deleteAccount(method: String, password: String?, otp: String?, agreement: Bool) async throws {
        guard let url = URL(string: "\(baseURL)/user/delete") else { return }
        guard let token = userToken else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var body: [String: Any] = ["method": method, "agreement": agreement]
        if let pwd = password {
            body["password"] = pwd
        }
        if let o = otp {
            body["otp"] = o
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                errorMsg = message
            } else {
                errorMsg = "Failed to delete account"
            }
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        logout()
    }
    
    func reportBug(title: String, description: String, deviceInfo: String?) async throws {
        guard let url = URL(string: "\(baseURL)/user/report-bug") else { return }
        guard let token = userToken else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var body: [String: Any] = ["title": title, "description": description]
        if let devInfo = deviceInfo {
            body["device_info"] = devInfo
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                errorMsg = message
            } else {
                errorMsg = "Failed to report bug"
            }
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    func logout() {
        self.disconnectWebSocket()
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults(suiteName: "group.glimpse.app")?.removeObject(forKey: "auth_token")
        
        let sharedDefaults = UserDefaults(suiteName: "group.glimpse.app")
        sharedDefaults?.removeObject(forKey: "latest_partner_data")
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
            let fileURL = groupURL.appendingPathComponent("widget_photo.jpg")
            try? FileManager.default.removeItem(at: fileURL)
        }
        WidgetCenter.shared.reloadAllTimelines()
        
        // Clear SQLite database and in-memory caches
        GlimpseDatabase.shared.clearAllMessages()
        UserDefaults.standard.removeObject(forKey: "glimpse_cached_chat_rooms")
        self.latestFetchedMessages = []
        self.roomMessagesCache = [:]
        self.chatRooms = []
        
        withAnimation {
            self.isAuthenticated = false
        }
    }
    
    @MainActor
    func handleSessionTerminated() {
        self.disconnectWebSocket()
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults(suiteName: "group.glimpse.app")?.removeObject(forKey: "auth_token")
        
        let sharedDefaults = UserDefaults(suiteName: "group.glimpse.app")
        sharedDefaults?.removeObject(forKey: "latest_partner_data")
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
            let fileURL = groupURL.appendingPathComponent("widget_photo.jpg")
            try? FileManager.default.removeItem(at: fileURL)
        }
        WidgetCenter.shared.reloadAllTimelines()
        
        // Clear SQLite database and in-memory caches
        GlimpseDatabase.shared.clearAllMessages()
        UserDefaults.standard.removeObject(forKey: "glimpse_cached_chat_rooms")
        self.latestFetchedMessages = []
        self.roomMessagesCache = [:]
        self.chatRooms = []
        
        withAnimation {
            self.isAuthenticated = false
        }
        
        self.showSessionTerminatedAlert = true
    }
    
    func checkResponseStatus(_ response: URLResponse) async -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        if httpResponse.statusCode == 401 {
            await handleSessionTerminated()
            return false
        }
        return httpResponse.statusCode == 200
    }
    
    // MARK: - OUTBOX / OFFLINE FLASH UPLOAD
    struct PendingFlash: Codable {
        let photoFileName: String
        let latitude: Double?
        let longitude: Double?
        let battery: Int?
        let note: String?
        let locationName: String?
        let timestamp: Double
    }
    
    func savePendingFlash(image: UIImage, latitude: Double?, longitude: Double?, battery: Int?, note: String?, locationName: String?) {
        guard let finalData = image.compressedForApp(maxDimension: 600, targetBytes: 50_000) else { return }
        
        let isWebP = finalData.isWebP
        let fileExtension = isWebP ? "webp" : "jpg"
        let fileName = "pending_flash_\(UUID().uuidString).\(fileExtension)"
        let fileManager = FileManager.default
        guard let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let fileURL = cachesDir.appendingPathComponent(fileName)
        
        do {
            try finalData.write(to: fileURL)
            
            let pending = PendingFlash(
                photoFileName: fileName,
                latitude: latitude,
                longitude: longitude,
                battery: battery,
                note: note,
                locationName: locationName,
                timestamp: Date().timeIntervalSince1970
            )
            
            var list = getPendingFlashes()
            list.append(pending)
            if let encoded = try? JSONEncoder().encode(list) {
                UserDefaults.standard.set(encoded, forKey: "glimpse_pending_flashes")
            }
            print("💾 Saved Flash to local Outbox successfully!")
        } catch {
            print("❌ Failed to save pending flash locally: \(error)")
        }
    }
    
    func getPendingFlashes() -> [PendingFlash] {
        guard let data = UserDefaults.standard.data(forKey: "glimpse_pending_flashes") else { return [] }
        return (try? JSONDecoder().decode([PendingFlash].self, from: data)) ?? []
    }
    
    func cancelFlashUpload() {
        uploadTask?.cancel()
        uploadTask = nil
        
        // Truly clear the Outbox: Delete all pending files from caches directory
        let list = getPendingFlashes()
        let fileManager = FileManager.default
        if let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            for pending in list {
                let fileURL = cachesDir.appendingPathComponent(pending.photoFileName)
                try? fileManager.removeItem(at: fileURL)
            }
        }
        
        // Remove the queue from UserDefaults
        UserDefaults.standard.removeObject(forKey: "glimpse_pending_flashes")
        
        isUploadingFlash = false
        uploadProgress = 0.0
        uploadFailed = false
        uploadSuccess = false
        uploadQueueTotal = 0
        uploadQueueCurrent = 0
        print("🗑️ Pending flash queue cancelled and deleted from Outbox successfully!")
    }
    
    func processPendingFlashes() {
        let list = getPendingFlashes()
        guard !list.isEmpty else { return }
        guard !isUploadingFlash else { return }
        
        uploadTask = Task {
            await MainActor.run {
                self.isUploadingFlash = true
                self.uploadFailed = false
                self.uploadSuccess = false
                self.uploadProgress = 0.0
                self.uploadQueueTotal = list.count
                self.uploadQueueCurrent = 0
            }
            
            let fileManager = FileManager.default
            guard let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                await MainActor.run { self.isUploadingFlash = false }
                return
            }
            
            var remainingFlashes: [PendingFlash] = []
            var completedCount = 0
            
            for pending in list {
                if Task.isCancelled { break }
                let fileURL = cachesDir.appendingPathComponent(pending.photoFileName)
                guard fileManager.fileExists(atPath: fileURL.path) else { continue }
                
                await MainActor.run {
                    self.uploadQueueCurrent = completedCount + 1
                    self.uploadProgress = 0.0
                }
                
                do {
                    guard let imageData = try? Data(contentsOf: fileURL) else {
                        try? fileManager.removeItem(at: fileURL)
                        continue
                    }
                    
                    try await uploadPhotoInternal(
                        imageData,
                        latitude: pending.latitude,
                        longitude: pending.longitude,
                        battery: pending.battery,
                        note: pending.note,
                        locationName: pending.locationName
                    )
                    
                    try? fileManager.removeItem(at: fileURL)
                    completedCount += 1
                    print("✅ Outbox Flash \(completedCount)/\(list.count) uploaded successfully!")
                } catch {
                    print("❌ Failed to upload outbox flash: \(error)")
                    remainingFlashes.append(pending)
                    await MainActor.run {
                        self.uploadFailed = true
                    }
                }
            }
            
            await MainActor.run {
                if let encoded = try? JSONEncoder().encode(remainingFlashes) {
                    UserDefaults.standard.set(encoded, forKey: "glimpse_pending_flashes")
                }
                
                if !self.uploadFailed {
                    self.uploadSuccess = true
                    self.uploadProgress = 1.0
                    self.uploadQueueTotal = 0
                    self.uploadQueueCurrent = 0
                    
                    // Keep success banner visible for 1.8 seconds showing checkmark/success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            self.isUploadingFlash = false
                            self.uploadSuccess = false
                            self.uploadProgress = 0.0
                        }
                    }
                } else {
                    self.isUploadingFlash = false
                    self.uploadQueueTotal = 0
                    self.uploadQueueCurrent = 0
                    // Auto-clear failed banner after 4 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            self.uploadFailed = false
                            self.uploadProgress = 0.0
                        }
                    }
                }
            }
        }
    }
    
    func uploadPhoto(_ image: UIImage, latitude: Double? = nil, longitude: Double? = nil, battery: Int? = nil, note: String? = nil, locationName: String? = nil) async throws {
        // 1. Save to outbox queue first for complete offline & crash resilience!
        savePendingFlash(image: image, latitude: latitude, longitude: longitude, battery: battery, note: note, locationName: locationName)
        
        // 2. Process queue immediately
        processPendingFlashes()
    }
    
    private func uploadPhotoInternal(_ photoData: Data, latitude: Double? = nil, longitude: Double? = nil, battery: Int? = nil, note: String? = nil, locationName: String? = nil) async throws {
        // 1. Request Background Task Assertion from iOS to protect upload from screen lock / app minimizes!
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "UploadFlash") {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        defer {
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }
        
        await MainActor.run {
            self.uploadProgress = 0.1
        }
        
        guard let url = URL(string: "\(baseURL)/glimpse/photo") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        await MainActor.run {
            self.uploadProgress = 0.2
        }
        
        // Skip compression here because photoData is ALREADY compressed before writing to cache!
        
        await MainActor.run {
            self.uploadProgress = 0.3
        }
        
        let isWebP = photoData.isWebP
        let filename = isWebP ? "flash.webp" : "flash.jpg"
        let contentType = isWebP ? "image/webp" : "image/jpeg"
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        body.append(photoData)
        body.append("\r\n".data(using: .utf8)!)
        
        if let lat = latitude {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"latitude\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(lat)\r\n".data(using: .utf8)!)
        }
        
        if let lon = longitude {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"longitude\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(lon)\r\n".data(using: .utf8)!)
        }
        
        if let batt = battery {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"battery_level\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(batt)\r\n".data(using: .utf8)!)
        }
        
        if let status = note {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"status_note\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(status)\r\n".data(using: .utf8)!)
        }
        
        if let loc = locationName {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"location_name\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(loc)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        await MainActor.run {
            self.uploadProgress = 0.5
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        await MainActor.run {
            self.uploadProgress = 0.8
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
        
        await MainActor.run {
            self.uploadProgress = 0.9
        }
        
        var photoUrl = ""
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let pUrl = json["photo_url"] as? String {
            photoUrl = pUrl
        }
        
        let caption = note ?? ""
        let location = locationName ?? ""
        let messageText = "📷 Sent a Flash! [FLASH_ATTACHMENT]|\(photoUrl)|\(caption)|\(location)"
        
        // Fire off companion requests asynchronously in parallel without blocking the main upload completion
        Task {
            if let sentMsg = try? await sendChatMessage(text: messageText) {
                // Immediately mark as read from sender's side to prevent self-unread badge
                await markMessagesAsRead(messageId: sentMsg.id)
                
                // Update local unread count to 0 for the main room
                await MainActor.run {
                    if let mainRoomIndex = self.chatRooms.firstIndex(where: { $0.is_main }) {
                        self.chatRooms[mainRoomIndex].unread_count = 0
                        self.updateUnreadCount()
                    }
                }
            }
            try? await fetchState()
            _ = try? await fetchFlashes()
        }
        
        await MainActor.run {
            self.uploadProgress = 1.0
        }
    }
    
    func triggerServerLoveBurst(reaction: String? = nil) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/love-burst") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let reaction = reaction {
            let body: [String: String] = ["reaction": reaction]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Love burst failed"])
        }
    }
    
    func triggerServerBump() async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/bump") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Bump failed"])
        }
        
        struct BumpResponse: Codable {
            let total_meetings: Int
        }
        if let res = try? JSONDecoder().decode(BumpResponse.self, from: data) {
            await MainActor.run {
                self.totalMeetings = res.total_meetings
            }
        }
    }
    
    func sendTypingStatus(isTyping: Bool, roomId: Int? = nil) {
        guard isAuthenticated else { return }
        
        Task {
            guard let url = URL(string: "\(baseURL)/glimpse/typing") else { return }
            guard let token = userToken else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            var body: [String: Any] = ["is_typing": isTyping]
            if let rId = roomId {
                body["room_id"] = rId
            }
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            _ = try? await URLSession.shared.data(for: request)
        }
    }
    
    // MARK: - CLEAR IMAGE CACHE
    func clearImageCache() {
        let fileManager = FileManager.default
        
        // 1. Clear standard Apple URL Cache
        URLCache.shared.removeAllCachedResponses()
        
        // 2. Clear App Group Cache files
        if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
            if let files = try? fileManager.contentsOfDirectory(at: groupURL, includingPropertiesForKeys: nil) {
                for file in files {
                    if file.lastPathComponent.hasPrefix("img_cache_") {
                        try? fileManager.removeItem(at: file)
                    }
                }
            }
        }
        
        // 3. Clear standard Caches directory files
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            if let files = try? fileManager.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil) {
                for file in files {
                    if file.lastPathComponent.hasPrefix("img_cache_") {
                        try? fileManager.removeItem(at: file)
                    }
                }
            }
        }
        
        print("✅ Image cache successfully cleared!")
    }
    
    func getImageCacheSize() -> String {
        let fileManager = FileManager.default
        var totalBytes: Int64 = 0
        
        // 1. App Group Cache files
        if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
            if let files = try? fileManager.contentsOfDirectory(at: groupURL, includingPropertiesForKeys: [.fileSizeKey]) {
                for file in files {
                    if file.lastPathComponent.hasPrefix("img_cache_") {
                        if let resourceValues = try? file.resourceValues(forKeys: [.fileSizeKey]),
                           let size = resourceValues.fileSize {
                            totalBytes += Int64(size)
                        }
                    }
                }
            }
        }
        
        // 2. Standard Caches directory files
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            if let files = try? fileManager.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: [.fileSizeKey]) {
                for file in files {
                    if file.lastPathComponent.hasPrefix("img_cache_") {
                        if let resourceValues = try? file.resourceValues(forKeys: [.fileSizeKey]),
                           let size = resourceValues.fileSize {
                            totalBytes += Int64(size)
                        }
                    }
                }
            }
        }
        
        if totalBytes == 0 {
            return "0 KB"
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
}

extension Data {
    var isWebP: Bool {
        guard self.count >= 12 else { return false }
        let riff = self.subdata(in: 0..<4)
        let webp = self.subdata(in: 8..<12)
        return riff == Data([0x52, 0x49, 0x46, 0x46]) && webp == Data([0x57, 0x45, 0x42, 0x50])
    }
}

extension UIImage {
    func compressedForApp(maxDimension: CGFloat, targetBytes: Int) -> Data? {
        // Step 1: Fast resize using integer pixel math (no float rounding loops)
        let targetSize: CGSize
        let w = self.size.width
        let h = self.size.height
        if w > maxDimension || h > maxDimension {
            let scale = maxDimension / max(w, h)
            targetSize = CGSize(width: (w * scale).rounded(), height: (h * scale).rounded())
        } else {
            targetSize = self.size
        }
        
        // Render once at target size with EXACT pixel mapping (scale = 1.0)
        // Without this, iOS renders at @3x screen scale (600px becomes 1800px!)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resizedImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        // Try WebP encoding first (native support in iOS 17+)
        if let webpData = resizedImage.webpData(quality: 0.5), webpData.count <= targetBytes {
            return webpData
        }
        
        // Fallback to JPEG if WebP is not supported or still too large
        if let jpegData = resizedImage.jpegData(compressionQuality: 0.5), jpegData.count <= targetBytes {
            return jpegData
        }
        
        // Step 3: Binary search quality between 0.1 and 0.5 to hit target size fast (max 5 iterations)
        var low: CGFloat = 0.1
        var high: CGFloat = 0.5
        // Start best at lowest quality 0.1 so if we fail to hit target, we at least return the smallest possible size
        var best: Data? = resizedImage.webpData(quality: 0.1) ?? resizedImage.jpegData(compressionQuality: 0.1)
        
        for _ in 0..<5 {
            let mid = (low + high) / 2.0
            if let data = resizedImage.webpData(quality: mid) {
                if data.count <= targetBytes {
                    best = data
                    low = mid  // try higher quality
                } else {
                    high = mid // too big, compress more
                }
            } else if let data = resizedImage.jpegData(compressionQuality: mid) {
                if data.count <= targetBytes {
                    best = data
                    low = mid
                } else {
                    high = mid
                }
            } else {
                break
            }
        }
        
        return best
    }
    
    func cropAndCompressAvatar(targetSize: CGSize = CGSize(width: 200, height: 200), targetBytes: Int = 10_000) -> Data? {
        let w = self.size.width
        let h = self.size.height
        let side = min(w, h)
        let cropRect = CGRect(
            x: (w - side) / 2.0,
            y: (h - side) / 2.0,
            width: side,
            height: side
        )
        
        guard let cgImage = self.cgImage?.cropping(to: cropRect) else { return nil }
        let croppedImage = UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resizedImage = renderer.image { _ in
            croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        // Try WebP first
        if let webpData = resizedImage.webpData(quality: 0.5), webpData.count <= targetBytes {
            return webpData
        }
        // Try JPEG fallback
        if let jpegData = resizedImage.jpegData(compressionQuality: 0.5), jpegData.count <= targetBytes {
            return jpegData
        }
        
        // Binary search quality
        var low: CGFloat = 0.05
        var high: CGFloat = 0.5
        var best: Data? = resizedImage.webpData(quality: 0.05) ?? resizedImage.jpegData(compressionQuality: 0.05)
        
        for _ in 0..<8 {
            let mid = (low + high) / 2.0
            if let data = resizedImage.webpData(quality: mid) {
                if data.count <= targetBytes {
                    best = data
                    low = mid
                } else {
                    high = mid
                }
            } else if let data = resizedImage.jpegData(compressionQuality: mid) {
                if data.count <= targetBytes {
                    best = data
                    low = mid
                } else {
                    high = mid
                }
            } else {
                break
            }
        }
        
        return best
    }
    
    private func webpData(quality: CGFloat) -> Data? {
        guard let cgImage = self.cgImage else { return nil }
        let data = NSMutableData()
        let typeID = "public.webp" as CFString
        
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, typeID, 1, nil) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality as CFNumber
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        if CGImageDestinationFinalize(destination) {
            return data as Data
        }
        return nil
    }
}
#endif
