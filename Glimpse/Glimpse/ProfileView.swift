import SwiftUI

struct ProfileView: View {
    let user: GlimpseUser
    let anniversaryDate: Date
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: user.profile_photo_url)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.electricPurple, lineWidth: 3))
                    .shadow(color: .electricPurple.opacity(0.3), radius: 15)
                    
                    Text(user.name)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                }
                .padding(.top, 40)
                
                // Moved Anniversary Ticker here
                AnniversaryTimerView(startDate: anniversaryDate)
                
                // Other Profile Stats
                VStack(spacing: 12) {
                    ProfileStatRow(icon: "heart.fill", title: "Relationship Status", value: "Paired")
                    ProfileStatRow(icon: "location.fill", title: "Last Known Location", value: user.location_name)
                    ProfileStatRow(icon: "battery.100", title: "Partner's Battery", value: "\(user.battery_level)%")
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    AuthManager.shared.logout()
                } label: {
                    Text("Logout")
                        .foregroundColor(.red)
                        .font(.system(size: 14, weight: .bold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.bottom, 120)
            }
        }
    }
}

struct ProfileStatRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.electricPurple)
                .frame(width: 32)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
            }
            Spacer()
        }
        .padding()
        .glassmorphic()
    }
}

#Preview {
    ProfileView(user: .mockPartner, anniversaryDate: CoupleResponse.mock.anniversaryDate)
}
