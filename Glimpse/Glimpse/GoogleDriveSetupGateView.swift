#if !WIDGET
import SwiftUI

struct GoogleDriveSetupGateView: View {
    @Bindable var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var isConnecting = false
    @State private var errorMessage: String? = nil
    
    private var backupManager = GoogleDriveBackupManager.shared
    
    init(auth: AuthManager) {
        self.auth = auth
    }
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            // Decorative background glowing gradients
            VStack {
                Circle()
                    .fill(Color.activeCyan.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -80, y: -100)
                Spacer()
                Circle()
                    .fill(Color.electricPurple.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 80, y: 100)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Top Header Branding
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.electricPurple)
                    Text("Glimpse")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Icon Illustration
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.activeCyan.opacity(0.2), .electricPurple.opacity(0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 140, height: 140)
                    
                    // Inner ring
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    Image(systemName: "icloud.and.arrow.up.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.activeCyan, .electricPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Description Texts
                VStack(spacing: 12) {
                    Text("Secure Your Memories")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("To protect your privacy, Glimpse operates on a **zero-server storage** policy. All your messages, flashes, and logs are stored exclusively on your device and backed up securely to your personal Google Drive.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button {
                        connectDrive()
                    } label: {
                        HStack(spacing: 12) {
                            if isConnecting {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 18))
                                Text("Connect Google Drive")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.activeCyan)
                        .cornerRadius(14)
                        .shadow(color: Color.activeCyan.opacity(0.3), radius: 10, y: 4)
                    }
                    .disabled(isConnecting)
                    
                    Button {
                        auth.logout()
                    } label: {
                        Text("Log Out")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func connectDrive() {
        isConnecting = true
        errorMessage = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        Task {
            let success = await backupManager.connect(loginHint: auth.currentUser?.email)
            if success {
                // Auto restore from Google Drive to local on connection
                await MainActor.run {
                    backupManager.performRestoreFlow(auth: auth)
                }
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            } else {
                await MainActor.run {
                    errorMessage = "Failed to authenticate Google Drive. Please try again."
                }
            }
            await MainActor.run {
                isConnecting = false
            }
        }
    }
}
#endif
