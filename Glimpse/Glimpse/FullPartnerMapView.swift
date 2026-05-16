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
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            // Static Branding Header (No blur)
            BrandingHeader()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                // Satellite Switcher: Floating above the card on the left
                Button("Map Style", systemImage: isSatellite ? "map.fill" : "globe.americas.fill") {
                    withAnimation { isSatellite.toggle() }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .padding(.leading, 20)
                
                // Bottom Info Card
                PartnerOverlayCard(user: user)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
        }
    }
}

#Preview {
    FullPartnerMapView(user: .mockPartner)
}
