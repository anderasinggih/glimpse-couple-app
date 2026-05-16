import SwiftUI

struct MainDashboardView: View {
    @State private var auth = AuthManager.shared
    
    var body: some View {
        @Bindable var bindableAuth = auth
        return ZStack(alignment: .top) {
            // GLOBAL BACKGROUND to fill safe areas
            Color.deepVelvet.ignoresSafeArea()
            
            // Standard Native TabView
            TabView(selection: $bindableAuth.selectedTab) {
                // Tab 0: Dashboard
                dashboardView
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                // Tab 1: Map
                Group {
                    if let partner = auth.partner, auth.coupleActive {
                        FullPartnerMapView(user: partner)
                    } else {
                        VStack(spacing: 15) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Map is currently empty")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.deepVelvet)
                    }
                }
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(1)
                
                // Tab 2: Flash
                FlashCameraView()
                    .tabItem {
                        Label("Flash", systemImage: "camera.fill")
                    }
                    .tag(2)
                
                // Tab 3: Chat
                ChatView()
                    .tabItem {
                        Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    .tag(3)
                
                // Tab 4: Profile
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(4)
            }
            .tint(.electricPurple)
            .simultaneousGesture(
                DragGesture().onEnded { value in
                    // SWIPE LOGIC
                    let threshold: CGFloat = 100
                    if value.translation.width > threshold {
                        // Swipe Right -> Previous Tab
                        if auth.selectedTab > 0 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                auth.selectedTab -= 1
                            }
                        }
                    } else if value.translation.width < -threshold {
                        // Swipe Left -> Next Tab
                        if auth.selectedTab < 4 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                auth.selectedTab += 1
                            }
                        }
                    }
                }
            )
            
            // MASTER HEADER (Like app.blade.php)
            if auth.selectedTab != 3 {
                BrandingHeader()
                    .zIndex(100)
            }
        }
        .onAppear {
            Task { try? await auth.fetchState() }
        }
        .alert("Request Declined", isPresented: Bindable(auth).showInviteDeclinedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your connection request was declined or cancelled.")
        }
    }
    
    private var dashboardView: some View {
        ZStack(alignment: .top) {
            // Background
            iOS26Background()
            
            // Main Scroll Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer(minLength: 45)
                    
                    // Presence Interface (Interactive Flip Card)
                    // Presence Interface (Interactive Flip Card)
                    if let partner = auth.partner {
                        if auth.coupleActive {
                            if let reqBy = auth.disconnectRequestedBy, reqBy == partner.id {
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.title2)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Disconnect Request")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("\(partner.name) wants to unlink from you.")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        Spacer()
                                    }
                                    
                                    HStack(spacing: 15) {
                                        Button {
                                            Task { try? await auth.approveDisconnectPartner() }
                                        } label: {
                                            Text("Approve Disconnect")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.red)
                                                .cornerRadius(10)
                                        }
                                        
                                        Button {
                                            Task { try? await auth.cancelDisconnectPartner() }
                                        } label: {
                                            Text("Decline")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.white.opacity(0.15))
                                                .cornerRadius(10)
                                        }
                                        Spacer()
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.bottom, 5)
                            }
                            
                            PartnerMapView(user: partner)
                                .aspectRatio(1, contentMode: .fit)
                                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                        } else {
                            // PENDING CONNECTION STATES
                            if auth.invitedBy == auth.currentUser?.id {
                                // Sent Request Pending
                                VStack(spacing: 20) {
                                    Image(systemName: "hourglass.badge.plus")
                                        .font(.system(size: 60))
                                        .foregroundColor(.orange.opacity(0.8))
                                    
                                    Text("Invite Sent!")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("Waiting for \(partner.name) to accept your connection request.")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                    
                                    Button {
                                        Task { try? await auth.declineConnectRequest() }
                                    } label: {
                                        Text("Cancel Request")
                                            .font(.headline)
                                            .padding(.horizontal, 30)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.1))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                    .padding(.top, 10)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 45)
                                .glassmorphic()
                                .padding(.top, 40)
                            } else {
                                // Received Request Pending
                                VStack(spacing: 20) {
                                    Image(systemName: "heart.badge.plus.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.red.opacity(0.8))
                                    
                                    Text("Connection Request")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("\(partner.name) wants to connect with you on Glimpse!")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 12) {
                                        Button {
                                            Task { try? await auth.acceptConnectRequest() }
                                        } label: {
                                            Text("Accept Connection")
                                                .font(.headline)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(Color.electricPurple)
                                                .foregroundColor(.white)
                                                .cornerRadius(12)
                                        }
                                        
                                        Button {
                                            Task { try? await auth.declineConnectRequest() }
                                        } label: {
                                            Text("Decline")
                                                .font(.headline)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(Color.white.opacity(0.15))
                                                .foregroundColor(.white.opacity(0.8))
                                                .cornerRadius(12)
                                        }
                                    }
                                    .padding(.horizontal, 30)
                                    .padding(.top, 10)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .glassmorphic()
                                .padding(.top, 40)
                            }
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "person.2.slash.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("No Partner Yet")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Go to the Profile tab and enter your partner's invite code to start sharing your Glimpse!")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            Button {
                                withAnimation { auth.selectedTab = 4 }
                            } label: {
                                Text("Connect Partner")
                                    .font(.headline)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
                                    .background(Color.electricPurple)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                        .glassmorphic()
                        .padding(.top, 40)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
            .refreshable {
                try? await auth.fetchState()
            }
        }
    }
}

#Preview {
    MainDashboardView()
}
