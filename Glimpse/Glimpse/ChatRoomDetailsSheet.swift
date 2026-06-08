import SwiftUI

// MARK: - Chat Room Details Sheet
// Shown when the user taps the chat header. Includes partner info, text size setting,
// shared theme/background color, and starred messages list.

struct ChatRoomDetailsSheet: View {
    let room: GlimpseChatRoom
    let partner: GlimpseUser
    @Binding var chatTextSize: CGFloat
    let starredMessageIds: Set<Int>
    let messages: [ChatMessage]
    let currentUserId: Int
    let apiBaseURL: String
    let myLatitude: Double?
    let myLongitude: Double?
    let onThemeUpdate: (String?, String?) -> Void
    let onScrollToStarred: (Int) -> Void
    let onRenameRoom: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("glimpse_background_theme", store: UserDefaults(suiteName: "group.glimpse.app")) var backgroundTheme = "default"

    // Preset palette options for theme accent
    private let themePresets: [(label: String, hex: String)] = [
        ("Cyan",    "00FFFF"),
        ("Purple",  "BF80FF"),
        ("Pink",    "FF4D9E"),
        ("Green",   "00FF88"),
        ("Orange",  "FF8C42"),
        ("Gold",    "FFD700"),
        ("Red",     "FF4D6D"),
        ("Blue",    "4D9EFF"),
        ("White",   "FFFFFF"),
    ]

    // Preset palette options for background tint
    private let bgPresets: [(label: String, hex: String)] = [
        ("Velvet",  "0D001A"),
        ("Midnight","0A0A1A"),
        ("Deep Sea","001A2C"),
        ("Forest",  "001A0D"),
        ("Charcoal","1A1A1A"),
        ("Warm",    "1A100D"),
        ("Rose",    "1A000D"),
        ("Default", ""),
    ]

    @State private var selectedThemeHex: String?
    @State private var selectedBgHex: String?
    @State private var isEditingRoomName = false
    @State private var editedRoomName: String = ""
    @State private var isShowingRenameAlert = false

    var starredMessages: [ChatMessage] {
        messages.filter { starredMessageIds.contains($0.id) }
    }

    // Distance between me and partner in km
    private var distanceKm: Double? {
        guard let myLat = myLatitude, let myLon = myLongitude,
              let pLat = partner.latitude, let pLon = partner.longitude,
              myLat != 0 && myLon != 0 && pLat != 0 && pLon != 0 else { return nil }
        let earthR = 6371.0
        let dLat = (pLat - myLat) * .pi / 180
        let dLon = (pLon - myLon) * .pi / 180
        let a = sin(dLat/2)*sin(dLat/2) + cos(myLat * .pi/180)*cos(pLat * .pi/180)*sin(dLon/2)*sin(dLon/2)
        return earthR * 2 * atan2(sqrt(a), sqrt(1-a))
    }

    private var distanceLabel: String {
        guard let d = distanceKm else { return "" }
        if d < 1.0 { return "\(Int(d * 1000))m away" }
        return String(format: "%.1f km away", d)
    }

    var body: some View {
        NavigationView {
            ZStack {
                (backgroundTheme == "dark" ? Color.black : Color(hex: "0D001A")).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: Partner Profile Card
                        partnerCard

                        // MARK: Room Info
                        roomInfoCard

                        Divider().background(Color.white.opacity(0.08))

                        // MARK: Text Size Setting
                        textSizeSection

                        Divider().background(Color.white.opacity(0.08))

                        // MARK: Theme Color Picker
                        colorPickerSection(
                            title: "Theme Color",
                            icon: "paintbrush.fill",
                            presets: themePresets,
                            currentHex: selectedThemeHex ?? room.theme_color ?? "00FFFF"
                        ) { hex in
                            selectedThemeHex = hex
                        }

                        Divider().background(Color.white.opacity(0.08))

                        // MARK: Background Color Picker
                        colorPickerSection(
                            title: "Background Color",
                            icon: "square.fill",
                            presets: bgPresets,
                            currentHex: selectedBgHex ?? room.background_color ?? ""
                        ) { hex in
                            selectedBgHex = hex
                        }

                        // Save theme button
                        Button {
                            let theme = selectedThemeHex ?? room.theme_color
                            let bg = selectedBgHex ?? room.background_color
                            onThemeUpdate(theme, bg)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Theme")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: selectedThemeHex ?? room.theme_color ?? "00FFFF"),
                                             Color(hex: selectedThemeHex ?? room.theme_color ?? "00FFFF").opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal, 20)

                        // MARK: Starred Messages
                        if !starredMessages.isEmpty {
                            Divider().background(Color.white.opacity(0.08))
                            starredMessagesSection
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Chat Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color(hex: selectedThemeHex ?? room.theme_color ?? "00FFFF"))
                }
            }
        }
        .onAppear {
            selectedThemeHex = room.theme_color
            selectedBgHex = room.background_color
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Partner Card
    private var partnerCard: some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: formattedPartnerPhoto())) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(Color.white.opacity(0.1))
                    .overlay(Image(systemName: "person.fill").font(.system(size: 40)).foregroundColor(.white.opacity(0.3)))
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(
                    Color(hex: selectedThemeHex ?? room.theme_color ?? "00FFFF").opacity(0.6),
                    lineWidth: 3.0
                )
            )
            .shadow(color: Color(hex: selectedThemeHex ?? room.theme_color ?? "00FFFF").opacity(0.3), radius: 15)

            VStack(spacing: 6) {
                Text(partner.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    // Online Status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(partner.isOffline ? Color.gray : Color.green)
                            .frame(width: 8, height: 8)
                        Text(partner.isOffline ? partner.timeAgoString : "Online now")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Battery
                    if let battery = partner.battery_level {
                        HStack(spacing: 4) {
                            Image(systemName: partner.is_charging == true ? "battery.100.bolt" : "battery.100")
                                .foregroundColor(partner.is_charging == true ? .green : .white.opacity(0.6))
                            Text("\(battery)%")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                // Location & Distance
                if let locName = partner.location_name, !locName.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(Color(hex: selectedThemeHex ?? room.theme_color ?? "00FFFF"))
                        Text(locName)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        if !distanceLabel.isEmpty {
                            Text("•")
                                .foregroundColor(.white.opacity(0.4))
                            Text(distanceLabel)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Room Info Card
    private var roomInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(room.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !room.is_main {
                    Button {
                        editedRoomName = room.name
                        isShowingRenameAlert = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 20)
        }
        .alert("Rename Room", isPresented: $isShowingRenameAlert) {
            TextField("Room Name", text: $editedRoomName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !editedRoomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onRenameRoom(editedRoomName)
                }
            }
        } message: {
            Text("Enter a new name for this chat room.")
        }
    }

    // MARK: - Text Size Section
    private var textSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Chat Text Size", systemImage: "textformat.size")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))

            HStack(spacing: 12) {
                Text("A")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))

                Slider(value: $chatTextSize, in: 11...20, step: 0.5)
                    .tint(Color(hex: selectedThemeHex ?? room.theme_color ?? "00FFFF"))
                    .onChange(of: chatTextSize) { _, newVal in
                        UserDefaults.standard.set(newVal, forKey: "glimpse_chat_text_size")
                    }

                Text("A")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Preview bubble
            HStack {
                Text("Hello, this is a preview of the text size!")
                    .font(.system(size: chatTextSize))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: selectedThemeHex ?? room.theme_color ?? "00FFFF").opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Color Picker Section
    @ViewBuilder
    private func colorPickerSection(title: String, icon: String, presets: [(label: String, hex: String)], currentHex: String, onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(presets, id: \.hex) { preset in
                    let isSelected = currentHex == preset.hex
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSelect(preset.hex)
                    } label: {
                        ZStack {
                            if preset.hex.isEmpty {
                                // Default indicator
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "0D001A"), Color(hex: "1A0030")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                            } else {
                                Circle()
                                    .fill(Color(hex: preset.hex))
                            }

                            if isSelected {
                                Circle()
                                    .stroke(Color.white, lineWidth: 2.5)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(preset.hex.isEmpty ? .white : colorContrast(hex: preset.hex))
                            }
                        }
                        .frame(width: 44, height: 44)
                        .shadow(color: isSelected ? Color(hex: preset.hex.isEmpty ? "FFFFFF" : preset.hex).opacity(0.5) : .clear, radius: 8)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Starred Messages Section
    private var starredMessagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("\(starredMessages.count) Starred Messages", systemImage: "star.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 20)

            ForEach(starredMessages) { msg in
                let isMe = msg.sender_id == currentUserId
                Button {
                    onScrollToStarred(msg.id)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                            .padding(.top, 3)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(isMe ? "You" : partner.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: selectedThemeHex ?? room.theme_color ?? "00FFFF"))
                            Text(msg.cleanDisplayContent)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.25))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Helpers
    private func formattedPartnerPhoto() -> String {
        let urlString = partner.profile_photo_url
        let baseURL = apiBaseURL.replacingOccurrences(of: "/api", with: "")
        if urlString.hasPrefix("http") { return urlString }
        let clean = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
        return clean.contains("storage/") ? "\(baseURL)/\(clean)" : "\(baseURL)/storage/\(clean)"
    }

    private func colorContrast(hex: String) -> Color {
        // Simple luminance check
        let r = Double(UInt8(hex.prefix(2), radix: 16) ?? 0) / 255.0
        let g = Double(UInt8(hex.dropFirst(2).prefix(2), radix: 16) ?? 0) / 255.0
        let b = Double(UInt8(hex.dropFirst(4).prefix(2), radix: 16) ?? 0) / 255.0
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5 ? .black : .white
    }
}
