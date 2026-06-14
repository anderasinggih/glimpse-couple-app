import WidgetKit
import SwiftUI

struct GlimpseWidgetEntry: TimelineEntry {
    let date: Date
    let partner: GlimpseUser?
    let image: UIImage?
}

struct GlimpseWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> GlimpseWidgetEntry {
        GlimpseWidgetEntry(date: Date(), partner: nil, image: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (GlimpseWidgetEntry) -> ()) {
        let sharedDefaults = UserDefaults(suiteName: "group.glimpse.app")
        let partnerData = sharedDefaults?.data(forKey: "latest_partner_data")
        let partner = try? JSONDecoder().decode(GlimpseUser.self, from: partnerData ?? Data())
        var partnerImage: UIImage? = nil
        
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
            let fileURL = groupURL.appendingPathComponent("widget_photo.jpg")
            if let data = try? Data(contentsOf: fileURL), let cachedImage = data.downsampledForWidget() {
                partnerImage = cachedImage
            }
        }
        
        let finalPartner = context.isPreview ? (partner ?? .mockPartner) : partner
        let entry = GlimpseWidgetEntry(date: Date(), partner: finalPartner, image: partnerImage)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GlimpseWidgetEntry>) -> ()) {
        Task {
            let (fetchedPartner, fetchedImage) = await fetchLatestPartnerData()
            
            var finalPartner = fetchedPartner
            var finalImage = fetchedImage
            
            // Cache Fallback if network fails
            if finalPartner == nil {
                let sharedDefaults = UserDefaults(suiteName: "group.glimpse.app")
                let partnerData = sharedDefaults?.data(forKey: "latest_partner_data")
                if let data = partnerData {
                    finalPartner = try? JSONDecoder().decode(GlimpseUser.self, from: data)
                }
            }
            
            // Image Fallback if network image download fails (e.g. because file was deleted on the server after client ACK)
            if finalImage == nil {
                if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
                    let fileURL = groupURL.appendingPathComponent("widget_photo.jpg")
                    if let cachedImage = UIImage(contentsOfFile: fileURL.path) {
                        finalImage = cachedImage
                    }
                }
            }
            
            let finalPartnerWithMock = context.isPreview ? (finalPartner ?? .mockPartner) : finalPartner
            let entry = GlimpseWidgetEntry(date: Date(), partner: finalPartnerWithMock, image: finalImage)
            
            // Set update policy (5 minutes for fresh active dev updates)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    // Background Network Direct Fetch Helper
    private func fetchLatestPartnerData() async -> (GlimpseUser?, UIImage?) {
        let sharedDefaults = UserDefaults(suiteName: "group.glimpse.app")
        guard let token = sharedDefaults?.string(forKey: "auth_token") else {
            return (nil, nil)
        }
        
        let apiBase = sharedDefaults?.string(forKey: "api_base_url") ?? "https://api.galleryfortwo.my.id/api"
        let urlString = "\(apiBase)/glimpse/state"
        guard let url = URL(string: urlString) else {
            return (nil, nil)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return (nil, nil)
            }
            
            struct WidgetPartnerData: Codable {
                let partner_data: GlimpseUser?
            }
            
            let responseData = try JSONDecoder().decode(WidgetPartnerData.self, from: data)
            guard let partner = responseData.partner_data else {
                return (nil, nil)
            }
            
            // Sync to shared Defaults Cache
            if let encoded = try? JSONEncoder().encode(partner) {
                sharedDefaults?.set(encoded, forKey: "latest_partner_data")
            }
            
            var photoURLString = partner.latest_photo_url ?? partner.profile_photo_url
            if !photoURLString.hasPrefix("http") {
                let cleanPath = photoURLString.hasPrefix("/") ? String(photoURLString.dropFirst()) : photoURLString
                var base = "https://api.galleryfortwo.my.id"
                if let apiURL = URL(string: apiBase),
                   let host = apiURL.host,
                   let scheme = apiURL.scheme {
                    base = "\(scheme)://\(host)"
                    if let port = apiURL.port {
                        base += ":\(port)"
                    }
                }
                photoURLString = cleanPath.contains("storage/") ? "\(base)/\(cleanPath)" : "\(base)/storage/\(cleanPath)"
            }
            
            var loadedImage: UIImage? = nil
            if let photoURL = URL(string: photoURLString),
               let (imageData, response) = try? await URLSession.shared.data(from: photoURL),
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                loadedImage = imageData.downsampledForWidget()
                
                // Only overwrite widget_photo.jpg if downsampling is successful to prevent cache corruption
                if let downsampledImage = loadedImage,
                   let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
                    let fileURL = groupURL.appendingPathComponent("widget_photo.jpg")
                    if let compressedData = downsampledImage.jpegData(compressionQuality: 0.6) {
                        try? compressedData.write(to: fileURL, options: .atomic)
                    } else {
                        try? imageData.write(to: fileURL, options: .atomic)
                    }
                }
            }
            
            return (partner, loadedImage)
        } catch {
            return (nil, nil)
        }
    }
}

struct GlimpseWidgetView : View {
    var entry: GlimpseWidgetEntry
    @Environment(\.widgetFamily) var family

    var locationFontSize: CGFloat {
        switch family {
        case .systemSmall: return 12
        case .systemMedium: return 18
        case .systemLarge: return 24
        default: return 12
        }
    }
    
    var timeFontSize: CGFloat {
        switch family {
        case .systemSmall: return 10
        case .systemMedium: return 14
        case .systemLarge: return 18
        default: return 10
        }
    }
    
    var noteFontSize: CGFloat {
        switch family {
        case .systemSmall: return 11
        case .systemMedium: return 16
        case .systemLarge: return 20
        default: return 11
        }
    }
    
    var gradientHeight: CGFloat {
        switch family {
        case .systemSmall: return 60
        case .systemMedium: return 80
        case .systemLarge: return 120
        default: return 60
        }
    }

    var paddingSize: CGFloat {
        switch family {
        case .systemSmall: return 12
        case .systemMedium: return 16
        case .systemLarge: return 20
        default: return 12
        }
    }

    var body: some View {
        ZStack {
            // Background / Foto Full Screen
            if let uiImage = entry.image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.deepVelvet
            }
            
            // Gradient agar teks terbaca
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.black.opacity(0.8), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: gradientHeight)
            }
            
            // Teks Info Pasangan
            // Teks Info Pasangan
            if let partner = entry.partner {
                let isFlash = partner.latest_photo_url != nil
                let displayLocation = isFlash ? (partner.latest_photo_location_name ?? partner.location_name ?? "Somewhere") : (partner.location_name ?? "Somewhere")
                let displayNote = isFlash ? (partner.latest_photo_status_note ?? partner.status_note) : partner.status_note
                let displayDate: Date = {
                    if isFlash, let created = partner.latest_photo_created_at {
                        let formatter = ISO8601DateFormatter()
                        return formatter.date(from: created) ?? partner.lastUpdatedDate
                    }
                    return partner.lastUpdatedDate
                }()
                
                VStack(alignment: .leading, spacing: 2) {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        HStack(spacing: 4) {
                            if isFlash {
                                Image(systemName: "camera.shutter.button.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.activeCyan)
                            }
                            Text(displayLocation)
                                .font(.system(size: locationFontSize, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text(displayDate, style: .time)
                            .font(.system(size: timeFontSize, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if let note = displayNote, !note.isEmpty {
                        Text(note)
                            .font(.system(size: noteFontSize))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .padding(paddingSize)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack {
                    Spacer()
                    Text("Awaiting Partner...")
                        .font(.system(size: locationFontSize, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(paddingSize)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct GlimpseWidget: Widget {
    let kind: String = "GlimpseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GlimpseWidgetProvider()) { entry in
            GlimpseWidgetView(entry: entry)
        }
        .configurationDisplayName("Glimpse Partner")
        .description("Menampilkan foto & lokasi pasangan.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

extension Data {
    func downsampledForWidget(to pointSize: CGSize = CGSize(width: 800, height: 800), scale: CGFloat = 1.0) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, imageSourceOptions) else {
            return nil
        }
        
        let maxDimensionInPixels = Swift.max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
    
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        return UIImage(cgImage: downsampledImage)
    }
}

