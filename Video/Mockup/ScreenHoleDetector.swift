import AppKit
import CoreGraphics

enum ScreenHoleDetector {
    static func detect(in image: NSImage) -> MockupScreenHole? {
        var proposed = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else {
            return nil
        }
        return detect(in: cgImage)
    }

    static func detect(in image: CGImage) -> MockupScreenHole? {
        let width = image.width
        let height = image.height
        guard width > 8, height > 8 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            return nil
        }
        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let step = max(min(width, height) / 220, 1)
        var dark: [(Int, Int)] = []
        dark.reserveCapacity(4_000)
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let i = (y * width + x) * 4
                let b = data[i]
                let g = data[i + 1]
                let r = data[i + 2]
                if Int(r) + Int(g) + Int(b) < 90 {
                    dark.append((x, y))
                }
            }
        }
        guard dark.count > 12 else { return nil }

        let minY = dark.map(\.1).min() ?? 0
        let maxY = dark.map(\.1).max() ?? height
        let span = max(maxY - minY, 1)
        let body = dark.filter { $0.1 < minY + Int(Double(span) * 0.78) }
        let points = body.isEmpty ? dark : body

        let xs = points.map(\.0)
        let ys = points.map(\.1)
        guard let minX = xs.min(), let maxX = xs.max(), let top = ys.min(), let bottom = ys.max() else {
            return nil
        }

        let topBand = points.filter { $0.1 <= top + max((bottom - top) / 8, step) }
        let bottomBand = points.filter { $0.1 >= bottom - max((bottom - top) / 8, step) }
        let topXs = topBand.map(\.0)
        let bottomXs = bottomBand.map(\.0)
        let tlX = CGFloat(topXs.min() ?? minX)
        let trX = CGFloat(topXs.max() ?? maxX)
        let blX = CGFloat(bottomXs.min() ?? minX)
        let brX = CGFloat(bottomXs.max() ?? maxX)
        let tlY = CGFloat(topBand.map(\.1).min() ?? top)
        let trY = CGFloat(topBand.map(\.1).min() ?? top)
        let blY = CGFloat(bottomBand.map(\.1).max() ?? bottom)
        let brY = CGFloat(bottomBand.map(\.1).max() ?? bottom)

        let inset: CGFloat = 0.012
        func norm(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(
                x: min(max(x / CGFloat(width) + inset, 0), 1),
                y: min(max(y / CGFloat(height) + inset, 0), 1)
            )
        }

        var hole = MockupScreenHole(points: [
            norm(tlX, tlY),
            CGPoint(x: min(max(trX / CGFloat(width) - inset, 0), 1), y: min(max(trY / CGFloat(height) + inset, 0), 1)),
            CGPoint(x: min(max(brX / CGFloat(width) - inset, 0), 1), y: min(max(brY / CGFloat(height) - inset, 0), 1)),
            CGPoint(x: min(max(blX / CGFloat(width) + inset, 0), 1), y: min(max(blY / CGFloat(height) - inset, 0), 1)),
        ])
        if hole.boundingRect.width < 0.08 || hole.boundingRect.height < 0.08 {
            hole = MockupScreenHole.rect(
                CGRect(
                    x: Double(minX) / Double(width),
                    y: Double(top) / Double(height),
                    width: Double(maxX - minX) / Double(width),
                    height: Double(bottom - top) / Double(height)
                ).insetBy(dx: 0.01, dy: 0.01)
            )
        }
        return hole
    }
}
