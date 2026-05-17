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
                    Text("Perizinan Perangkat")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Glimpse memerlukan akses hardware berikut agar sinkronisasi intim dengan pasanganmu berjalan 100% sempurna.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .opacity(animateItems ? 1.0 : 0.0)
                .offset(y: animateItems ? 0 : 20)
                
                // Permissions List
                VStack(spacing: 16) {
                    // 1. Location
                    permissionRow(
                        title: "Pelacakan Lokasi",
                        description: "Mengetahui keberadaan pasanganmu secara background di peta.",
                        systemIcon: "location.circle.fill",
                        color: .activeCyan,
                        isGranted: permissionManager.isLocationGranted,
                        requestAction: permissionManager.requestLocation
                    )
                    
                    // 2. CoreMotion Activity
                    permissionRow(
                        title: "Gerakan & Aktivitas",
                        description: "Mendeteksi apakah kamu sedang berjalan, menyetir, atau diam.",
                        systemIcon: "figure.walk.circle.fill",
                        color: .electricPurple,
                        isGranted: permissionManager.isMotionGranted,
                        requestAction: permissionManager.requestMotion
                    )
                    
                    // 3. Notifications
                    permissionRow(
                        title: "Notifikasi Instan",
                        description: "Menerima sinyal cinta, kilatan Flash, dan pesan chat intim.",
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
                    Text("Jika tombol izin tidak merespons, silakan aktifkan manual melalui Pengaturan Sistem.")
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
                            Text("Buka Pengaturan Sistem")
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
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
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
                    Text("Diizinkan")
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
                    Text("Izinkan")
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
