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
    
    // Wi-Fi location anchoring
    private let pathMonitor = NWPathMonitor()
    private let pathQueue = DispatchQueue(label: "WiFiPathMonitorQueue")
    private var currentWiFiBSSID: String? = nil
    private var cachedWiFiLocations: [String: CLLocationCoordinate2D] = [:] // [BSSID: Coordinate]
    private var isWiFiScanning = false
    
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
                    if !self.isStationary {
                        self.isStationary = true
                        self.log("🛑 Sensor Gerak (Stationary): HP terdeteksi DIAM di tempat. Menidurkan GPS demi hemat baterai!")
                        self.locationManager.stopUpdatingLocation()
                        LiveDebugLogger.shared.setGPSStatus("Sleeping (Stationary) 😴")
                    }
                } else if activity.walking || activity.running || activity.automotive || activity.cycling {
                    if self.isStationary {
                        self.isStationary = false
                        var tipeGerak = "bergerak"
                        if activity.walking { tipeGerak = "jalan kaki 🚶‍♂️" }
                        else if activity.running { tipeGerak = "berlari 🏃‍♂️" }
                        else if activity.automotive { tipeGerak = "berkendara 🚗" }
                        else if activity.cycling { tipeGerak = "sepeda 🚴‍♂️" }
                        
                        self.log("🏃‍♂️ Sensor Gerak (Moving): HP terdeteksi \(tipeGerak). Membangunkan GPS kembali secara real-time!")
                        self.locationManager.startUpdatingLocation()
                        LiveDebugLogger.shared.setGPSStatus("Active (\(tipeGerak)) 🏃‍♂️")
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
                    self.fetchCurrentWiFiAndLock()
                } else {
                    // Disconnected from Wi-Fi: Resume standard GPS tracking
                    if self.currentWiFiBSSID != nil {
                        self.log("📴 Wi-Fi Terputus: Lepas dari jangkar Wi-Fi. Mengaktifkan kembali chip GPS aktif!")
                        self.currentWiFiBSSID = nil
                        self.locationManager.startUpdatingLocation()
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
            
            if let net = network {
                let bssid = net.bssid
                self.currentWiFiBSSID = bssid
                
                self.log("📶 Wi-Fi Terhubung: Tersambung ke BSSID: \(bssid)")
                
                // If we already have a cached location for this Wi-Fi, lock to it (unless simulated!)
                if let cached = self.cachedWiFiLocations[bssid] {
                    var shouldStop = true
                    if #available(iOS 15.0, *) {
                        if self.locationManager.location?.sourceInformation?.isSimulatedBySoftware == true {
                            shouldStop = false
                        }
                    }
                    
                    if shouldStop {
                        self.log("😴 GPS Dinonaktifkan: Terkunci pada cache koordinat Wi-Fi. Menghemat baterai hingga 99%!")
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
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
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
