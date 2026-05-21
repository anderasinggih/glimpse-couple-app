import SwiftUI

extension Color {
    // Dark Mode Palette
    static let deepVelvet = Color(hex: "0D001A")
    static let electricPurple = Color(hex: "BF80FF")
    
    static var activeCyan: Color {
        let hex = UserDefaults.standard.string(forKey: "glimpse_theme_accent") ?? "00FFFF"
        return Color(hex: hex)
    }
    
    // Light Mode Palette
    static let lavenderMist = Color(hex: "F9F5FF")
    static let royalPurple = Color(hex: "7A28FF")
    static let vividMint = Color(hex: "00FF88")
    
    // Adaptive Colors - Static for performance
    static let adaptiveBackground = Color.deepVelvet
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
    @AppStorage("glimpse_dynamic_orbs") var dynamicOrbsEnabled = true
    @State private var animateOrbs = false
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea()
            
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
    
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.electricPurple)
                    .font(.system(size: 28))
                Text("Glimpse")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
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
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    NotificationCenter.default.post(name: Notification.Name("ShowCreateChatRoom"), object: nil)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 44, height: 44)
                            .blur(radius: 0.5)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10) // Locked Top Padding
    }
}
