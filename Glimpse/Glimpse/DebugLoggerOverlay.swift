import SwiftUI

struct DebugLoggerOverlay: View {
    @ObservedObject var logger = LiveDebugLogger.shared
    @State private var isExpanded = false
    
    var body: some View {
        #if DEBUG
        ZStack {
            if isExpanded {
                // Dimmed background to focus on console
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isExpanded = false
                        }
                    }
                
                // Beautiful Glassmorphic Console
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⚡️ Glimpse Debugger")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 8, height: 8)
                                Text("Status: \(logger.gpsStatus)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        // Clear button
                        Button(action: { logger.clearLogs() }) {
                            Text("Clear")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(8)
                        }
                        
                        // Close button
                        Button(action: {
                            withAnimation(.spring()) {
                                isExpanded = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(14)
                    .background(Color.deepVelvet.opacity(0.95))
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Logs list
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                if logger.logs.isEmpty {
                                    Text("Waiting for GPS or CoreMotion events...")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.4))
                                        .padding(.vertical, 40)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    ForEach(logger.logs, id: \.self) { log in
                                        Text(log)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(getLogColor(log))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.2))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(10)
                        }
                    }
                    .background(Color.black.opacity(0.65))
                }
                .frame(height: 320)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .shadow(color: Color.black.opacity(0.5), radius: 20, y: 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                // Small Glassmorphic Floating Bubble (Bottom Right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                isExpanded = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "ladybug.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                
                                Text("GPS: \(shortStatus)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 80) // Floating beautifully above tab bar
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        #else
        EmptyView()
        #endif
    }
    
    private var shortStatus: String {
        let status = logger.gpsStatus
        if status.contains("Sleeping") { return "Sleep 😴" }
        if status.contains("Active") { return "Active 🛰️" }
        if status.contains("Simulator") { return "Xcode 🛸" }
        return "Unknown"
    }
    
    private var statusColor: Color {
        let status = logger.gpsStatus
        if status.contains("Sleeping") { return .yellow }
        if status.contains("Active") || status.contains("Simulator") { return .green }
        if status.contains("Stopped") { return .red }
        return .gray
    }
    
    private func getLogColor(_ log: String) -> Color {
        if log.contains("🛑") || log.contains("😴") { return .yellow }
        if log.contains("📤") { return .cyan }
        if log.contains("🏃‍♂️") || log.contains("🛸") { return .green }
        if log.contains("📴") { return .orange }
        return .white
    }
}
