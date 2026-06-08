import SwiftUI

struct ShareView: View {
    let sharedText: String?
    let sharedURL: URL?
    let onDismiss: () -> Void
    
    @State private var commentText: String = ""
    @State private var chatRooms: [SharedChatRoom] = []
    @State private var selectedRoomId: Int? = nil
    @State private var isLoadingRooms = true
    @State private var isSending = false
    @State private var errorMessage: String? = nil
    @State private var isSuccess = false
    @State private var currentUserId: Int = 0
    
    // Shared defaults suitename
    private let suiteName = "group.glimpse.app"
    private let baseURL = "https://api.galleryfortwo.my.id/api"
    
    private var activeAccentColor: Color {
        let hex = UserDefaults(suiteName: suiteName)?.string(forKey: "glimpse_theme_accent") ?? "00FFFF"
        return Color(hex: hex)
    }
    
    private var isPureBlack: Bool {
        let theme = UserDefaults(suiteName: suiteName)?.string(forKey: "glimpse_background_theme") ?? "default"
        return theme == "dark"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                // Drag / top handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 6)
                    .padding(.top, 12)
                
                // Header
                HStack {
                    Text("Share to Glimpse")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 20)
                
                if isSuccess {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundColor(activeAccentColor)
                            .scaleEffect(isSuccess ? 1.0 : 0.5)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSuccess)
                        
                        Text("Shared successfully!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(height: 250)
                    .padding(.bottom, 20)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        // Shared content preview
                        if let url = sharedURL {
                            HStack(spacing: 12) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(activeAccentColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sharedText ?? "Shared Link")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Text(url.absoluteString)
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.5))
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        } else if let text = sharedText {
                            Text(text)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(3)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        }
                        
                        // Comment text field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Add a comment (optional)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                            
                            TextField("Type a message to send along...", text: $commentText)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                        }
                        
                        // Rooms list header
                        Text("Select Chat Room")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        if isLoadingRooms {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .tint(.white)
                                Spacer()
                            }
                            .frame(height: 70)
                        } else if chatRooms.isEmpty {
                            Text("No active chat rooms found. Make sure you are logged in and paired.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(chatRooms) { room in
                                        Button {
                                            selectedRoomId = room.id
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        } label: {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedRoomId == room.id ? activeAccentColor : Color.white.opacity(0.08))
                                                        .frame(width: 50, height: 50)
                                                    
                                                    Image(systemName: room.is_main ? "heart.fill" : "bubble.left.and.bubble.right.fill")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(selectedRoomId == room.id ? Color(hex: "050215") : (room.is_main ? .red : activeAccentColor))
                                                }
                                                
                                                Text(room.name)
                                                    .font(.system(size: 11, weight: selectedRoomId == room.id ? .bold : .regular))
                                                    .foregroundColor(selectedRoomId == room.id ? activeAccentColor : .white.opacity(0.8))
                                                    .lineLimit(1)
                                                    .frame(width: 70)
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            .frame(height: 85)
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                        }
                        
                        // Send Button
                        Button {
                            sendMessage()
                        } label: {
                            HStack {
                                if isSending {
                                    ProgressView().tint(Color(hex: "050215"))
                                } else {
                                    Text("Send to Room")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedRoomId != nil && !isSending ? activeAccentColor : Color.white.opacity(0.1))
                            .foregroundColor(selectedRoomId != nil && !isSending ? Color(hex: "050215") : .white.opacity(0.3))
                            .cornerRadius(14)
                        }
                        .disabled(selectedRoomId == nil || isSending)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .background(
                ZStack {
                    (isPureBlack ? Color.black : Color(hex: "0D001A"))
                    
                    if !isPureBlack {
                        // Orb 1 (Adapts to Active Theme Accent!)
                        Circle()
                            .fill(activeAccentColor.opacity(0.12))
                            .frame(width: 350, height: 350)
                            .blur(radius: 70)
                            .offset(x: -80, y: 100)
                        
                        // Orb 2 (Complementary royal purple)
                        Circle()
                            .fill(Color(hex: "7A28FF").opacity(0.08))
                            .frame(width: 250, height: 250)
                            .blur(radius: 50)
                            .offset(x: 120, y: 150)
                    }
                }
            )
            .cornerRadius(24, corners: [.topLeft, .topRight])
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            loadInitialData()
        }
    }
    
    private func loadInitialData() {
        guard let token = UserDefaults(suiteName: suiteName)?.string(forKey: "auth_token") else {
            errorMessage = "Please log in to the Glimpse app first."
            isLoadingRooms = false
            return
        }
        
        Task {
            do {
                // 1. Fetch current user state to retrieve sender ID
                try await fetchState(token: token)
                
                // 2. Fetch rooms
                try await fetchRooms(token: token)
            } catch {
                errorMessage = "Failed to load data. Please open Glimpse and try again."
            }
            isLoadingRooms = false
        }
    }
    
    private func fetchState(token: String) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/state") else { return }
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let userDict = json["user"] as? [String: Any],
           let id = userDict["id"] as? Int {
            self.currentUserId = id
        }
    }
    
    private func fetchRooms(token: String) async throws {
        guard let url = URL(string: "\(baseURL)/glimpse/chat-rooms") else { return }
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Share", code: 400, userInfo: nil)
        }
        
        let rooms = try JSONDecoder().decode([SharedChatRoom].self, from: data)
        await MainActor.run {
            self.chatRooms = rooms
            if let mainRoom = rooms.first(where: { $0.is_main }) {
                self.selectedRoomId = mainRoom.id
            } else {
                self.selectedRoomId = rooms.first?.id
            }
        }
    }
    
    private func sendMessage() {
        guard let roomId = selectedRoomId else { return }
        guard let token = UserDefaults(suiteName: suiteName)?.string(forKey: "auth_token") else { return }
        
        isSending = true
        errorMessage = nil
        
        // Construct the full message text: comment + shared link/text
        var textToSend = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = sharedURL {
            if textToSend.isEmpty {
                textToSend = url.absoluteString
            } else {
                textToSend = "\(textToSend)\n\(url.absoluteString)"
            }
        } else if let text = sharedText, textToSend.isEmpty {
            textToSend = text
        }
        
        Task {
            do {
                guard let url = URL(string: "\(baseURL)/glimpse/chat") else { return }
                
                // Create temporary Protobuf message representation
                let messageData = encodeProtobufMessage(messageText: textToSend, roomId: roomId, senderId: currentUserId)
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.addValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
                request.addValue("application/x-protobuf", forHTTPHeaderField: "Accept")
                request.httpBody = messageData
                
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NSError(domain: "Share", code: 400, userInfo: nil)
                }
                
                await MainActor.run {
                    isSuccess = true
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    // Auto close after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onDismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to send message. Please try again."
                    isSending = false
                }
            }
        }
    }
    
    private func encodeProtobufMessage(messageText: String, roomId: Int, senderId: Int) -> Data {
        var writer = ProtobufWriter()
        writer.writeInt32Field(fieldNumber: 1, value: 0) // ID = 0 for new messages
        writer.writeInt32Field(fieldNumber: 2, value: roomId)
        writer.writeInt32Field(fieldNumber: 3, value: senderId)
        writer.writeStringField(fieldNumber: 4, value: messageText)
        return writer.data
    }
}

// MARK: - Light Protobuf Writer to avoid binary dependencies
struct ProtobufWriter {
    private(set) var data = Data()
    
    mutating func writeVarint(_ val: UInt64) {
        var value = val
        while value >= 0x80 {
            data.append(UInt8((value & 0x7F) | 0x80))
            value >>= 7
        }
        data.append(UInt8(value & 0x7F))
    }
    
    mutating func writeTag(fieldNumber: Int, wireType: Int) {
        writeVarint(UInt64((fieldNumber << 3) | wireType))
    }
    
    mutating func writeInt32Field(fieldNumber: Int, value: Int) {
        writeTag(fieldNumber: fieldNumber, wireType: 0)
        writeVarint(UInt64(value))
    }
    
    mutating func writeStringField(fieldNumber: Int, value: String) {
        guard let stringData = value.data(using: .utf8) else { return }
        writeTag(fieldNumber: fieldNumber, wireType: 2)
        writeVarint(UInt64(stringData.count))
        data.append(stringData)
    }
}

// MARK: - Models
struct SharedChatRoom: Codable, Identifiable {
    let id: Int
    let name: String
    let is_main: Bool
}

// MARK: - Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 1)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
