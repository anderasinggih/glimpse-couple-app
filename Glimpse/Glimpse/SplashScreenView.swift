import SwiftUI

struct SplashScreenView: View {
    @State private var pulse = 1.0
    @State private var opacity = 1.0
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.electricPurple)
                    .scaleEffect(pulse)
                    .shadow(color: .electricPurple.opacity(0.5), radius: 20)
                
                Text("Glimpse")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                Spacer()
            }
            
            // Premium Splash Footer (Author & Copyright)
            VStack {
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Created by Lovinpeace")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.electricPurple.opacity(0.85))
                    
                    Text("© 2026 Lovinpeace. All Rights Reserved.")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.25))
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            // Light Beating animation - non-repeating or shorter to save CPU
            withAnimation(.easeInOut(duration: 0.8).repeatCount(3, autoreverses: true)) {
                pulse = 1.15
            }
            
            // Text fade in
            withAnimation(.easeIn(duration: 0.6).delay(0.2)) {
                opacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
