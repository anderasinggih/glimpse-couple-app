import Foundation
import SwiftUI

@Observable
class AuthManager {
    static let shared = AuthManager()
    
    var isAuthenticated = false
    var currentUser: GlimpseUser?
    var partner: GlimpseUser?
    var anniversaryDate: Date?
    
    var userToken: String? {
        UserDefaults.standard.string(forKey: "auth_token")
    }
    
    private let baseURL = "http://192.168.100.108:8000/api"
    
    init() {
        self.isAuthenticated = userToken != nil
        if isAuthenticated {
            Task { try? await fetchState() }
        }
    }
    
    func fetchState() async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/state") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return
        }
        
        let decoder = JSONDecoder()
        if let stateResponse = try? decoder.decode(CoupleResponse.self, from: data) {
            DispatchQueue.main.async {
                self.currentUser = stateResponse.user
                self.partner = stateResponse.partner_data
                self.anniversaryDate = stateResponse.anniversaryDate
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
        
        if let photo = photo, let imageData = photo.jpegData(compressionQuality: 0.7) {
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
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
        withAnimation {
            self.isAuthenticated = false
        }
    }
    
    func uploadPhoto(_ image: UIImage) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/photo") else { return }
        guard let token = userToken else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else { return }
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"flash.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
    }
}
