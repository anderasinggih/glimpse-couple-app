import Foundation
import CoreLocation
import UIKit

class LiveLocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LiveLocationManager()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    private var lastUploadedLocation: CLLocation?
    private var lastUploadTime: Date?
    private var isGeocoding = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // High accuracy but highly energy efficient!
        locationManager.distanceFilter = 30.0 // Only trigger didUpdateLocations if user moves more than 30 meters!
    }
    
    func startTracking() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Trigger immediate check to get the very first coordinate right on app launch
        if let currentLoc = locationManager.location {
            processAndUploadLocation(currentLoc)
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        processAndUploadLocation(location)
    }
    
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
