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
        
        setupNetworkPathMonitor()
    }
    
    func startTracking() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        startMotionTracking()
        
        // Trigger immediate check to get the very first coordinate right on app launch
        if let currentLoc = locationManager.location {
            processAndUploadLocation(currentLoc)
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        motionActivityManager.stopActivityUpdates()
    }
    
    // MARK: - CoreMotion (Motion Detection)
    private func startMotionTracking() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        
        motionActivityManager.startActivityUpdates(to: motionQueue) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            Task { @MainActor in
                if activity.stationary {
                    if !self.isStationary {
                        self.isStationary = true
                        print("[Glimpse GPS] Device is stationary. Stopping GPS updates to conserve battery.")
                        self.locationManager.stopUpdatingLocation()
                    }
                } else if activity.walking || activity.running || activity.automotive || activity.cycling {
                    if self.isStationary {
                        self.isStationary = false
                        print("[Glimpse GPS] Device is moving. Resuming active GPS tracking.")
                        self.locationManager.startUpdatingLocation()
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
                    // Check SSID/BSSID and lock coordinates if possible
                    self.fetchCurrentWiFiAndLock()
                } else {
                    // Disconnected from Wi-Fi: Resume standard GPS tracking
                    if self.currentWiFiBSSID != nil {
                        print("[Glimpse WiFi] Disconnected from Wi-Fi network. Resuming standard GPS tracking.")
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
                
                print("[Glimpse WiFi] Anchored to Wi-Fi BSSID: \(bssid)")
                
                // If we already have a cached location for this Wi-Fi, we can immediately lock to it and stop GPS!
                if let cached = self.cachedWiFiLocations[bssid] {
                    print("[Glimpse WiFi] Using cached coordinates for Wi-Fi. Stopping GPS to save 99% battery.")
                    self.locationManager.stopUpdatingLocation()
                    
                    let dummyLocation = CLLocation(latitude: cached.latitude, longitude: cached.longitude)
                    self.processAndUploadLocation(dummyLocation)
                } else {
                    // Otherwise, get current coordinate first to cache it
                    if let currentLoc = self.locationManager.location {
                        self.cachedWiFiLocations[bssid] = currentLoc.coordinate
                        print("[Glimpse WiFi] Cached location for BSSID: \(bssid)")
                        self.locationManager.stopUpdatingLocation()
                    }
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Cache WiFi location if we just connected
        if let bssid = currentWiFiBSSID, cachedWiFiLocations[bssid] == nil {
            cachedWiFiLocations[bssid] = location.coordinate
            print("[Glimpse WiFi] Cached location for BSSID: \(bssid) on active GPS update.")
            locationManager.stopUpdatingLocation()
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
