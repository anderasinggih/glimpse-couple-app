import SwiftUI

struct MainDashboardView: View {
    @State private var auth = AuthManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard
            dashboardView
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Tab 2: Map
            Group {
                if let partner = auth.partner {
                    FullPartnerMapView(user: partner)
                } else {
                    ProgressView("Finding partner...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.deepVelvet)
                }
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }
            .tag(1)
            
            // Tab 3: Flash
            FlashCameraView()
                .tabItem {
                    Label("Flash", systemImage: "camera.fill")
                }
                .tag(2)
            
            // Tab 4: Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(.electricPurple)
        .onAppear {
            Task { try? await auth.fetchState() }
        }
    }
    
    private var dashboardView: some View {
        ZStack(alignment: .top) {
            // Background
            iOS26Background()
            
            // Main Scroll Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer(minLength: 95)
                    
                    // Presence Interface (Map)
                    if let partner = auth.partner {
                        PartnerMapView(user: partner)
                            .frame(height: 340)
                            .shadow(color: .electricPurple.opacity(0.15), radius: 20)
                    }
                    
                    // Kabar Panel
                    KabarPanel()
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
            .ignoresSafeArea(.container, edges: .top)
            .refreshable {
                try? await auth.fetchState()
            }
            
            // Floating Header
            headerView
        }
    }
    
    private var headerView: some View {
        BrandingHeader()
    }
}

#Preview {
    MainDashboardView()
}
