#if !WIDGET
import Foundation
import AVFoundation
import Combine

class AudioRecordManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    static let shared = AudioRecordManager()
    
    @Published var isRecording = false
    @Published var duration: TimeInterval = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var fileURL: URL?
    
    private override init() {
        super.init()
    }
    
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            // mode: .voiceChat automatically enables built-in hardware/software noise reduction, gain control, and echo cancellation
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session for recording: \(error.localizedDescription)")
            return
        }
        
        let path = FileManager.default.temporaryDirectory
        let fileName = "voice_whisper_temp.m4a"
        fileURL = path.appendingPathComponent(fileName)
        
        // HD Voice settings: 24kHz mono AAC at 24kbps ensures crystal clear vocals with no low-pass feel, while remaining extremely lightweight (~3KB/sec or 180KB/minute)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 24000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 24000,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        do {
            guard let url = fileURL else { return }
            
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            duration = 0.0
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let recorder = self.audioRecorder else { return }
                self.duration = recorder.currentTime
                
                // Max 5 minutes (300 seconds)
                if self.duration >= 300.0 {
                    _ = self.stopRecording()
                }
            }
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() -> (url: URL, duration: TimeInterval)? {
        guard isRecording else { return nil }
        
        timer?.invalidate()
        timer = nil
        
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        
        let recordDuration = duration
        duration = 0.0
        
        if let url = fileURL {
            return (url, recordDuration)
        }
        return nil
    }
    
    func cancelRecording() {
        guard isRecording else { return }
        
        timer?.invalidate()
        timer = nil
        
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        duration = 0.0
        
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
#endif
