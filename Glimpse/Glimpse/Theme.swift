import SwiftUI

extension Color {
    // Dark Mode Palette
    static let deepVelvet = Color(hex: "0D001A")
    static let electricPurple = Color(hex: "BF80FF")
    
    static var activeCyan: Color {
        let suite = UserDefaults(suiteName: "group.glimpse.app")
        let hex = suite?.string(forKey: "glimpse_theme_accent") ?? "00FFFF"
        return Color(hex: hex)
    }
    
    // Light Mode Palette
    static let lavenderMist = Color(hex: "F9F5FF")
    static let royalPurple = Color(hex: "7A28FF")
    static let vividMint = Color(hex: "00FF88")
    
    // Adaptive Colors
    static var adaptiveBackground: Color {
        let suite = UserDefaults(suiteName: "group.glimpse.app")
        let theme = suite?.string(forKey: "glimpse_background_theme") ?? "default"
        return theme == "dark" ? Color.black : Color.deepVelvet
    }
    static var adaptiveAccent: Color { Color.activeCyan }
}

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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct GlassmorphicModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
    }
}

struct iOS26Background: View {
    @AppStorage("glimpse_dynamic_orbs", store: UserDefaults(suiteName: "group.glimpse.app")) var dynamicOrbsEnabled = true
    @AppStorage("glimpse_background_theme", store: UserDefaults(suiteName: "group.glimpse.app")) var backgroundTheme = "default"
    @State private var animateOrbs = false
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            if backgroundTheme != "dark" {
                // Orb 1 (Adapts to Active Theme Accent!)
                Circle()
                    .fill(Color.activeCyan.opacity(0.12))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(
                        x: dynamicOrbsEnabled ? (animateOrbs ? -40 : -120) : -80,
                        y: dynamicOrbsEnabled ? (animateOrbs ? -160 : -260) : -220
                    )
                
                // Orb 2 (Complementary royal purple)
                Circle()
                    .fill(Color.royalPurple.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(
                        x: dynamicOrbsEnabled ? (animateOrbs ? 160 : 70) : 120,
                        y: dynamicOrbsEnabled ? (animateOrbs ? 220 : 130) : 180
                    )
            }
        }
        .drawingGroup()
        .ignoresSafeArea()
        .onAppear {
            if dynamicOrbsEnabled {
                withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                    animateOrbs = true
                }
            }
        }
    }
}

struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear, .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
}

struct LiquidButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

extension View {
    func glassmorphic() -> some View {
        self.modifier(GlassmorphicModifier())
    }
    
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
    
    func blurBackground() -> some View {
        self.background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
    
    func hideKeyboard() {
        #if canImport(UIKit)
        guard let sharedApp = UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? UIApplication else { return }
        sharedApp.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

struct BrandingHeader: View {
    var coupleActive: Bool = false
    var selectedTab: Int = 0
    var onCalendarTap: (() -> Void)? = nil
    
    #if !WIDGET
    @State private var auth = AuthManager.shared
    #endif
    
    var body: some View {
        HStack {
            #if !WIDGET
            if selectedTab == 3 && auth.showArchivedOnly {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        auth.showArchivedOnly = false
                        auth.isChatSelectMode = false
                        NotificationCenter.default.post(name: Notification.Name("GlimpseChatClearSelection"), object: nil)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                        Text("Archived")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.activeCyan)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(height: 44)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.electricPurple)
                        .font(.system(size: 28))
                    Text("Glimpse")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(height: 44)
            }
            #else
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.electricPurple)
                    .font(.system(size: 28))
                Text("Glimpse")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(height: 44)
            #endif
            
            Spacer()
            
            if coupleActive && selectedTab == 0 {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onCalendarTap?()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 44, height: 44)
                            .blur(radius: 0.5)
                        
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.activeCyan)
                            .shadow(color: .activeCyan.opacity(0.8), radius: 8)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else if selectedTab == 3 {
                #if !WIDGET
                if auth.isChatSelectMode {
                    HStack(spacing: 16) {
                        Button {
                            NotificationCenter.default.post(name: Notification.Name("GlimpseChatArchiveSelected"), object: nil)
                        } label: {
                            Image(systemName: auth.showArchivedOnly ? "archivebox.bottom.fill" : "archivebox.fill")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(.activeCyan)
                        }
                        
                        Button {
                            NotificationCenter.default.post(name: Notification.Name("GlimpseChatDeleteSelected"), object: nil)
                        } label: {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(.red)
                        }
                        
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            auth.isChatSelectMode = false
                            NotificationCenter.default.post(name: Notification.Name("GlimpseChatClearSelection"), object: nil)
                        } label: {
                            Text("Done")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }
                } else {
                    Menu {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            auth.isChatSelectMode = true
                        } label: {
                            Label("Select Chats", systemImage: "checklist")
                        }
                        
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            NotificationCenter.default.post(name: Notification.Name("ShowCreateChatRoom"), object: nil)
                        } label: {
                            Label("New Chat Room", systemImage: "plus.circle")
                        }
                        
                        let archivedCount = auth.chatRooms.filter { room in
                            let suite = UserDefaults(suiteName: "group.glimpse.app")
                            let archivedString = suite?.string(forKey: "glimpse_archived_room_ids") ?? ""
                            let archivedIds = Set(archivedString.split(separator: ",").compactMap { Int($0) })
                            return archivedIds.contains(room.id)
                        }.count
                        
                        if !auth.showArchivedOnly && archivedCount > 0 {
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    auth.showArchivedOnly = true
                                }
                            } label: {
                                Label("Archived Chats", systemImage: "archivebox")
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 44, height: 44)
                                .blur(radius: 0.5)
                            
                            Image(systemName: "ellipsis")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                #else
                Color.clear
                    .frame(width: 44, height: 44)
                #endif
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 20)
        .padding(.top, 10) // Locked Top Padding
    }
}
