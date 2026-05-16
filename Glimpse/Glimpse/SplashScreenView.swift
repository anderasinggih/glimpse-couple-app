import SwiftUI

struct SplashScreenView: View {
    @State private var pulse = 1.0
    @State private var opacity = 1.0
    
    var body: some View {
        ZStack {
            Color.deepVelvet.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.electricPurple)
                    .scaleEffect(pulse)
                    .shadow(color: .electricPurple.opacity(0.5), radius: 20)
                
                Text("Glimpse")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)
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
