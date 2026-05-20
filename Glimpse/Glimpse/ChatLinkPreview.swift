import SwiftUI
import LinkPresentation

// MARK: - URL Detection helpers

extension String {
    var detectedURLs: [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
        let matches = detector.matches(in: self, options: [], range: NSRange(self.startIndex..., in: self))
        return matches.compactMap { $0.url }
    }

    var firstURL: URL? { detectedURLs.first }
    var containsURL: Bool { firstURL != nil }
}

// MARK: - Attributed text view with tappable links

struct LinkedTextView: View {
    let text: String
    let fontSize: CGFloat
    let foregroundColor: Color

    var body: some View {
        if let attrStr = buildAttributedString() {
            Text(attrStr)
                .font(.system(size: fontSize))
                .tint(.blue)
        } else {
            Text(text)
                .font(.system(size: fontSize))
                .foregroundColor(foregroundColor)
        }
    }

    private func buildAttributedString() -> AttributedString? {
        guard text.containsURL else { return nil }
        var result = AttributedString(text)
        // Apply base style
        result.foregroundColor = UIColor(foregroundColor)
        result.font = UIFont.systemFont(ofSize: fontSize)
        // Detect and mark URLs
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let ns = text as NSString
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))
            for match in matches {
                guard let range = Range(match.range, in: text) else { continue }
                let attrRange = AttributedString.Index(range.lowerBound, within: result)! ..< AttributedString.Index(range.upperBound, within: result)!
                result[attrRange].foregroundColor = UIColor.systemBlue
                result[attrRange].underlineStyle = .single
                if let url = match.url {
                    result[attrRange].link = url
                }
            }
        }
        return result
    }
}

// MARK: - Link Preview Card using LinkPresentation

struct ChatLinkPreviewCard: View {
    let url: URL
    let themeColor: Color

    @State private var metadata: LPLinkMetadata?
    @State private var isLoading = true
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if isLoading {
                loadingPlaceholder
            } else if let meta = metadata {
                previewCard(meta: meta)
            }
        }
        .onAppear { loadMetadata() }
    }

    private var loadingPlaceholder: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.08))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "link")
                        .font(.system(size: 20))
                        .foregroundColor(themeColor.opacity(0.5))
                )
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)).frame(height: 10).frame(maxWidth: 140)
                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.06)).frame(height: 8).frame(maxWidth: 100)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func previewCard(meta: LPLinkMetadata) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 10) {
                if let imageProvider = meta.imageProvider {
                    AsyncImageFromProvider(provider: imageProvider)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(themeColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "globe")
                                .font(.system(size: 22))
                                .foregroundColor(themeColor)
                        )
                }
                VStack(alignment: .leading, spacing: 3) {
                    if let title = meta.title, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    Text(url.host ?? url.absoluteString)
                        .font(.system(size: 10))
                        .foregroundColor(themeColor.opacity(0.8))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(themeColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func loadMetadata() {
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { meta, error in
            DispatchQueue.main.async {
                self.metadata = meta
                self.isLoading = false
            }
        }
    }
}

// MARK: - Helper to load image from NSItemProvider

struct AsyncImageFromProvider: View {
    let provider: NSItemProvider
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .overlay(Image(systemName: "photo").foregroundColor(.white.opacity(0.3)))
            }
        }
        .onAppear {
            provider.loadObject(ofClass: UIImage.self) { obj, _ in
                DispatchQueue.main.async {
                    self.image = obj as? UIImage
                }
            }
        }
    }
}
