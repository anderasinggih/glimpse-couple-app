#if !WIDGET
import Foundation
import SQLite3
import SwiftUI

// MARK: - SQLite Database Manager
// MARK: - SQLite Database Manager
class GlimpseDatabase {
    static let shared = GlimpseDatabase()
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "group.glimpse.database", qos: .background)
    
    private init() {
        dbQueue.sync {
            openDatabase()
            createTable()
        }
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
    
    func closeAndReplaceDatabase(withTempURL tempURL: URL) -> Bool {
        return dbQueue.sync {
            // Close connection
            if db != nil {
                sqlite3_close(db)
                db = nil
            }
            
            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return false
            }
            let fileURL = documentsDirectory.appendingPathComponent("glimpse_chat.sqlite")
            
            do {
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
                try fileManager.copyItem(at: tempURL, to: fileURL)
                
                // Reopen connection
                if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
                    print("❌ SQLite: Error reopening database after restore")
                    return false
                }
                print("✅ SQLite: Reopened connection to database after restore")
                return true
            } catch {
                print("❌ SQLite: Failed to replace database file: \(error)")
                return false
            }
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
        }
        sqlite3_finalize(createTableStatement)
        
        let createFlashesTableString = """
        CREATE TABLE IF NOT EXISTS flashes (
            id INTEGER PRIMARY KEY,
            sender_id INTEGER,
            sender_name TEXT,
            photo_url TEXT,
            latitude REAL,
            longitude REAL,
            location_name TEXT,
            status_note TEXT,
            battery_level INTEGER,
            created_at TEXT
        );
        """
        
        var createFlashesStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createFlashesTableString, -1, &createFlashesStatement, nil) == SQLITE_OK {
            if sqlite3_step(createFlashesStatement) == SQLITE_DONE {
                print("✅ SQLite: flashes table created or verified.")
            } else {
                print("❌ SQLite: flashes table could not be created.")
            }
        }
        sqlite3_finalize(createFlashesStatement)
    }
    
    func saveMessage(_ msg: ChatMessage) {
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            let insertStatementString = """
            INSERT OR REPLACE INTO chat_messages (id, couple_id, sender_id, message, room_id, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            """
            
            var insertStatement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
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
    }
    
    func saveMessages(_ messages: [ChatMessage]) {
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            // Run in transaction for high performance bulk inserts
            sqlite3_exec(self.db, "BEGIN TRANSACTION", nil, nil, nil)
            for msg in messages {
                let insertStatementString = """
                INSERT OR REPLACE INTO chat_messages (id, couple_id, sender_id, message, room_id, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?);
                """
                
                var insertStatement: OpaquePointer?
                if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
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
                    
                    _ = sqlite3_step(insertStatement)
                }
                sqlite3_finalize(insertStatement)
            }
            sqlite3_exec(self.db, "COMMIT TRANSACTION", nil, nil, nil)
        }
    }
    
    func getMessages(forRoomId roomId: Int?, mainRoomId: Int? = nil) -> [ChatMessage] {
        return dbQueue.sync {
            let queryStatementString: String
            let mainId = mainRoomId
            
            if let rId = roomId {
                if rId == mainId {
                    queryStatementString = "SELECT id, couple_id, sender_id, message, room_id, created_at, updated_at FROM chat_messages WHERE room_id = ? OR room_id IS NULL ORDER BY id ASC;"
                } else {
                    queryStatementString = "SELECT id, couple_id, sender_id, message, room_id, created_at, updated_at FROM chat_messages WHERE room_id = ? ORDER BY id ASC;"
                }
            } else {
                if let _ = mainId {
                    queryStatementString = "SELECT id, couple_id, sender_id, message, room_id, created_at, updated_at FROM chat_messages WHERE room_id = ? OR room_id IS NULL ORDER BY id ASC;"
                } else {
                    queryStatementString = "SELECT id, couple_id, sender_id, message, room_id, created_at, updated_at FROM chat_messages WHERE room_id IS NULL ORDER BY id ASC;"
                }
            }
            
            var queryStatement: OpaquePointer?
            var messages: [ChatMessage] = []
            
            if sqlite3_prepare_v2(self.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if let rId = roomId {
                    sqlite3_bind_int(queryStatement, 1, Int32(rId))
                } else if let mId = mainId {
                    sqlite3_bind_int(queryStatement, 1, Int32(mId))
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
    }
    
    func clearAllMessages() {
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            let deleteString = "DELETE FROM chat_messages;"
            var deleteStatement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, deleteString, -1, &deleteStatement, nil) == SQLITE_OK {
                if sqlite3_step(deleteStatement) == SQLITE_DONE {
                    print("✅ SQLite: All messages cleared.")
                }
            }
            sqlite3_finalize(deleteStatement)
        }
    }
    
    func clearAllFlashes() {
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            let deleteString = "DELETE FROM flashes;"
            var deleteStatement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, deleteString, -1, &deleteStatement, nil) == SQLITE_OK {
                if sqlite3_step(deleteStatement) == SQLITE_DONE {
                    print("✅ SQLite: All flashes cleared.")
                }
            }
            sqlite3_finalize(deleteStatement)
        }
    }
    
    func deleteFlash(id: Int) {
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            let deleteString = "DELETE FROM flashes WHERE id = ?;"
            var deleteStatement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, deleteString, -1, &deleteStatement, nil) == SQLITE_OK {
                sqlite3_bind_int(deleteStatement, 1, Int32(id))
                if sqlite3_step(deleteStatement) == SQLITE_DONE {
                    print("✅ SQLite: Flash \(id) deleted from DB.")
                } else {
                    print("❌ SQLite: Could not delete flash \(id) from DB.")
                }
            }
            sqlite3_finalize(deleteStatement)
        }
    }
    
    func saveFlashes(_ flashes: [GlimpseFlash]) {
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            
            sqlite3_exec(self.db, "BEGIN TRANSACTION", nil, nil, nil)
            
            let insertStatementString = """
            INSERT OR REPLACE INTO flashes (id, sender_id, sender_name, photo_url, latitude, longitude, location_name, status_note, battery_level, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            
            var insertStatement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
                for flash in flashes {
                    sqlite3_bind_int(insertStatement, 1, Int32(flash.id))
                    sqlite3_bind_int(insertStatement, 2, Int32(flash.sender_id))
                    sqlite3_bind_text(insertStatement, 3, (flash.sender_name as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(insertStatement, 4, (flash.photo_url as NSString).utf8String, -1, nil)
                    
                    if let lat = flash.latitude {
                        sqlite3_bind_double(insertStatement, 5, lat)
                    } else {
                        sqlite3_bind_null(insertStatement, 5)
                    }
                    
                    if let lon = flash.longitude {
                        sqlite3_bind_double(insertStatement, 6, lon)
                    } else {
                        sqlite3_bind_null(insertStatement, 6)
                    }
                    
                    if let locName = flash.location_name {
                        sqlite3_bind_text(insertStatement, 7, (locName as NSString).utf8String, -1, nil)
                    } else {
                        sqlite3_bind_null(insertStatement, 7)
                    }
                    
                    if let statusNote = flash.status_note {
                        sqlite3_bind_text(insertStatement, 8, (statusNote as NSString).utf8String, -1, nil)
                    } else {
                        sqlite3_bind_null(insertStatement, 8)
                    }
                    
                    if let batt = flash.battery_level {
                        sqlite3_bind_int(insertStatement, 9, Int32(batt))
                    } else {
                        sqlite3_bind_null(insertStatement, 9)
                    }
                    
                    sqlite3_bind_text(insertStatement, 10, (flash.created_at as NSString).utf8String, -1, nil)
                    
                    if sqlite3_step(insertStatement) != SQLITE_DONE {
                        print("❌ SQLite: Error saving flash \(flash.id)")
                    }
                    
                    sqlite3_reset(insertStatement)
                }
            }
            sqlite3_finalize(insertStatement)
            sqlite3_exec(self.db, "COMMIT", nil, nil, nil)
        }
    }
    
    func getFlashes() -> [GlimpseFlash] {
        var loadedFlashes: [GlimpseFlash] = []
        let queryStatementString = "SELECT id, sender_id, sender_name, photo_url, latitude, longitude, location_name, status_note, battery_level, created_at FROM flashes ORDER BY id DESC;"
        
        var queryStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let senderId = Int(sqlite3_column_int(queryStatement, 1))
                
                let senderName = String(cString: sqlite3_column_text(queryStatement, 2))
                let photoUrl = String(cString: sqlite3_column_text(queryStatement, 3))
                
                let lat = sqlite3_column_double(queryStatement, 4)
                let lon = sqlite3_column_double(queryStatement, 5)
                
                var locName: String? = nil
                if sqlite3_column_type(queryStatement, 6) != SQLITE_NULL {
                    locName = String(cString: sqlite3_column_text(queryStatement, 6))
                }
                
                var note: String? = nil
                if sqlite3_column_type(queryStatement, 7) != SQLITE_NULL {
                    note = String(cString: sqlite3_column_text(queryStatement, 7))
                }
                
                var battery: Int? = nil
                if sqlite3_column_type(queryStatement, 8) != SQLITE_NULL {
                    battery = Int(sqlite3_column_int(queryStatement, 8))
                }
                
                let createdAt = String(cString: sqlite3_column_text(queryStatement, 9))
                
                let flash = GlimpseFlash(
                    id: id,
                    sender_id: senderId,
                    sender_name: senderName,
                    photo_url: photoUrl,
                    latitude: lat == 0.0 ? nil : lat,
                    longitude: lon == 0.0 ? nil : lon,
                    location_name: locName,
                    status_note: note,
                    battery_level: battery,
                    created_at: createdAt
                )
                loadedFlashes.append(flash)
            }
        }
        sqlite3_finalize(queryStatement)
        return loadedFlashes
    }
    
    func getLatestMessage(forRoomId roomId: Int?, mainRoomId: Int? = nil) -> ChatMessage? {
        return dbQueue.sync {
            let queryStatementString: String
            let mainId = mainRoomId
            
            if let rId = roomId {
                if rId == mainId {
                    queryStatementString = "SELECT id, couple_id, sender_id, message, room_id, created_at, updated_at FROM chat_messages WHERE room_id = ? OR room_id IS NULL ORDER BY id DESC LIMIT 1;"
                } else {
                    queryStatementString = "SELECT id, couple_id, sender_id, message, room_id, created_at, updated_at FROM chat_messages WHERE room_id = ? ORDER BY id DESC LIMIT 1;"
                }
            } else {
                if let _ = mainId {
                    queryStatementString = "SELECT id, couple_id, sender_id, message, room_id, created_at, updated_at FROM chat_messages WHERE room_id = ? OR room_id IS NULL ORDER BY id DESC LIMIT 1;"
                } else {
                    queryStatementString = "SELECT id, couple_id, sender_id, message, room_id, created_at, updated_at FROM chat_messages WHERE room_id IS NULL ORDER BY id DESC LIMIT 1;"
                }
            }
            
            var queryStatement: OpaquePointer?
            var latestMessage: ChatMessage? = nil
            
            if sqlite3_prepare_v2(self.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if let rId = roomId {
                    sqlite3_bind_int(queryStatement, 1, Int32(rId))
                } else if let mId = mainId {
                    sqlite3_bind_int(queryStatement, 1, Int32(mId))
                }
                
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    let id = Int(sqlite3_column_int(queryStatement, 0))
                    let coupleId = Int(sqlite3_column_int(queryStatement, 1))
                    let senderId = Int(sqlite3_column_int(queryStatement, 2))
                    
                    if let messageTextBytes = sqlite3_column_text(queryStatement, 3) {
                        let message = String(cString: messageTextBytes)
                        
                        var roomIdVal: Int? = nil
                        if sqlite3_column_type(queryStatement, 4) != SQLITE_NULL {
                            roomIdVal = Int(sqlite3_column_int(queryStatement, 4))
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
                        
                        latestMessage = ChatMessage(
                            id: id,
                            couple_id: coupleId,
                            sender_id: senderId,
                            message: message,
                            room_id: roomIdVal,
                            created_at: createdAt,
                            updated_at: updatedAt
                        )
                    }
                }
            }
            sqlite3_finalize(queryStatement)
            return latestMessage
        }
    }
}



extension AuthManager {
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
        let mainId = self.chatRooms.first(where: { $0.is_main })?.id
        self.latestFetchedMessages = GlimpseDatabase.shared.getMessages(forRoomId: nil, mainRoomId: mainId)
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
        GlimpseDatabase.shared.saveFlashes(self.flashes)
    }
    
    func loadCachedFlashes() {
        self.flashes = GlimpseDatabase.shared.getFlashes()
    }
    
    func getCachedMessages(for roomId: Int?) -> [ChatMessage] {
        let mainId = chatRooms.first(where: { $0.is_main })?.id
        let targetId = (roomId == nil) ? mainId : roomId
        
        if let rId = targetId {
            if let inMemory = roomMessagesCache[rId], !inMemory.isEmpty {
                return inMemory
            }
            let fromDb = GlimpseDatabase.shared.getMessages(forRoomId: rId, mainRoomId: mainId)
            roomMessagesCache[rId] = fromDb
            if rId == mainId {
                latestFetchedMessages = fromDb
            }
            return fromDb
        } else {
            if !latestFetchedMessages.isEmpty {
                return latestFetchedMessages
            }
            let fromDb = GlimpseDatabase.shared.getMessages(forRoomId: nil, mainRoomId: mainId)
            latestFetchedMessages = fromDb
            return fromDb
        }
    }
    
    // MARK: - SESSION CACHING
    func saveSessionCache(_ data: Data) {
        UserDefaults.standard.set(data, forKey: "cached_couple_response")
    }
    
    func loadCachedSession() {
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
    
    func getLatestMessagePreview(for room: GlimpseChatRoom) -> RoomLatestMessage? {
        let mainId = chatRooms.first(where: { $0.is_main })?.id
        if let localLatest = GlimpseDatabase.shared.getLatestMessage(forRoomId: room.is_main ? nil : room.id, mainRoomId: mainId) {
            return RoomLatestMessage(
                id: localLatest.id,
                message: localLatest.message,
                sender_id: localLatest.sender_id,
                created_at: localLatest.created_at
            )
        }
        return room.latest_message
    }
    

}
#endif
