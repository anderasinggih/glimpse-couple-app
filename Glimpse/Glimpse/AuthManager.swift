#if !WIDGET
import Foundation
import SwiftUI
import WidgetKit
import AudioToolbox
import Combine
import ImageIO
import UniformTypeIdentifiers
import SQLite3

// MARK: - SQLite Database Manager
class GlimpseDatabase {
    static let shared = GlimpseDatabase()
    private var db: OpaquePointer?
    
    private init() {
        openDatabase()
        createTable()
    }
    
    private func openDatabase() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ SQLite: Failed to find documents directory")
            return
        }
        let fileURL = documentsDirectory.appendingPathComponent("glimpse_chat.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("❌ SQLite: Error opening database")
        } else {
            print("✅ SQLite: Opened connection to database at \(fileURL.path)")
        }
    }
    
    private func createTable() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS chat_messages (
            id INTEGER PRIMARY KEY,
            couple_id INTEGER,
            sender_id INTEGER,
            message TEXT,
            room_id INTEGER,
            created_at TEXT,
            updated_at TEXT
        );
        """
        
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("✅ SQLite: chat_messages table created or verified.")
            } else {
                print("❌ SQLite: chat_messages table could not be created.")
            }
        } else {
            print("❌ SQLite: CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    func saveMessage(_ msg: ChatMessage) {
        let insertStatementString = """
        INSERT OR REPLACE INTO chat_messages (id, couple_id, sender_id, message, room_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var insertStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(insertStatement, 1, Int32(msg.id))
            sqlite3_bind_int(insertStatement, 2, Int32(msg.couple_id))
            sqlite3_bind_int(insertStatement, 3, Int32(msg.sender_id))
            sqlite3_bind_text(insertStatement, 4, (msg.message as NSString).utf8String, -1, nil)
            
            if let roomId = msg.room_id {
                sqlite3_bind_int(insertStatement, 5, Int32(roomId))
            } else {
                sqlite3_bind_null(insertStatement, 5)
            }
            
            sqlite3_bind_text(insertStatement, 6, (msg.created_at as NSString? ?? "" as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 7, (msg.updated_at as NSString? ?? "" as NSString).utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                // Successfully inserted or updated
            } else {
                print("❌ SQLite: Could not insert row.")
            }
        } else {
            print("❌ SQLite: INSERT statement could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
    }
    
    func saveMessages(_ messages: [ChatMessage]) {
        // Run in transaction for high performance bulk inserts
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)
        for msg in messages {
            saveMessage(msg)
        }
        sqlite3_exec(db, "COMMIT TRANSACTION", nil, nil, nil)
    }
    
    func getMessages(forRoomId roomId: Int?) -> [ChatMessage] {
        let queryStatementString: String
        if let rId = roomId {
            queryStatementString = "SELECT id, couple_id, sender_id, message, room_id, created_at, updated_at FROM chat_messages WHERE room_id = ? ORDER BY id ASC;"
        } else {
            queryStatementString = "SELECT id, couple_id, sender_id, message, room_id, created_at, updated_at FROM chat_messages WHERE room_id IS NULL ORDER BY id ASC;"
        }
        
        var queryStatement: OpaquePointer?
        var messages: [ChatMessage] = []
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            if let rId = roomId {
                sqlite3_bind_int(queryStatement, 1, Int32(rId))
            }
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let coupleId = Int(sqlite3_column_int(queryStatement, 1))
                let senderId = Int(sqlite3_column_int(queryStatement, 2))
                
                guard let messageTextBytes = sqlite3_column_text(queryStatement, 3) else { continue }
                let message = String(cString: messageTextBytes)
                
                var roomId: Int? = nil
                if sqlite3_column_type(queryStatement, 4) != SQLITE_NULL {
                    roomId = Int(sqlite3_column_int(queryStatement, 4))
                }
                
                let createdAt: String?
                if let createdAtBytes = sqlite3_column_text(queryStatement, 5) {
                    createdAt = String(cString: createdAtBytes)
                } else {
                    createdAt = nil
                }
                
                let updatedAt: String?
                if let updatedAtBytes = sqlite3_column_text(queryStatement, 6) {
                    updatedAt = String(cString: updatedAtBytes)
                } else {
                    updatedAt = nil
                }
                
                let chatMessage = ChatMessage(
                    id: id,
                    couple_id: coupleId,
                    sender_id: senderId,
                    message: message,
                    room_id: roomId,
                    created_at: createdAt,
                    updated_at: updatedAt
                )
                messages.append(chatMessage)
            }
        } else {
            print("❌ SQLite: SELECT statement could not be prepared.")
        }
        sqlite3_finalize(queryStatement)
        return messages
    }
    
    func clearAllMessages() {
        let deleteString = "DELETE FROM chat_messages;"
        var deleteStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteString, -1, &deleteStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("✅ SQLite: All messages cleared.")
            }
        }
        sqlite3_finalize(deleteStatement)
    }
}

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
    var lastLoveBurstReaction: String? = nil
    var activeSchedule: GlimpseSchedule? = nil
    var pendingInvitation: GlimpseSchedule? = nil
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
    private var webSocketTask: URLSessionWebSocketTask?
    var isWebSocketConnected = false
    var isPartnerTyping = false
    private var shouldReconnect = true
    private var reconnectInterval: TimeInterval = 2.0
    private var pingTimer: Timer?
    private var isConnecting = false
    
    var userToken: String? {
        UserDefaults.standard.string(forKey: "auth_token")
    }
    
    let baseURL = "https://api.galleryfortwo.my.id/api"
    
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
    
    func pushLocationAndStatus(latitude: Double?, longitude: Double?, locationName: String?) {
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
                wifiBssid: wifi
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

    func updateProfile(name: String?, email: String?, bornDate: String?, gender: String?, photo: UIImage?) async throws {
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
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        await MainActor.run {
            self.uploadProgress = 0.8
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
        
        await MainActor.run {
            self.uploadProgress = 0.9
        }
        
        // Fire off companion requests asynchronously in parallel without blocking the main upload completion
        Task {
            if let sentMsg = try? await sendChatMessage(text: "📷 Sent a Flash! [FLASH_ATTACHMENT]") {
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
    
    func disconnectWebSocket() {
        shouldReconnect = false
        isConnecting = false
        stopPingTimer()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        DispatchQueue.main.async {
            self.isWebSocketConnected = false
        }
        print("🔌 WebSocket disconnected manually.")
    }
    
    private func startPingTimer() {
        stopPingTimer()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
                self?.sendPingFrame()
            }
        }
    }
    
    private func stopPingTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.pingTimer?.invalidate()
            self?.pingTimer = nil
        }
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
                self.isConnecting = false
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
            case "pusher:ping":
                self.sendPongFrame()
                
            case "pusher:pong":
                print("📥 Received websocket pong.")
                
            case "pusher:connection_established":
                print("✅ WebSocket handshake established!")
                self.isConnecting = false
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
                    struct ProtobufPayload: Codable {
                        let pb: String?
                    }
                    if let pbPayload = try? JSONDecoder().decode(ProtobufPayload.self, from: eventData),
                       let pbString = pbPayload.pb,
                       let update = GlimpsePartnerStateUpdate.decodeProtobuf(from: pbString) {
                        DispatchQueue.main.async {
                            if var p = self.partner, p.id == update.userId {
                                if let lat = update.latitude { p.latitude = lat }
                                if let lon = update.longitude { p.longitude = lon }
                                if let batt = update.batteryLevel { p.battery_level = batt }
                                if let char = update.isCharging { p.is_charging = char }
                                if let lastSeen = update.lastSeenMessageId { p.last_seen_message_id = lastSeen }
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
                            DispatchQueue.main.async {
                                // Wake up GPS immediately to get fresh satellite coordinates
                                LiveLocationManager.shared.forceWakeGPSAndSync(bypassCooldown: true)
                            }
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
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name("GlimpseChatRoomCreated"), object: payload.room)
                        }
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
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name("GlimpseChatRoomDeleted"), object: payload.room_id)
                        }
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
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: Notification.Name("GlimpseChatRoomUpdated"),
                                object: nil,
                                userInfo: ["room_id": payload.room_id, "name": payload.name]
                            )
                        }
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
                        DispatchQueue.main.async {
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
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: Notification.Name("GlimpseChatRoomDeleteStatusChanged"),
                                object: nil,
                                userInfo: ["room_id": payload.room_id, "delete_requested_by": payload.delete_requested_by as Any]
                            )
                        }
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
                        
                        DispatchQueue.main.async {
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
                        DispatchQueue.main.async {
                            // Update lastLoveBurstTimestamp in real-time!
                            self.lastLoveBurstReaction = payload.reaction
                            self.lastLoveBurstTimestamp = payload.timestamp
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
                        DispatchQueue.main.async {
                            // Update partner typing status ONLY if it comes from the partner, not me!
                            if state.userId != self.currentUser?.id {
                                self.isPartnerTyping = state.isTyping
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
    
    // MARK: - MESSAGES CACHING
    func saveMessagesCache() {
        GlimpseDatabase.shared.saveMessages(latestFetchedMessages)
    }
    
    func loadCachedMessages() {
        // Clean up old legacy UserDefaults cache if present
        if UserDefaults.standard.object(forKey: "glimpse_cached_messages") != nil {
            UserDefaults.standard.removeObject(forKey: "glimpse_cached_messages")
        }
        
        // Clean up legacy JSON cache file if present
        let fileManager = FileManager.default
        if let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let jsonURL = cacheDirectory.appendingPathComponent("glimpse_messages_cache.json")
            if fileManager.fileExists(atPath: jsonURL.path) {
                try? fileManager.removeItem(at: jsonURL)
            }
        }
        
        // Load main room messages from native SQLite database
        self.latestFetchedMessages = GlimpseDatabase.shared.getMessages(forRoomId: nil)
    }
    
    func saveChatRoomsCache() {
        if let encoded = try? JSONEncoder().encode(chatRooms) {
            UserDefaults.standard.set(encoded, forKey: "glimpse_cached_chat_rooms")
        }
    }
    
    func loadCachedChatRooms() {
        if let data = UserDefaults.standard.data(forKey: "glimpse_cached_chat_rooms"),
           let rooms = try? JSONDecoder().decode([GlimpseChatRoom].self, from: data) {
            self.chatRooms = rooms
        }
    }
    
    func saveFlashesCache() {
        if let encoded = try? JSONEncoder().encode(flashes) {
            UserDefaults.standard.set(encoded, forKey: "glimpse_cached_flashes")
        }
    }
    
    func loadCachedFlashes() {
        if let data = UserDefaults.standard.data(forKey: "glimpse_cached_flashes"),
           let decoded = try? JSONDecoder().decode([GlimpseFlash].self, from: data) {
            self.flashes = decoded
        }
    }
    
    func getCachedMessages(for roomId: Int?) -> [ChatMessage] {
        if let rId = roomId {
            if let inMemory = roomMessagesCache[rId], !inMemory.isEmpty {
                return inMemory
            }
            let fromDb = GlimpseDatabase.shared.getMessages(forRoomId: rId)
            roomMessagesCache[rId] = fromDb
            return fromDb
        } else {
            if !latestFetchedMessages.isEmpty {
                return latestFetchedMessages
            }
            let fromDb = GlimpseDatabase.shared.getMessages(forRoomId: nil)
            latestFetchedMessages = fromDb
            return fromDb
        }
    }
    
    // MARK: - SESSION CACHING
    private func saveSessionCache(_ data: Data) {
        UserDefaults.standard.set(data, forKey: "cached_couple_response")
    }
    
    private func loadCachedSession() {
        guard let cachedData = UserDefaults.standard.data(forKey: "cached_couple_response") else { return }
        do {
            let responseData = try JSONDecoder().decode(CoupleResponse.self, from: cachedData)
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
            
            // Mark loaded so that it doesn't show loading spinner if cached data is present!
            self.isInitialStateLoaded = true
        } catch {
            print("❌ Failed to decode cached session: \(error)")
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
