import SwiftUI
import MapKit

struct FullPartnerMapView: View {
    let user: GlimpseUser
    @State private var position: MapCameraPosition
    
    init(user: GlimpseUser) {
        self.user = user
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: user.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Full Screen Map
            Map(position: $position) {
                Annotation(user.name, coordinate: user.coordinate) {
                    PartnerMarker(photoUrl: user.profile_photo_url, isOffline: user.isOffline)
                }
            }
            .mapStyle(.standard(emphasis: .muted))
            .ignoresSafeArea()
            
            // Branding Overlay
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.electricPurple)
                        Text("Glimpse")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.leading, 10)
                    
                    Spacer()
                }
                .padding(.top, 10)
                
                Spacer()
                
                // Bottom Info Card
                PartnerOverlayCard(user: user)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
        }
    }
}

#Preview {
    FullPartnerMapView(user: .mockPartner)
}
