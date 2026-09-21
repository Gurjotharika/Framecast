import AppKit
import Foundation
import UniformTypeIdentifiers

enum PageSnapshotError: LocalizedError {
    case noWebView
    case emptyView
    case encodeFailed

    var errorDescription: String? {
        switch self {
        case .noWebView:
            return "The page view is not ready yet."
        case .emptyView:
            return "The page has no size to capture. Make the window larger and try again."
        case .encodeFailed:
            return "Could not encode a PNG from the snapshot."
        }
    }
}

enum PNGSnapshot {
    static let targetWidth: CGFloat = 1440

    static func pngData(from image: NSImage) throws -> Data {
        var proposedRect = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
            throw PageSnapshotError.encodeFailed
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        bitmap.size = image.size
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw PageSnapshotError.encodeFailed
        }
        return data
    }

    static func jpegData(from image: NSImage, quality: Double) throws -> Data {
        var proposedRect = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
            throw PageSnapshotError.encodeFailed
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        bitmap.size = image.size
        let factor = min(max(quality, 0.1), 1)
        guard let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: factor]) else {
            throw PageSnapshotError.encodeFailed
        }
        return data
    }

    static func cgImage(of image: NSImage) -> CGImage? {
        var proposedRect = NSRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
    }

    static func pixelSize(of image: NSImage) -> CGSize {
        if let cgImage = cgImage(of: image) {
            return CGSize(width: cgImage.width, height: cgImage.height)
        }
        return image.size
    }

    static func defaultFilename(host: String?) -> String {
        let slug = (host ?? "site")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        return "\(slug)-snapshot.png"
    }
}
