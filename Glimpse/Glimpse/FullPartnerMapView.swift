import SwiftUI
import MapKit

struct FullPartnerMapView: View {
    let user: GlimpseUser
    @State private var position: MapCameraPosition
    
    @State private var mapStyle: MapStyle = .standard(emphasis: .muted)
    @State private var isSatellite = false
    
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
            .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard(emphasis: .muted))
            .mapControls {
                MapCompass()
                MapUserLocationButton()
                MapScaleView()
            }
            .safeAreaInset(edge: .bottom) {
                // Bottom Info Card acts as a safe area inset, pushing map controls UP
                PartnerOverlayCard(user: user)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
            .ignoresSafeArea()
            
            // Branding Overlay
            VStack(spacing: 0) {
                BrandingHeader()
                
                // Satellite toggle - positioned BELOW safe area / status bar
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring()) {
                            isSatellite.toggle()
                        }
                    } label: {
                        Image(systemName: isSatellite ? "map.fill" : "globe.americas.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    FullPartnerMapView(user: .mockPartner)
}
