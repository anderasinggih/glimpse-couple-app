import Foundation
import Combine

class LiveDebugLogger: ObservableObject {
    static let shared = LiveDebugLogger()
    
    @Published var logs: [String] = []
    @Published var gpsStatus: String = "Unknown"
    
    func log(_ message: String) {
        #if DEBUG
        DispatchQueue.main.async {
            // Append log with timestamp
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let timeString = formatter.string(from: Date())
            
            self.logs.insert("[\(timeString)] \(message)", at: 0)
            
            // Limit to last 50 logs
            if self.logs.count > 50 {
                self.logs.removeLast()
            }
        }
        #endif
    }
    
    func setGPSStatus(_ status: String) {
        #if DEBUG
        DispatchQueue.main.async {
            self.gpsStatus = status
        }
        #endif
    }
    
    func clearLogs() {
        #if DEBUG
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
        #endif
    }
}
