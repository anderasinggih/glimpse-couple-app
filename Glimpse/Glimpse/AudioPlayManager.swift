#if !WIDGET
import Foundation
import AVFoundation
import Combine

class AudioPlayManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayManager()
    
    @Published var playingMessageId: Int? = nil
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0.0
    @Published var totalDuration: TimeInterval = 0.0
    @Published var playingMessage: ChatMessage? = nil
    @Published var navigateToMessageIdTrigger: Int? = nil
    @Published var playbackSpeed: Float = 1.0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    // Max number of cached audio files to keep in tmp
    private let maxCachedFiles = 20
    
    private override init() {
        super.init()
    }
    
    func hasLocalCache(for messageId: Int) -> Bool {
        let cachedFileURL = cachedURL(for: messageId)
        return FileManager.default.fileExists(atPath: cachedFileURL.path)
    }
    
    func preDownloadAudio(messageId: Int, urlString: String) {
        let cachedFileURL = cachedURL(for: messageId)
        if FileManager.default.fileExists(atPath: cachedFileURL.path) {
            return
        }
        guard let url = URL(string: urlString) else { return }
        guard let token = AuthManager.shared.userToken else { return }
        
        Task {
            var request = URLRequest(url: url)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
                try data.write(to: cachedFileURL, options: .atomic)
                evictOldCache(keeping: messageId)
            } catch {
                print("Failed to pre-download audio: \(error.localizedDescription)")
            }
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        player.currentTime = max(0, min(time, player.duration))
        currentTime = player.currentTime
    }
    
    func playAudio(messageId: Int, urlString: String, message: ChatMessage? = nil) {
        if playingMessageId == messageId {
            if isPlaying {
                pause()
            } else {
                resume()
            }
            return
        }
        
        stop()
        
        self.playingMessage = message
        let cachedFileURL = cachedURL(for: messageId)
        
        if FileManager.default.fileExists(atPath: cachedFileURL.path) {
            playingMessageId = messageId
            startPlayback(at: cachedFileURL)
            return
        }
        
        guard let url = URL(string: urlString) else { return }
        guard let token = AuthManager.shared.userToken else { return }
        
        playingMessageId = messageId
        
        Task {
            var request = URLRequest(url: url)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Failed to download audio message, status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    await MainActor.run { self.stop() }
                    return
                }
                
                let destURL = cachedURL(for: messageId)
                try data.write(to: destURL, options: .atomic)
                evictOldCache(keeping: messageId)
                
                await MainActor.run {
                    self.startPlayback(at: destURL)
                }
            } catch {
                print("Failed to download/play audio: \(error.localizedDescription)")
                await MainActor.run { self.stop() }
            }
        }
    }
    
    /// Save a locally-recorded file into the play cache so sender can replay without server
    func cacheLocalRecording(from sourceURL: URL, messageId: Int) {
        let dest = cachedURL(for: messageId)
        try? FileManager.default.copyItem(at: sourceURL, to: dest)
        evictOldCache(keeping: messageId)
    }
    
    private func cachedURL(for messageId: Int) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("playing_whisper_\(messageId).m4a")
    }
    
    /// Evict old cached audio files to keep tmp tidy (keeps newest maxCachedFiles)
    private func evictOldCache(keeping pinnedId: Int) {
        let tmp = FileManager.default.temporaryDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: [.creationDateKey])
            .filter({ $0.lastPathComponent.hasPrefix("playing_whisper_") && $0.pathExtension == "m4a" }) else { return }
        
        if files.count <= maxCachedFiles { return }
        
        let sorted = files.sorted {
            let d0 = (try? $0.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            let d1 = (try? $1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            return d0 < d1
        }
        
        let pinnedName = "playing_whisper_\(pinnedId).m4a"
        for file in sorted.prefix(files.count - maxCachedFiles) {
            if file.lastPathComponent != pinnedName {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
    
    private func startPlayback(at url: URL) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.enableRate = true
            audioPlayer?.rate = playbackSpeed
            audioPlayer?.play()
            
            isPlaying = true
            totalDuration = audioPlayer?.duration ?? 0.0
            currentTime = 0.0
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
                guard let self = self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
            }
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
            stop()
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        if audioPlayer == nil, let msgId = playingMessageId {
            let cachedFileURL = cachedURL(for: msgId)
            if FileManager.default.fileExists(atPath: cachedFileURL.path) {
                startPlayback(at: cachedFileURL)
                return
            }
        }
        audioPlayer?.enableRate = true
        audioPlayer?.rate = playbackSpeed
        audioPlayer?.play()
        isPlaying = true
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playingMessageId = nil
        currentTime = 0.0
        totalDuration = 0.0
        playingMessage = nil
        // NOTE: We intentionally do NOT delete the cached file here
        // so the user can replay the audio without re-downloading.
    }
    
    func setSpeed(_ speed: Float) {
        playbackSpeed = speed
        if let player = audioPlayer {
            player.enableRate = true
            player.rate = speed
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let finishedMessageId = playingMessageId
        timer?.invalidate()
        timer = nil
        audioPlayer = nil
        isPlaying = false
        currentTime = 0.0
        // We do NOT clear playingMessageId or playingMessage here so the floating player and bubble remain active for replaying
        
        if flag, let msgId = finishedMessageId {
            NotificationCenter.default.post(
                name: NSNotification.Name("GlimpseAudioPlaybackDidFinish"),
                object: nil,
                userInfo: ["messageId": msgId]
            )
        }
    }
}
#endif
