import SwiftUI

struct MainDashboardView: View {
    @State private var partner: GlimpseUser = .mockPartner
    @State private var anniversaryDate = CoupleResponse.mock.anniversaryDate
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard
            NavigationStack {
                dashboardContent
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            headerView
                        }
                    }
            }
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
            Text("Flash Photo")
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
    
    private var dashboardContent: some View {
        ZStack {
            iOS26Background()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Presence Interface (Map) - Compact
                    PartnerMapView(user: partner)
                        .frame(height: 340)
                        .padding(.top, 12)
                        .shadow(color: .electricPurple.opacity(0.15), radius: 20)
                    
                    // Kabar Panel (Actions) - Compact
                    KabarPanel()
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .foregroundColor(Color.electricPurple)
                .font(.system(size: 24))
            
            Text("Glimpse")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.leading, 4)
    }
}
#Preview {
    NavigationStack {
        MainDashboardView()
    }
}
