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
    
    func getMessages(forRoomId roomId: Int?) -> [ChatMessage] {
        return dbQueue.sync {
            let queryStatementString: String
            if let rId = roomId {
                queryStatementString = "SELECT id, couple_id, sender_id, message, room_id, created_at, updated_at FROM chat_messages WHERE room_id = ? ORDER BY id ASC;"
            } else {
                queryStatementString = "SELECT id, couple_id, sender_id, message, room_id, created_at, updated_at FROM chat_messages WHERE room_id IS NULL ORDER BY id ASC;"
            }
            
            var queryStatement: OpaquePointer?
            var messages: [ChatMessage] = []
            
            if sqlite3_prepare_v2(self.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
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
    

}
#endif
