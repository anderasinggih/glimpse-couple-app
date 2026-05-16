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
        let photoUrlString = partner?.latest_photo_url ?? partner?.profile_photo_url
        if let urlString = photoUrlString {
            let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
            let finalUrlString = cleanPath.contains("http") ? urlString : (cleanPath.contains("storage/") ? "http://192.168.0.103:8000/\(cleanPath)" : "http://192.168.0.103:8000/storage/\(cleanPath)")
            
            let cacheKey = "img_cache_\(finalUrlString)"
            if let data = sharedDefaults?.data(forKey: cacheKey), let cachedImage = data.downsampledForWidget() {
                partnerImage = cachedImage
            }
        }
        let finalPartner = context.isPreview ? (partner ?? .mockPartner) : partner
        let entry = GlimpseWidgetEntry(date: Date(), partner: finalPartner, image: partnerImage)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GlimpseWidgetEntry>) -> ()) {
        let sharedDefaults = UserDefaults(suiteName: "group.glimpse.app")
        let partnerData = sharedDefaults?.data(forKey: "latest_partner_data")
        
        var partner: GlimpseUser? = nil
        
        if let data = partnerData {
            partner = try? JSONDecoder().decode(GlimpseUser.self, from: data)
        }
        
        var partnerImage: UIImage? = nil
        let photoUrlString = partner?.latest_photo_url ?? partner?.profile_photo_url
        if let urlString = photoUrlString {
            let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
            let finalUrlString = cleanPath.contains("http") ? urlString : (cleanPath.contains("storage/") ? "http://192.168.0.103:8000/\(cleanPath)" : "http://192.168.0.103:8000/storage/\(cleanPath)")
            
            let cacheKey = "img_cache_\(finalUrlString)"
            if let data = sharedDefaults?.data(forKey: cacheKey), let cachedImage = data.downsampledForWidget() {
                partnerImage = cachedImage
            }
        }
        
        // Buat satu entry yang valid
        let finalPartner = context.isPreview ? (partner ?? .mockPartner) : partner
        let entry = GlimpseWidgetEntry(date: Date(), partner: finalPartner, image: partnerImage)
        
        // Update setiap 15 menit
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
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
                VStack(alignment: .leading, spacing: 2) {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        Text(partner.location_name ?? "Somewhere")
                            .font(.system(size: locationFontSize, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(partner.lastUpdatedDate, style: .time)
                            .font(.system(size: timeFontSize, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if let note = partner.status_note, !note.isEmpty {
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

