import SwiftUI

struct MainDashboardView: View {
    @State private var partner: GlimpseUser = .mockPartner
    @State private var anniversaryDate = CoupleResponse.mock.anniversaryDate
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
            Text("Presence Map")
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
            ProfileView(user: partner, anniversaryDate: anniversaryDate)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(.electricPurple)
    }
    
    private var dashboardView: some View {
        ZStack(alignment: .top) {
            // Background
            iOS26Background()
            
            // Main Scroll Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Increased Spacer for better initial placement
                    Spacer(minLength: 95)
                    
                    // Presence Interface (Map)
                    PartnerMapView(user: partner)
                        .frame(height: 340)
                        .shadow(color: .electricPurple.opacity(0.15), radius: 20)
                    
                    // Kabar Panel
                    KabarPanel()
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
            .ignoresSafeArea(.container, edges: .top)
            
            // Floating Header - Exactly matched with Flash
            headerView
                .padding(.top, 10)
        }
    }
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.electricPurple)
                    .font(.system(size: 28))
                
                Text("Glimpse")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    MainDashboardView()
}
