import SwiftUI
import Combine

struct AnniversaryTimerView: View {
    let startDate: Date
    @State private var timeElapsed: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 8) {
            Label("OUR JOURNEY", systemImage: "infinity")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.electricPurple)
                .kerning(1.5)
            
            Text(timeElapsed)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
        .onAppear(perform: updateTimer)
        .onReceive(timer) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                updateTimer()
            }
        }
    }
    
    private func updateTimer() {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .day, .hour, .minute, .second], from: startDate, to: now)
        
        let yrs = components.year ?? 0
        let days = components.day ?? 0
        let hrs = components.hour ?? 0
        let mins = components.minute ?? 0
        let secs = components.second ?? 0
        
        timeElapsed = "\(yrs)yr \(days)d \(hrs)hr \(mins)min \(secs)sec"
    }
}

#Preview {
    ZStack {
        Color.deepVelvet.ignoresSafeArea()
        AnniversaryTimerView(startDate: Calendar.current.date(byAdding: .year, value: -1, to: Date())!)
    }
}
