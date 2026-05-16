import Foundation
import SwiftUI

@Observable
class AuthManager {
    static let shared = AuthManager()
    
    var isAuthenticated = false
    var userToken: String? {
        UserDefaults.standard.string(forKey: "auth_token")
    }
    
    private let baseURL = "http://192.168.100.108:8000/api"
    
    init() {
        self.isAuthenticated = userToken != nil
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
}
