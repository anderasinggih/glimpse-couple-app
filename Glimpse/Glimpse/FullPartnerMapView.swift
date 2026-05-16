import SwiftUI
import MapKit

struct FullPartnerMapView: View {
    let user: GlimpseUser
    @State private var position: MapCameraPosition
    
    @State private var mapStyle: MapStyle = .standard(emphasis: .muted)
    @State private var isSatellite = true
    
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
                MapScaleView()
            }
            .ignoresSafeArea()
            
            // Branding Overlay
            VStack(spacing: 0) {
                Spacer(minLength: 50) // Space for master header from shell
                
                Spacer()
                
                // Map Action Buttons - Grouped on the right
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // Satellite toggle
                        Button {
                            withAnimation(.spring()) {
                                isSatellite.toggle()
                            }
                        } label: {
                            Image(systemName: isSatellite ? "map.fill" : "globe.americas.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 46, height: 46)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                        }
                        
                        // Re-center on Partner
                        Button {
                            withAnimation(.spring()) {
                                position = .region(MKCoordinateRegion(
                                    center: user.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                ))
                            }
                        } label: {
                            Image(systemName: "scope")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 46, height: 46)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
                }
                
                // Bottom Info Card
                PartnerOverlayCard(user: user, locationOverride: nil, isMinimal: false)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 30)
            }
        }
    }
}

#Preview {
    FullPartnerMapView(user: .mockPartner)
}
