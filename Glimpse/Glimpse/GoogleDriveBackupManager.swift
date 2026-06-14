#if !WIDGET
import Foundation
import AuthenticationServices
import Combine
import SwiftUI

@Observable
class GoogleDriveBackupManager {
    static let shared = GoogleDriveBackupManager()
    
    // MARK: - Configurations
    // Replace this with your Google OAuth 2.0 Client ID from Google Cloud Console
    var googleClientId: String {
        get {
            UserDefaults.standard.string(forKey: "google_drive_client_id") ?? "302722862393-lmqomnd2h74u33obukankjqnta97grc1.apps.googleusercontent.com"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "google_drive_client_id")
        }
    }
    
    var redirectUri: String {
        let parts = googleClientId.components(separatedBy: ".")
        let first = parts.first ?? "903058983226-c24h327fopgh4l112233aabbcc"
        return "com.googleusercontent.apps.\(first):/oauth2redirect"
    }
    
    let authScope = "https://www.googleapis.com/auth/drive.file"
    
    // MARK: - State
    var isConnected = false
    var userEmail: String? = nil
    var isBackingUp = false
    var backupProgress: Double = 0.0
    var errorMessage: String? = nil
    var isRestoring = false
    var restoreArcTrim: Double = 0.0
    var restoreDone = false
    private var presentationContextRetainer: Any? = nil
    
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "google_drive_access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "google_drive_access_token") }
    }
    
    private var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "google_drive_refresh_token") }
        set { UserDefaults.standard.set(newValue, forKey: "google_drive_refresh_token") }
    }
    
    private var tokenExpiry: Date? {
        get {
            if let seconds = UserDefaults.standard.object(forKey: "google_drive_token_expiry") as? Double {
                return Date(timeIntervalSince1970: seconds)
            }
            return nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970, forKey: "google_drive_token_expiry")
        }
    }
    
    private init() {
        self.isConnected = (refreshToken != nil)
        if self.isConnected {
            Task {
                await refreshAccessTokenIfNeeded()
                await fetchUserEmail()
            }
        }
    }
    
    // MARK: - OAuth Authentication
    @MainActor
    func connect(presentationAnchor: ASPresentationAnchor? = nil, loginHint: String? = nil) async -> Bool {
        self.errorMessage = nil
        
        let state = UUID().uuidString
        let scopeString = "\(authScope) https://www.googleapis.com/auth/userinfo.email"
        guard let encodedScope = scopeString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            self.errorMessage = "Failed to encode scopes"
            return false
        }
        
        var authURLString = "https://accounts.google.com/o/oauth2/v2/auth?" +
            "client_id=\(googleClientId)&" +
            "redirect_uri=\(redirectUri)&" +
            "response_type=code&" +
            "scope=\(encodedScope)&" +
            "state=\(state)&" +
            "access_type=offline&" +
            "prompt=consent"
        
        if let hint = loginHint {
            if let encodedHint = hint.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                authURLString += "&login_hint=\(encodedHint)"
            }
        }
        
        guard let authURL = URL(string: authURLString) else {
            self.errorMessage = "Invalid auth URL"
            return false
        }
        
        let finalAnchor: ASPresentationAnchor
        if let anchor = presentationAnchor {
            finalAnchor = anchor
        } else {
            // Retrieve key active window
            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first {
                finalAnchor = window
            } else if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first {
                finalAnchor = window
            } else {
                finalAnchor = UIWindow()
            }
        }
        
        let clientParts = googleClientId.components(separatedBy: ".")
        let callbackScheme = "com.googleusercontent.apps.\(clientParts.first ?? "903058983226-c24h327fopgh4l112233aabbcc")"
        
        return await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { callbackURL, error in
                self.presentationContextRetainer = nil
                
                if let error = error {
                    print("OAuth error: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    continuation.resume(returning: false)
                    return
                }
                
                // Parse code from redirect
                guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                      let queryItems = components.queryItems,
                      let code = queryItems.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(returning: false)
                    return
                }
                
                Task {
                    let success = await self.exchangeCodeForTokens(code: code)
                    if success {
                        await self.fetchUserEmail()
                    }
                    continuation.resume(returning: success)
                }
            }
            
            let provider = PresentationAnchorProvider(anchor: finalAnchor)
            self.presentationContextRetainer = provider
            session.presentationContextProvider = provider
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }
    
    func disconnect() {
        // Remove token from server asynchronously
        Task {
            await deleteDriveTokenFromServer()
        }
        self.accessToken = nil
        self.refreshToken = nil
        self.tokenExpiry = nil
        self.userEmail = nil
        self.isConnected = false
        self.errorMessage = nil
    }
    
    /// Reconnect Drive using a refresh token retrieved from the Glimpse server.
    /// Called after login on a new device so the user doesn't need to re-authorize.
    func connectFromServerToken(_ token: String) async {
        await MainActor.run {
            self.refreshToken = token
            self.isConnected = true
        }
        // Immediately get a fresh access token so we're ready to use Drive
        await refreshAccessTokenNow()
        await fetchUserEmail()
        print("✅ GoogleDrive: Auto-connected from server token")
    }
    
    // MARK: - Delete Backup Folder
    func deleteBackupFolder() async -> Bool {
        guard isConnected else { return false }
        await refreshAccessTokenIfNeeded()
        guard let token = accessToken else { return false }
        
        let folderQuery = "mimeType = 'application/vnd.google-apps.folder' and name = 'Glimpse Memories' and trashed = false"
        let encodedQuery = folderQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let searchURL = URL(string: "https://www.googleapis.com/drive/v3/files?q=\(encodedQuery)") else { return false }
        
        var searchRequest = URLRequest(url: searchURL)
        searchRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var folderId: String? = nil
        do {
            let (data, response) = try await URLSession.shared.data(for: searchRequest)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let files = json["files"] as? [[String: Any]],
                   let firstFolder = files.first,
                   let fId = firstFolder["id"] as? String {
                    folderId = fId
                }
            }
        } catch {
            print("Google Drive search folder failed: \(error)")
        }
        
        guard let fId = folderId else { return true }
        
        guard let deleteURL = URL(string: "https://www.googleapis.com/drive/v3/files/\(fId)") else { return false }
        var deleteRequest = URLRequest(url: deleteURL)
        deleteRequest.httpMethod = "DELETE"
        deleteRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: deleteRequest)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 || httpResponse.statusCode == 200 {
                print("🗑️ Google Drive: Successfully deleted Glimpse Memories folder.")
                return true
            }
        } catch {
            print("Google Drive delete folder exception: \(error)")
        }
        return false
    }
    
    // MARK: - Google Drive Folder Creation
    func getOrCreateBackupFolder() async -> String? {
        await refreshAccessTokenIfNeeded()
        guard let token = accessToken else {
            print("Google Drive Backup Error: Access token is missing")
            LiveDebugLogger.shared.log("Drive Backup: Access token missing")
            return nil
        }
        
        // 1. Search for existing Glimpse Memories folder
        let folderQuery = "mimeType = 'application/vnd.google-apps.folder' and name = 'Glimpse Memories' and trashed = false"
        let encodedQuery = folderQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let searchURL = URL(string: "https://www.googleapis.com/drive/v3/files?q=\(encodedQuery)") else { return nil }
        
        var searchRequest = URLRequest(url: searchURL)
        searchRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: searchRequest)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let files = json["files"] as? [[String: Any]],
                       let firstFolder = files.first,
                       let folderId = firstFolder["id"] as? String {
                        return folderId
                    }
                } else {
                    let errStr = self.parseGoogleErrorMessage(from: data)
                    print("Google Drive folder search failed: Status \(httpResponse.statusCode), body: \(errStr)")
                    LiveDebugLogger.shared.log("Drive Search Fail (\(httpResponse.statusCode)): \(errStr)")
                }
            }
        } catch {
            print("Google Drive folder search exception: \(error)")
            LiveDebugLogger.shared.log("Drive Search Exception: \(error.localizedDescription)")
        }
        
        // 2. Create new Glimpse Memories folder if not found
        guard let createURL = URL(string: "https://www.googleapis.com/drive/v3/files") else { return nil }
        var createRequest = URLRequest(url: createURL)
        createRequest.httpMethod = "POST"
        createRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        createRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let metadata = [
            "name": "Glimpse Memories",
            "mimeType": "application/vnd.google-apps.folder"
        ]
        createRequest.httpBody = try? JSONSerialization.data(withJSONObject: metadata)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: createRequest)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            if statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let folderId = json["id"] as? String {
                    print("Google Drive: Created Glimpse Memories folder successfully.")
                    LiveDebugLogger.shared.log("Drive: Folder Created")
                    return folderId
                }
            } else {
                let errStr = self.parseGoogleErrorMessage(from: data)
                print("Google Drive folder creation failed: Status \(statusCode), body: \(errStr)")
                LiveDebugLogger.shared.log("Drive Create Fail: \(errStr)")
            }
        } catch {
            print("Google Drive folder creation exception: \(error)")
            LiveDebugLogger.shared.log("Drive Create Exception: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // MARK: - Delete File from Backup Folder
    func deleteFileFromBackupFolder(filename: String) async -> Bool {
        guard isConnected else { return false }
        await refreshAccessTokenIfNeeded()
        guard let token = accessToken else { return false }
        
        guard let parentId = await getOrCreateBackupFolder() else {
            print("Google Drive delete file: Glimpse Memories folder not found.")
            return false
        }
        
        let fileQuery = "'\(parentId)' in parents and name = '\(filename)' and trashed = false"
        let encodedFileQuery = fileQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let fileSearchURL = URL(string: "https://www.googleapis.com/drive/v3/files?q=\(encodedFileQuery)") else { return false }
        
        var fileSearchRequest = URLRequest(url: fileSearchURL)
        fileSearchRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var fileId: String? = nil
        do {
            let (data, response) = try await URLSession.shared.data(for: fileSearchRequest)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let files = json["files"] as? [[String: Any]],
                   let firstFile = files.first,
                   let fId = firstFile["id"] as? String {
                    fileId = fId
                }
            } else {
                let errText = String(data: data, encoding: .utf8) ?? ""
                print("Google Drive search file failed: \(errText)")
            }
        } catch {
            print("Google Drive search file failed: \(error)")
        }
        
        guard let fId = fileId else {
            print("Google Drive delete file: file \(filename) not found in folder.")
            return false
        }
        
        guard let deleteURL = URL(string: "https://www.googleapis.com/drive/v3/files/\(fId)") else { return false }
        var deleteRequest = URLRequest(url: deleteURL)
        deleteRequest.httpMethod = "DELETE"
        deleteRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: deleteRequest)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            if statusCode == 204 || statusCode == 200 {
                print("🗑️ Google Drive: Successfully deleted file: \(filename).")
                return true
            } else {
                let errText = String(data: data, encoding: .utf8) ?? ""
                print("Google Drive delete file failed: status \(statusCode), body: \(errText)")
            }
        } catch {
            print("Google Drive delete file exception: \(error)")
        }
        return false
    }
    
    // MARK: - Download File from Backup Folder
    func downloadFileFromBackupFolder(filename: String) async -> Data? {
        guard isConnected else { return nil }
        await refreshAccessTokenIfNeeded()
        guard let token = accessToken else { return nil }
        
        var folderId: String? = nil
        let folderQuery = "mimeType = 'application/vnd.google-apps.folder' and name = 'Glimpse Memories' and trashed = false"
        let encodedFolderQuery = folderQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let searchURL = URL(string: "https://www.googleapis.com/drive/v3/files?q=\(encodedFolderQuery)") {
            var searchRequest = URLRequest(url: searchURL)
            searchRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if let (data, response) = try? await URLSession.shared.data(for: searchRequest),
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let files = json["files"] as? [[String: Any]],
                   let firstFolder = files.first,
                   let fId = firstFolder["id"] as? String {
                    folderId = fId
                }
            }
        }
        
        guard let parentId = folderId else {
            print("Google Drive download file: Glimpse Memories folder not found.")
            return nil
        }
        
        let fileQuery = "'\(parentId)' in parents and name = '\(filename)' and trashed = false"
        let encodedFileQuery = fileQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let fileSearchURL = URL(string: "https://www.googleapis.com/drive/v3/files?q=\(encodedFileQuery)") else { return nil }
        
        var fileSearchRequest = URLRequest(url: fileSearchURL)
        fileSearchRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var fileId: String? = nil
        do {
            let (data, response) = try await URLSession.shared.data(for: fileSearchRequest)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let files = json["files"] as? [[String: Any]],
                   let firstFile = files.first,
                   let fId = firstFile["id"] as? String {
                    fileId = fId
                }
            }
        } catch {
            print("Google Drive search file failed: \(error)")
        }
        
        guard let fId = fileId else {
            print("Google Drive download file: file \(filename) not found in folder.")
            return nil
        }
        
        guard let downloadURL = URL(string: "https://www.googleapis.com/drive/v3/files/\(fId)?alt=media") else { return nil }
        var downloadRequest = URLRequest(url: downloadURL)
        downloadRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            print("⬇️ Downloading file \(filename) from Google Drive...")
            let (data, response) = try await URLSession.shared.data(for: downloadRequest)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return data
            }
        } catch {
            print("Google Drive download file exception: \(error)")
        }
        return nil
    }
    
    // MARK: - Exchange Code for Tokens
    private func exchangeCodeForTokens(code: String) async -> Bool {
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters = [
            "code": code,
            "client_id": googleClientId,
            "redirect_uri": redirectUri,
            "grant_type": "authorization_code"
        ]
        
        request.httpBody = bodyParameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let errResponse = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Token exchange error response: \(errResponse)")
                await MainActor.run { self.errorMessage = "Failed token exchange: \(errResponse)" }
                return false
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let access = json["access_token"] as? String,
               let refresh = json["refresh_token"] as? String,
               let expiresIn = json["expires_in"] as? Double {
                
                await MainActor.run {
                    self.accessToken = access
                    self.refreshToken = refresh
                    self.tokenExpiry = Date().addingTimeInterval(expiresIn)
                    self.isConnected = true
                }
                // Persist the refresh token to the Glimpse server so other devices can auto-reconnect
                await uploadDriveTokenToServer(refresh)
                return true
            }
        } catch {
            print("Token exchange exception: \(error)")
        }
        return false
    }
    
    // MARK: - Refresh Access Token (forced, ignores expiry check)
    private func refreshAccessTokenNow() async {
        guard let refresh = refreshToken else { return }
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters = [
            "refresh_token": refresh,
            "client_id": googleClientId,
            "grant_type": "refresh_token"
        ]
        
        request.httpBody = bodyParameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("⚠️ Drive force-refresh failed: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                // Token invalid – clear local state
                await MainActor.run {
                    self.refreshToken = nil
                    self.isConnected = false
                }
                return
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let access = json["access_token"] as? String,
               let expiresIn = json["expires_in"] as? Double {
                await MainActor.run {
                    self.accessToken = access
                    self.tokenExpiry = Date().addingTimeInterval(expiresIn)
                }
            }
        } catch {
            print("Drive force-refresh exception: \(error)")
        }
    }
    
    // MARK: - Refresh Access Token
    private func refreshAccessTokenIfNeeded() async {
        guard let expiry = tokenExpiry, expiry.timeIntervalSinceNow < 300 else { return } // Refresh if expiring in < 5 mins
        guard let refresh = refreshToken else { return }
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters = [
            "refresh_token": refresh,
            "client_id": googleClientId,
            "grant_type": "refresh_token"
        ]
        
        request.httpBody = bodyParameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Refresh token error code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let access = json["access_token"] as? String,
               let expiresIn = json["expires_in"] as? Double {
                
                await MainActor.run {
                    self.accessToken = access
                    self.tokenExpiry = Date().addingTimeInterval(expiresIn)
                }
            }
        } catch {
            print("Token refresh exception: \(error)")
        }
    }
    
    // MARK: - Server Token Sync
    private func uploadDriveTokenToServer(_ token: String) async {
        guard let authToken = UserDefaults.standard.string(forKey: "auth_token") else { return }
        let baseURL = AuthManager.shared.baseURL
        guard let url = URL(string: "\(baseURL)/user/drive-token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["refresh_token": token])
        
        if let (_, response) = try? await URLSession.shared.data(for: request),
           let httpResponse = response as? HTTPURLResponse {
            print("☁️ Drive token upload to server: \(httpResponse.statusCode)")
        }
    }
    
    private func deleteDriveTokenFromServer() async {
        guard let authToken = UserDefaults.standard.string(forKey: "auth_token") else { return }
        let baseURL = AuthManager.shared.baseURL
        guard let url = URL(string: "\(baseURL)/user/drive-token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        if let (_, response) = try? await URLSession.shared.data(for: request),
           let httpResponse = response as? HTTPURLResponse {
            print("🗑️ Drive token deleted from server: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Fetch Google User Profile
    private func fetchUserEmail() async {
        await refreshAccessTokenIfNeeded()
        guard let token = accessToken, let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo") else { return }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let (data, response) = try? await URLSession.shared.data(for: request),
           let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let email = json["email"] as? String {
                await MainActor.run {
                    self.userEmail = email
                }
            }
        }
    }
    
    private func parseGoogleErrorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let errorObj = json["error"] as? [String: Any],
               let msg = errorObj["message"] as? String {
                return msg
            }
        }
        return String(data: data, encoding: .utf8) ?? "Unknown Google API error"
    }
    

        

    // MARK: - Perform Google Drive Backup sync
    func runBackup(flashes: [GlimpseFlash]) async {
        guard isConnected else { return }
        
        await MainActor.run {
            self.isBackingUp = true
            self.backupProgress = 0.0
            self.errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                self.isBackingUp = false
            }
        }
        
        guard let folderId = await getOrCreateBackupFolder() else {
            await MainActor.run { self.errorMessage = "Failed to access/create backup folder" }
            return
        }
        
        // 1. Backup Pending Flashes Images
        var backedUpIds = UserDefaults.standard.array(forKey: "backed_up_flash_ids") as? [Int] ?? []
        let currentFlashIds = Set(flashes.map { $0.id })
        backedUpIds = backedUpIds.filter { currentFlashIds.contains($0) }
        UserDefaults.standard.set(backedUpIds, forKey: "backed_up_flash_ids")
        
        let pendingFlashes = flashes.filter { !backedUpIds.contains($0.id) }
        
        if !pendingFlashes.isEmpty {
            var completedCount = 0
            let totalCount = pendingFlashes.count
            
            for flash in pendingFlashes {
                let urlString = formattedUrl(flash.photo_url)
                guard let url = URL(string: urlString) else { continue }
                
                do {
                    let (imageData, _) = try await URLSession.shared.data(from: url)
                    let success = await uploadToDrive(imageData: imageData, filename: "Glimpse_Flash_\(flash.id).jpg", folderId: folderId, flash: flash)
                    if success {
                        backedUpIds.append(flash.id)
                        UserDefaults.standard.set(backedUpIds, forKey: "backed_up_flash_ids")
                    }
                } catch {
                    print("Failed to download image for flash \(flash.id): \(error)")
                }
                
                completedCount += 1
                let progress = Double(completedCount) / Double(totalCount) * 0.9 // Reserve 10% for DB backup progress
                await MainActor.run {
                    self.backupProgress = progress
                }
            }
        }
        
        // 2. Backup Local SQLite Database File (glimpse_chat.sqlite)
        // Wait briefly so dbQueue.async in saveFlashesCache() has finished writing to disk
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s flush window
        
        let fileManager = FileManager.default
        if let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dbURL = docsDir.appendingPathComponent("glimpse_chat.sqlite")
            if fileManager.fileExists(atPath: dbURL.path) {
                if let dbData = try? Data(contentsOf: dbURL) {
                    let dbSuccess = await uploadDatabaseFile(fileData: dbData, folderId: folderId)
                    print("Database backup result: \(dbSuccess)")
                }
            }
        }
        
        await MainActor.run {
            self.backupProgress = 1.0
        }
    }
    
    // MARK: - Search and Upload SQLite Database File
    private func findDatabaseFile(folderId: String) async -> String? {
        await refreshAccessTokenIfNeeded()
        guard let token = accessToken else { return nil }
        
        let query = "name = 'glimpse_chat.sqlite' and '\(folderId)' in parents and trashed = false"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://www.googleapis.com/drive/v3/files?q=\(encodedQuery)") else { return nil }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let (data, response) = try? await URLSession.shared.data(for: request),
           let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let files = json["files"] as? [[String: Any]],
               let firstFile = files.first,
               let fileId = firstFile["id"] as? String {
                return fileId
            }
        }
        return nil
    }
    
    private func uploadDatabaseFile(fileData: Data, folderId: String) async -> Bool {
        await refreshAccessTokenIfNeeded()
        guard let token = accessToken else { return false }
        
        let existingFileId = await findDatabaseFile(folderId: folderId)
        
        let boundary = "Boundary-\(UUID().uuidString)"
        let urlString: String
        let method: String
        if let fileId = existingFileId {
            urlString = "https://www.googleapis.com/upload/drive/v3/files/\(fileId)?uploadType=multipart"
            method = "PATCH"
        } else {
            urlString = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
            method = "POST"
        }
        
        guard let uploadURL = URL(string: urlString) else { return false }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = method
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Metadata Part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        
        var metadata: [String: Any] = [
            "name": "glimpse_chat.sqlite"
        ]
        if existingFileId == nil {
            metadata["parents"] = [folderId]
        }
        
        let metadataData = try! JSONSerialization.data(withJSONObject: metadata)
        body.append(metadataData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Media Part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/x-sqlite3\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
                return true
            } else {
                let errText = String(data: data, encoding: .utf8) ?? ""
                print("Database upload failed: \(errText)")
            }
        } catch {
            print("Database upload exception: \(error)")
        }
        return false
    }
    
    
    @MainActor
    func performRestoreFlow(auth: AuthManager) {
        guard !isRestoring else { return }
        isRestoring = true
        restoreDone = false
        
        // Start pulsing animation
        restoreArcTrim = 0.15
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            restoreArcTrim = 0.85
        }
        
        Task {
            let success = await restoreDatabase()
            if success {
                auth.loadCachedMessages()
                auth.loadCachedFlashes()
                let fetchedFlashes = (try? await auth.fetchFlashes()) ?? auth.flashes
                await restoreFlashImages(flashes: fetchedFlashes)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            
            await MainActor.run {
                restoreArcTrim = 0
                isRestoring = false
                withAnimation {
                    restoreDone = true
                }
                
                // Hide banner after 2.5s
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        self.restoreDone = false
                    }
                }
            }
        }
    }
    
    // MARK: - Restore SQLite Database from Google Drive
    func restoreDatabase() async -> Bool {
        guard isConnected else { return false }
        await refreshAccessTokenIfNeeded()
        guard let token = accessToken else { return false }
        
        guard let folderId = await getOrCreateBackupFolder() else { return false }
        guard let fileId = await findDatabaseFile(folderId: folderId) else { return false }
        
        guard let downloadURL = URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media") else { return false }
        
        var request = URLRequest(url: downloadURL)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Database download failed with code \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return false
            }
            
            // Write to a temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_glimpse.sqlite")
            try data.write(to: tempURL)
            
            // Close and replace database
            let success = GlimpseDatabase.shared.closeAndReplaceDatabase(withTempURL: tempURL)
            try? FileManager.default.removeItem(at: tempURL)
            return success
        } catch {
            print("Database restore exception: \(error)")
            return false
        }
    }
    
    private func uploadToDrive(imageData: Data, filename: String, folderId: String, flash: GlimpseFlash) async -> Bool {
        await refreshAccessTokenIfNeeded()
        guard let token = accessToken else { return false }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        guard let uploadURL = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart") else { return false }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Metadata Part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        
        let metadata: [String: Any] = [
            "name": filename,
            "parents": [folderId],
            "description": flash.status_note ?? "Glimpse Memory Flash"
        ]
        
        let metadataData = try! JSONSerialization.data(withJSONObject: metadata)
        body.append(metadataData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Media Part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
                return true
            } else {
                let errText = String(data: data, encoding: .utf8) ?? ""
                print("Upload failed: \(errText)")
            }
        } catch {
            print("Drive upload exception: \(error)")
        }
        return false
    }
    
    // MARK: - Restore Flash Images from Google Drive to local Cache
    func restoreFlashImages(flashes: [GlimpseFlash]) async {
        guard isConnected else {
            print("❌ restoreFlashImages: Not connected to Google Drive")
            return
        }
        await refreshAccessTokenIfNeeded()
        guard let token = accessToken else {
            print("❌ restoreFlashImages: Access token missing")
            return
        }
        
        guard let folderId = await getOrCreateBackupFolder() else {
            print("❌ restoreFlashImages: Failed to get or create Glimpse Memories folder")
            return
        }
        
        // 1. List all files in the folder (simplifying query to be foolproof)
        let query = "'\(folderId)' in parents and trashed = false"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let listURL = URL(string: "https://www.googleapis.com/drive/v3/files?q=\(encodedQuery)&pageSize=1000&fields=files(id,name,createdTime,description)") else { return }
        
        var request = URLRequest(url: listURL)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var driveFiles: [[String: Any]] = []
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let files = json["files"] as? [[String: Any]] {
                        driveFiles = files
                        print("🔍 restoreFlashImages: Listed \(files.count) total files in Google Drive backup folder.")
                        LiveDebugLogger.shared.log("Drive: Found \(files.count) files in backup folder")
                    }
                } else {
                    let errStr = String(data: data, encoding: .utf8) ?? "unknown"
                    print("❌ restoreFlashImages: Google Drive file listing failed: Status \(httpResponse.statusCode), body: \(errStr)")
                    LiveDebugLogger.shared.log("Drive List Fail: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ restoreFlashImages: Exception listing files: \(error)")
            LiveDebugLogger.shared.log("Drive List Exception: \(error.localizedDescription)")
            return
        }
        
        // 2. Iterate through each file in Google Drive, download it, and cache it
        let fileManager = FileManager.default
        var dlSuccessCount = 0
        var skipCount = 0
        
        for file in driveFiles {
            guard let fileId = file["id"] as? String,
                  let name = file["name"] as? String else { continue }
            
            // Filter files that represent our flashes
            guard name.hasPrefix("Glimpse_Flash_") && name.hasSuffix(".jpg") else {
                print("   - Skipping non-flash file: \(name)")
                continue
            }
            
            // Extract flash ID from filename (e.g. Glimpse_Flash_123.jpg)
            let cleanFilename = name.replacingOccurrences(of: "Glimpse_Flash_", with: "").replacingOccurrences(of: ".jpg", with: "")
            guard let flashId = Int(cleanFilename) else { continue }
            
            // Find corresponding GlimpseFlash
            var flash: GlimpseFlash
            if let matched = flashes.first(where: { $0.id == flashId }) {
                flash = matched
            } else {
                print("   - No matching GlimpseFlash found in feed for ID \(flashId). Reconstructing from Drive metadata...")
                let createdTime = file["createdTime"] as? String ?? ""
                let description = file["description"] as? String
                
                let restoredFlash = GlimpseFlash(
                    id: flashId,
                    sender_id: 0,
                    sender_name: "Glimpse Memory",
                    photo_url: "glimpse_photos/Glimpse_Flash_\(flashId).jpg",
                    latitude: nil,
                    longitude: nil,
                    location_name: nil,
                    status_note: description,
                    battery_level: nil,
                    created_at: createdTime.isEmpty ? ISO8601DateFormatter().string(from: Date()) : createdTime
                )
                
                let finalFlash = restoredFlash
                await MainActor.run {
                    if !AuthManager.shared.flashes.contains(where: { $0.id == finalFlash.id }) {
                        AuthManager.shared.flashes.append(finalFlash)
                        AuthManager.shared.saveFlashesCache()
                    }
                }
                flash = restoredFlash
            }
            
            // Build cache filename
            let finalUrlStr = formattedUrl(flash.photo_url)
            let cleanName = finalUrlStr.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
            let cacheFilename = "img_cache_\(cleanName).jpg"
            
            var primaryURL: URL? = nil
            if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
                primaryURL = groupURL.appendingPathComponent(cacheFilename)
            }
            
            var fallbackURL: URL? = nil
            if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                fallbackURL = cachesURL.appendingPathComponent(cacheFilename)
            }
            
            // Check if already cached
            let alreadyCached = (primaryURL != nil && fileManager.fileExists(atPath: primaryURL!.path)) ||
                                (fallbackURL != nil && fileManager.fileExists(atPath: fallbackURL!.path))
            
            if alreadyCached {
                print("   - Flash \(flashId) image already exists in local cache, skipping.")
                skipCount += 1
                continue
            }
            
            // Download image from Drive to ensure it is restored locally, as the server copy is ephemeral and deleted after ACK.
            
            // Download image from Drive
            guard let downloadURL = URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media") else { continue }
            var downloadRequest = URLRequest(url: downloadURL)
            downloadRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                print("⬇️ Restoring flash image \(flashId) from Google Drive...")
                LiveDebugLogger.shared.log("DL from Drive: Flash \(flashId)")
                let (imgData, dlResponse) = try await URLSession.shared.data(for: downloadRequest)
                guard let httpDLResponse = dlResponse as? HTTPURLResponse else { continue }
                
                if httpDLResponse.statusCode == 200 {
                    if let primaryURL = primaryURL {
                        try imgData.write(to: primaryURL)
                        print("💾 Restored and cached image to primary App Group path: \(cacheFilename)")
                    }
                    if let fallbackURL = fallbackURL {
                        try? imgData.write(to: fallbackURL)
                    }
                    dlSuccessCount += 1
                } else {
                    let errStr = String(data: imgData, encoding: .utf8) ?? "unknown"
                    print("❌ Failed to download flash image \(flashId): Status \(httpDLResponse.statusCode), body: \(errStr)")
                }
            } catch {
                print("❌ Failed to download and cache restored flash \(flashId): \(error)")
                LiveDebugLogger.shared.log("DL Error \(flashId): \(error.localizedDescription)")
            }
        }
        
        print("💾 restoreFlashImages finished. Downloaded: \(dlSuccessCount), Skipped (already cached): \(skipCount)")
        LiveDebugLogger.shared.log("Restore finished: \(dlSuccessCount) DL, \(skipCount) skip")
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

// MARK: - PresentationAnchorProvider
private class PresentationAnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    let anchor: ASPresentationAnchor
    
    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return anchor
    }
}
#endif
