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
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $position) {
                    Annotation(user.name, coordinate: user.coordinate) {
                        PartnerMarker(photoUrl: user.profile_photo_url, isOffline: user.isOffline)
                    }
                }
                .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard(emphasis: .muted))
            .mapControls {
                MapUserLocationButton()
                MapScaleView()
            }
            .ignoresSafeArea()
            .safeAreaInset(edge: .top) {
                VStack(spacing: 10) {
                    BrandingHeader()
                    
                    HStack(spacing: 12) {
                        Spacer()
                        
                        // Compass and Satellite side-by-side
                        MapCompass()
                        
                        Button {
                            withAnimation { isSatellite.toggle() }
                        } label: {
                            Image(systemName: isSatellite ? "map.fill" : "globe.americas.fill")
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                    }
                    .padding(.trailing, 16)
                }
            }
            .safeAreaInset(edge: .bottom) {
                PartnerOverlayCard(user: user)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            }
        }
    }
}

#Preview {
    FullPartnerMapView(user: .mockPartner)
}
