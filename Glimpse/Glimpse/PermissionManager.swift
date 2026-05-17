import Foundation
import CoreLocation
import CoreMotion
import UserNotifications
import UIKit
import SwiftUI

@Observable
class PermissionManager {
    static let shared = PermissionManager()
    
    var isLocationGranted = false
    var isMotionGranted = false
    var isNotificationsGranted = false
    
    // Checks if ALL required permissions are fully granted
    var hasAllPermissions: Bool {
        return isLocationGranted && isMotionGranted && isNotificationsGranted
    }
    
    private let locationManager = CLLocationManager()
    private let motionActivityManager = CMMotionActivityManager()
    
    private init() {
        checkAllPermissions()
        // Register observer to re-check when app returns from background / settings!
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        checkAllPermissions()
    }
    
    func checkAllPermissions() {
        // 1. Check Location Permission
        let locStatus = locationManager.authorizationStatus
        isLocationGranted = (locStatus == .authorizedAlways || locStatus == .authorizedWhenInUse)
        
        // 2. Check CoreMotion Activity Permission
        let motionStatus = CMMotionActivityManager.authorizationStatus()
        isMotionGranted = (motionStatus == .authorized)
        
        // 3. Check Notifications Permission (Async)
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.isNotificationsGranted = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // Request Actions
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        // Re-check after small delay in case they interact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkAllPermissions()
        }
    }
    
    func requestMotion() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            isMotionGranted = true
            return
        }
        
        // CMMotionActivityManager requests permission by starting updates once
        motionActivityManager.queryActivityStarting(from: Date(), to: Date(), to: .main) { [weak self] _, error in
            self?.checkAllPermissions()
        }
    }
    
    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            Task { @MainActor in
                self?.isNotificationsGranted = granted
                self?.checkAllPermissions()
            }
        }
    }
    
    // Open system settings if they previously denied it
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
