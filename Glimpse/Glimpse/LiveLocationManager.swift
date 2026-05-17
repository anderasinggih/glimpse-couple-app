import Foundation
import CoreLocation
import UIKit
import CoreMotion
import NetworkExtension
import Network

class LiveLocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LiveLocationManager()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // CoreMotion activity tracking
    private let motionActivityManager = CMMotionActivityManager()
    private let motionQueue = OperationQueue()
    private var isStationary = false
    private var motionDebounceTimer: Timer?
    
    // Wi-Fi location anchoring
    private let pathMonitor = NWPathMonitor()
    private let pathQueue = DispatchQueue(label: "WiFiPathMonitorQueue")
    private var currentWiFiBSSID: String? = nil
    private var cachedWiFiLocations: [String: CLLocationCoordinate2D] = [:] // [BSSID: Coordinate]
    private var isWiFiScanning = false
    private var wasUsingWiFi = false
    
    private var lastUploadedLocation: CLLocation?
    private var lastUploadTime: Date?
    private var isGeocoding = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // High accuracy but highly energy efficient!
        locationManager.distanceFilter = 30.0 // Only trigger didUpdateLocations if user moves more than 30 meters!
        
        // Background Tracking Capabilities
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = false
        
        setupNetworkPathMonitor()
    }
    
    func startTracking() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        LiveDebugLogger.shared.setGPSStatus("Active GPS 🛰️")
        
        startMotionTracking()
        
        // Trigger immediate check to get the very first coordinate right on app launch
        if let currentLoc = locationManager.location {
            processAndUploadLocation(currentLoc)
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        motionActivityManager.stopActivityUpdates()
        LiveDebugLogger.shared.setGPSStatus("Stopped 🛑")
    }
    
    // MARK: - Elite Debug Logging Helper (Zero overhead in App Store release build!)
    private func log(_ message: String) {
        #if DEBUG
        print("[⚡️ Glimpse GPS Debug] \(message)")
        LiveDebugLogger.shared.log(message)
        #endif
    }
    
    // MARK: - CoreMotion (Motion Detection)
    private func startMotionTracking() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        
        motionActivityManager.startActivityUpdates(to: motionQueue) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            Task { @MainActor in
                // Bypass motion sleep if location is simulated
                if #available(iOS 15.0, *) {
                    if self.locationManager.location?.sourceInformation?.isSimulatedBySoftware == true {
                        self.locationManager.startUpdatingLocation()
                        LiveDebugLogger.shared.setGPSStatus("Xcode Simulator Active 🛸")
                        self.log("🛸 Deteksi Xcode Simulator: GPS dibiarkan aktif untuk simulasi.")
                        return
                    }
                }
                
                if activity.stationary {
                    // Cancel any pending wake-up timers immediately since device is still
                    if self.motionDebounceTimer != nil {
                        self.motionDebounceTimer?.invalidate()
                        self.motionDebounceTimer = nil
                        self.log("🛑 Gerakan Singkat Terhenti: Mengabaikan gerakan minor. GPS tetap tidur!")
                        LiveDebugLogger.shared.setGPSStatus("Sleeping (Stationary) 😴")
                    }
                    
                    if !self.isStationary {
                        self.isStationary = true
                        self.log("🛑 Sensor Gerak (Stationary): HP terdeteksi DIAM di tempat. Menidurkan GPS demi hemat baterai!")
                        self.locationManager.stopUpdatingLocation()
                        LiveDebugLogger.shared.setGPSStatus("Sleeping (Stationary) 😴")
                    }
                } else {
                    // Non-stationary: Device is moving (walking, automotive, shaking, etc.)
                    
                    // 🏡 Wi-Fi Home Shield: If connected to Wi-Fi, only wake up GPS for vehicle movement (automotive/cycling)
                    // If we are just walking, playing games, or moving the phone at home, keep the GPS 100% powered down!
                    if self.currentWiFiBSSID != nil && !activity.automotive && !activity.cycling {
                        if self.motionDebounceTimer != nil {
                            self.motionDebounceTimer?.invalidate()
                            self.motionDebounceTimer = nil
                        }
                        if !self.isStationary {
                            self.isStationary = true
                            self.locationManager.stopUpdatingLocation()
                        }
                        LiveDebugLogger.shared.setGPSStatus("Sleeping (Wi-Fi Shield) 📶🏡😴")
                        return
                    }
                    
                    // Pre-emptive Dynamic GPS configuration based on activity type
                    var accuracy = kCLLocationAccuracyNearestTenMeters
                    var filter = 30.0
                    var tipeGerak = "bergerak"
                    
                    if activity.walking {
                        tipeGerak = "jalan kaki 🚶‍♂️"
                        accuracy = kCLLocationAccuracyNearestTenMeters
                        filter = 20.0
                    } else if activity.running {
                        tipeGerak = "berlari 🏃‍♂️"
                        accuracy = kCLLocationAccuracyNearestTenMeters
                        filter = 20.0
                    } else if activity.automotive {
                        tipeGerak = "berkendara 🚗"
                        accuracy = kCLLocationAccuracyBest
                        filter = 5.0
                    } else if activity.cycling {
                        tipeGerak = "sepeda 🚴‍♂️"
                        accuracy = kCLLocationAccuracyBest
                        filter = 10.0
                    }
                    
                    // Apply dynamic settings pre-emptively
                    if self.locationManager.desiredAccuracy != accuracy || self.locationManager.distanceFilter != filter {
                        self.locationManager.desiredAccuracy = accuracy
                        self.locationManager.distanceFilter = filter
                        self.log("⚡ Akurasi Dinamis (CM): GPS dikonfigurasi ke \(accuracy == kCLLocationAccuracyBest ? "AKURASI TERBAIK 🚗" : "HEMAT DAYA 🚶‍♂️") (Filter: \(filter)m)")
                    }
                    
                    if self.isStationary && self.motionDebounceTimer == nil {
                        self.log("⏳ Pergerakan Terdeteksi: Memantau apakah gerakan berlanjut selama 3 menit sebelum menyalakan GPS...")
                        LiveDebugLogger.shared.setGPSStatus("Evaluating Movement... ⏳")
                        
                        // Schedule GPS wake-up after 3 minutes (180 seconds) of continuous motion
                        self.motionDebounceTimer = Timer.scheduledTimer(withTimeInterval: 180.0, repeats: false) { [weak self] _ in
                            guard let self = self else { return }
                            
                            Task { @MainActor in
                                self.isStationary = false
                                self.motionDebounceTimer = nil
                                self.log("🏃‍♂️ Sensor Gerak (Sustained): Gerakan berlanjut selama 3 menit. Membangunkan GPS kembali secara real-time!")
                                self.locationManager.startUpdatingLocation()
                                LiveDebugLogger.shared.setGPSStatus("Active (\(tipeGerak)) 🏃‍♂️")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - NWPathMonitor (Wi-Fi Change Monitoring)
    private func setupNetworkPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            let isUsingWiFi = path.usesInterfaceType(.wifi)
            
            Task { @MainActor in
                if isUsingWiFi {
                    // Only call Wi-Fi fetch if we weren't previously using Wi-Fi (transition state!)
                    // This prevents spamming NEHotspotNetwork.fetchCurrent and lighting up the GPS indicator arrow!
                    if !self.wasUsingWiFi {
                        self.wasUsingWiFi = true
                        self.fetchCurrentWiFiAndLock()
                    }
                } else {
                    // Disconnected from Wi-Fi: Resume standard GPS tracking
                    if self.wasUsingWiFi {
                        self.wasUsingWiFi = false
                        self.log("📴 Wi-Fi Terputus: Jaringan berpindah ke Data Seluler. Menyalakan kembali GPS aktif!")
                        self.currentWiFiBSSID = nil
                        self.locationManager.startUpdatingLocation()
                        LiveDebugLogger.shared.setGPSStatus("Active GPS 🛰️")
                    }
                }
            }
        }
        pathMonitor.start(queue: pathQueue)
    }
    
    private func fetchCurrentWiFiAndLock() {
        guard !isWiFiScanning else { return }
        isWiFiScanning = true
        
        NEHotspotNetwork.fetchCurrent { [weak self] network in
            guard let self = self else { return }
            
            defer { self.isWiFiScanning = false }
            
            // Personal Dev Account Fallback: if network is nil (blocked by entitlement),
            // we use a synthetic BSSID "personal_dev_wifi" to let them test the Wi-Fi feature!
            let bssid = network?.bssid ?? "personal_dev_wifi_anchor"
            self.currentWiFiBSSID = bssid
            
            self.log("📶 Wi-Fi Terhubung: Tersambung ke Wi-Fi BSSID: \(bssid)")
            
            // HOTSPOT PROTECTION: Only sleep GPS if device is STATIONARY.
            // If device is moving, do NOT lock to cached Wi-Fi coordinates (user might be tethered to a moving hotspot in a car!)
            if !self.isStationary {
                self.log("🚗 Wi-Fi Terhubung tetapi HP sedang bergerak (Hotspot Mobil?). GPS dibiarkan AKTIF!")
                LiveDebugLogger.shared.setGPSStatus("Active (Moving on Wi-Fi) 📶🚗")
                self.locationManager.startUpdatingLocation()
                return
            }
            
            // If we already have a cached location for this Wi-Fi, lock to it (unless simulated!)
            if let cached = self.cachedWiFiLocations[bssid] {
                var shouldStop = true
                if #available(iOS 15.0, *) {
                    if self.locationManager.location?.sourceInformation?.isSimulatedBySoftware == true {
                        shouldStop = false
                    }
                }
                
                if shouldStop {
                    self.log("😴 GPS Dinonaktifkan: Terkunci pada cache koordinat Wi-Fi stasioner. Menghemat baterai!")
                    self.locationManager.stopUpdatingLocation()
                    LiveDebugLogger.shared.setGPSStatus("Sleeping (Wi-Fi Locked) 📶😴")
                }
                
                let dummyLocation = CLLocation(latitude: cached.latitude, longitude: cached.longitude)
                self.processAndUploadLocation(dummyLocation)
            } else {
                // Otherwise, get current coordinate first to cache it (unless simulated!)
                if let currentLoc = self.locationManager.location {
                    self.cachedWiFiLocations[bssid] = currentLoc.coordinate
                    self.log("💾 Wi-Fi Caching: Koordinat lokasi baru disimpan untuk Wi-Fi BSSID: \(bssid)")
                    
                    var shouldStop = true
                    if #available(iOS 15.0, *) {
                        if currentLoc.sourceInformation?.isSimulatedBySoftware == true {
                            shouldStop = false
                        }
                    }
                    
                    if shouldStop {
                        self.log("😴 GPS Dinonaktifkan: Titik Wi-Fi berhasil di-cache. Menidurkan GPS!")
                        self.locationManager.stopUpdatingLocation()
                        LiveDebugLogger.shared.setGPSStatus("Sleeping (Wi-Fi Cache Locked) 📶😴")
                    }
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Detect and set status if simulated
        if #available(iOS 15.0, *) {
            if location.sourceInformation?.isSimulatedBySoftware == true {
                LiveDebugLogger.shared.setGPSStatus("Xcode Simulator Active 🛸")
            }
        }
        
        // Dynamic accuracy fallback based on actual physical speed (Layer 2)
        let speed = location.speed // in meters/second
        if speed >= 5.0 { // Speed is >= 18 km/h (driving/cycling/etc)
            if locationManager.desiredAccuracy != kCLLocationAccuracyBest {
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.distanceFilter = 5.0
                self.log("⚡ Akurasi Dinamis (Speed): Kecepatan terdeteksi \(Int(speed * 3.6)) km/jam. Mengaktifkan GPS Akurasi Maksimal!")
            }
        } else if speed > 0.5 && speed < 3.0 { // Walking speed (1.8 km/h to 10.8 km/h)
            if locationManager.desiredAccuracy != kCLLocationAccuracyNearestTenMeters {
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.distanceFilter = 20.0
                self.log("⚡ Akurasi Dinamis (Speed): Kecepatan terdeteksi \(Int(speed * 3.6)) km/jam. Mengaktifkan GPS Akurasi Hemat Daya.")
            }
        }
        
        // Cache WiFi location if we just connected (but bypass if simulated!)
        if let bssid = currentWiFiBSSID, cachedWiFiLocations[bssid] == nil {
            cachedWiFiLocations[bssid] = location.coordinate
            self.log("💾 Wi-Fi Caching (GPS Lock): Menyimpan koordinat Wi-Fi BSSID \(bssid) dari satelit GPS aktif.")
            
            var shouldStop = true
            if #available(iOS 15.0, *) {
                if location.sourceInformation?.isSimulatedBySoftware == true {
                    shouldStop = false
                }
            }
            
            if shouldStop {
                self.log("😴 GPS Dinonaktifkan: Wi-Fi terdaftar dari pembacaan satelit. Menidurkan GPS!")
                locationManager.stopUpdatingLocation()
                LiveDebugLogger.shared.setGPSStatus("Sleeping (Wi-Fi GPS Lock) 📶😴")
            }
        }
        
        processAndUploadLocation(location)
    }
    
    // MARK: - Silent Upload Logic
    private func processAndUploadLocation(_ location: CLLocation) {
        guard AuthManager.shared.isAuthenticated else { return }
        
        // Rule: Only upload if it's the first upload, OR if the distance moved is > 30 meters, OR if > 5 minutes has elapsed
        let timeElapsed: TimeInterval = lastUploadTime != nil ? Date().timeIntervalSince(lastUploadTime!) : 9999.0
        let distanceMoved: CLLocationDistance = lastUploadedLocation != nil ? location.distance(from: lastUploadedLocation!) : 9999.0
        
        guard lastUploadedLocation == nil || distanceMoved >= 30.0 || timeElapsed >= 300.0 else {
            return
        }
        
        guard !isGeocoding else { return }
        isGeocoding = true
        
        Task {
            var locationName: String? = nil
            if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
               let placemark = placemarks.first {
                let street = placemark.thoroughfare ?? ""
                let subLoc = placemark.subLocality ?? placemark.locality ?? ""
                
                if !street.isEmpty && !subLoc.isEmpty {
                    locationName = "\(street), \(subLoc)"
                } else {
                    locationName = street.isEmpty ? subLoc : street
                }
            }
            
            self.log("📤 GPS Uplink: Mengirim data ke server Laravel! (Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude), Nama: \(locationName ?? "Tidak Diketahui"), Jarak: \(Int(distanceMoved))m, Waktu: \(Int(timeElapsed))s)")
            
            // Upload dynamically to server!
            AuthManager.shared.pushLocationAndStatus(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                locationName: locationName
            )
            
            await MainActor.run {
                self.lastUploadedLocation = location
                self.lastUploadTime = Date()
                self.isGeocoding = false
            }
        }
    }
}
