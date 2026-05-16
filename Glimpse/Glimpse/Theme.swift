import SwiftUI

extension Color {
    // Dark Mode Palette
    static let deepVelvet = Color(hex: "0D001A")
    static let electricPurple = Color(hex: "BF80FF")
    static let activeCyan = Color(hex: "00FFFF")
    
    // Light Mode Palette
    static let lavenderMist = Color(hex: "F9F5FF")
    static let royalPurple = Color(hex: "7A28FF")
    static let vividMint = Color(hex: "00FF88")
    
    // Adaptive Colors
    static var adaptiveBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(Color.deepVelvet) : UIColor(Color.lavenderMist)
        })
    }
    
    static var adaptiveAccent: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(Color.electricPurple) : UIColor(Color.royalPurple)
        })
    }
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
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea()
            
            // Animated Mesh-like Orbs
            Circle()
                .fill(Color.electricPurple.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: animate ? 100 : -100, y: animate ? -200 : -100)
            
            Circle()
                .fill(Color.royalPurple.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animate ? -150 : 150, y: animate ? 100 : 200)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .clear, .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

struct LiquidButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(x: configuration.isPressed ? 1.05 : 1.0) // Subtle stretch effect
            .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0), value: configuration.isPressed)
            .background(
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 1
                                )
                        )
                }
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            )
    }
}

extension View {
    func glassmorphic() -> some View {
        self.modifier(GlassmorphicModifier())
    }
    
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct BrandingHeader: View {
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
        }
        .padding(.horizontal, 20)
        .padding(.top, 10) // Locked Top Padding
    }
}
