import SwiftUI
import Combine

struct AnniversaryTimerView: View {
    let startDate: Date
    @State private var timeElapsed: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 4) {
            Text("OUR JOURNEY")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.adaptiveAccent.opacity(0.8))
                .kerning(2)
            
            Text(timeElapsed)
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundColor(.adaptiveAccent)
                .contentTransition(.numericText())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
