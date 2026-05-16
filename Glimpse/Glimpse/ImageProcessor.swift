import UIKit

struct ImageProcessor {
    static func compressForGlimpse(image: UIImage) -> Data? {
        // 1. Downscale/Resize
        let maxDimension: CGFloat = 1200
        let size = image.size
        
        var targetSize: CGSize
        if size.width > size.height {
            let ratio = maxDimension / size.width
            targetSize = CGSize(width: maxDimension, height: size.height * ratio)
        } else {
            let ratio = maxDimension / size.height
            targetSize = CGSize(width: size.width * ratio, height: maxDimension)
        }
        
        // Skip resizing if already smaller
        if size.width <= maxDimension && size.height <= maxDimension {
            targetSize = size
        }
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        // 2. JPEG Compression Quality 0.75
        return resizedImage.jpegData(compressionQuality: 0.75)
    }
}
