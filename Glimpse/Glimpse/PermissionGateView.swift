import SwiftUI

struct PermissionGateView: View {
    @State private var permissionManager = PermissionManager.shared
    @State private var animateItems = false
    
    var body: some View {
        ZStack {
            iOS26Background()
            
            VStack(spacing: 24) {
                // Sleek Intimate Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.electricPurple.opacity(0.2), .activeCyan.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .blur(radius: 10)
                    
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.electricPurple)
                        .shadow(color: .electricPurple.opacity(0.8), radius: 10)
                }
                .scaleEffect(animateItems ? 1.0 : 0.8)
                .opacity(animateItems ? 1.0 : 0.0)
                
                // Titles
                VStack(spacing: 8) {
                    Text("Device Permissions")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Glimpse requires the following hardware access to ensure 100% seamless background synchronization and updates with your partner.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .opacity(animateItems ? 1.0 : 0.0)
                .offset(y: animateItems ? 0 : 20)
                
                // Permissions List
                VStack(spacing: 16) {
                    // 1. Location (Must be "Always" / Selalu)
                    permissionRow(
                        title: "Location Tracking (Always)",
                        description: "Used to synchronize real-time background location updates with your partner.",
                        systemIcon: "location.circle.fill",
                        color: .activeCyan,
                        isGranted: permissionManager.isLocationGranted,
                        requestAction: permissionManager.requestLocation
                    )
                    
                    // 2. CoreMotion Activity
                    permissionRow(
                        title: "Motion & Activity",
                        description: "Detects whether you are walking, driving, or stationary to update your status.",
                        systemIcon: "figure.walk.circle.fill",
                        color: .electricPurple,
                        isGranted: permissionManager.isMotionGranted,
                        requestAction: permissionManager.requestMotion
                    )
                    
                    // 3. Notifications
                    permissionRow(
                        title: "Push Notifications",
                        description: "Enables instant delivery of love bursts, flashes, and intimate chat messages.",
                        systemIcon: "bell.circle.fill",
                        color: .orange,
                        isGranted: permissionManager.isNotificationsGranted,
                        requestAction: permissionManager.requestNotifications
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Settings button for disabled states
                VStack(spacing: 12) {
                    Text("If the permission prompt does not respond, please enable it manually inside System Settings.")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        permissionManager.openSettings()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                            Text("Open System Settings")
                        }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    .buttonStyle(PlainButtonStyle())
                }
                .opacity(animateItems ? 1.0 : 0.0)
                .offset(y: animateItems ? 0 : 20)
                
                // Author & Copyright Footer
                VStack(spacing: 4) {
                    Text("Designed & Developed by Lovinpeace")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                    
                    Text("© 2026 Glimpse. All rights reserved.")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.25))
                }
                .padding(.bottom, 8)
                .opacity(animateItems ? 1.0 : 0.0)
            }
            .padding(.top, 30)
            .padding(.bottom, 10)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateItems = true
            }
            permissionManager.checkAllPermissions()
        }
    }
    
    @ViewBuilder
    private func permissionRow(
        title: String,
        description: String,
        systemIcon: String,
        color: Color,
        isGranted: Bool,
        requestAction: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: systemIcon)
                .font(.system(size: 34))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.4), radius: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Action or Status Button
            if isGranted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Granted")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            } else {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    requestAction()
                } label: {
                    Text("Grant")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(color)
                        .cornerRadius(12)
                        .shadow(color: color.opacity(0.4), radius: 6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(14)
        .liquidGlass()
    }
}

#Preview {
    PermissionGateView()
}
