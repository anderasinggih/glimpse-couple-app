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
                // Keep only essential system controls that don't overlap
                MapScaleView()
            }
            .ignoresSafeArea()
            
            // Branding Overlay
            VStack(spacing: 0) {
                BrandingHeader()
                
                HStack {
                    Spacer()
                    // Top Right: Compass & Map Style (Liquid Glass)
                    VStack(spacing: 12) {
                        // System Compass (Custom placement)
                        MapCompass()
                            .mapControlVisibility(.visible)
                        
                        Button {
                            withAnimation(.spring()) {
                                isSatellite.toggle()
                            }
                        } label: {
                            Image(systemName: isSatellite ? "map.fill" : "globe.americas.fill")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .buttonStyle(.glass)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 10)
                }
                
                Spacer()
                
                // Bottom Right: Location Button (Moved down for better reachability)
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            position = .userLocation(fallback: .automatic)
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .buttonStyle(.glass)
                    .padding(.trailing, 16)
                    .padding(.bottom, 10)
                }
                
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
