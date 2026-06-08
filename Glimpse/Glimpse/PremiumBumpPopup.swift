import SwiftUI

struct PremiumBumpPopup: View {
    let totalMeetings: Int
    let dailyBumps: Int
    let onDismiss: () -> Void
    
    @State private var animateIcon = false
    @State private var animateBackground = false
    
    var body: some View {
        ZStack {
            // Darkened backdrop with premium blur
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    onDismiss()
                }
            
            // The Glassmorphic Modal Card
            VStack(spacing: 24) {
                // Top Visual: Glowing overlapping circles / phones to symbolize "Bump"
                ZStack {
                    // Pulsing Glow Orbs in background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.adaptiveAccent.opacity(0.35), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(animateBackground ? 1.3 : 0.85)
                        .opacity(animateBackground ? 0.8 : 0.4)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.electricPurple.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateBackground ? 0.9 : 1.25)
                        .opacity(animateBackground ? 0.5 : 0.8)
                    
                    // Main double-phone / handshake bump icon
                    HStack(spacing: -16) {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 46, weight: .semibold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(-15))
                            .offset(x: animateIcon ? -6 : -25)
                            .shadow(color: Color.electricPurple.opacity(0.6), radius: 8)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.red)
                            .scaleEffect(animateIcon ? 1.2 : 0.8)
                            .zIndex(10)
                            .shadow(color: .red.opacity(0.8), radius: 6)
                        
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 46, weight: .semibold))
                            .foregroundColor(Color.adaptiveAccent)
                            .rotationEffect(.degrees(15))
                            .offset(x: animateIcon ? 6 : 25)
                            .shadow(color: Color.adaptiveAccent.opacity(0.6), radius: 8)
                    }
                }
                .frame(height: 120)
                
                // Text Area
                VStack(spacing: 10) {
                    Text("BUMPED!")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.adaptiveAccent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.adaptiveAccent.opacity(0.4), radius: 6, y: 2)
                        .tracking(2)
                    
                    Text("Meetup #\(totalMeetings)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if dailyBumps > 1 {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("Bumped \(dailyBumps)x today")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                        )
                    } else {
                        Text("First bump of the day!")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Confirm / Close Button
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onDismiss()
                } label: {
                    Text("Awesome")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.adaptiveAccent, Color.adaptiveAccent.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.adaptiveAccent.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, 8)
            }
            .padding(28)
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.adaptiveBackground.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.35),
                                        Color.adaptiveAccent.opacity(0.2),
                                        Color.electricPurple.opacity(0.2),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 16)
            .scaleEffect(animateIcon ? 1.0 : 0.9)
            .opacity(animateIcon ? 1.0 : 0.0)
        }
        .onAppear {
            // Haptic notification for success
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0)) {
                animateIcon = true
            }
            
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateBackground = true
            }
        }
    }
}
