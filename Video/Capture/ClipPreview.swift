import AVFoundation
import AppKit
import CoreMedia
import Foundation

enum ClipPreview {
    static func duration(of url: URL) async -> Double {
        let asset = AVURLAsset(url: url)
        let time = (try? await asset.load(.duration)) ?? .zero
        return max(time.seconds, 0)
    }

    static func thumbnail(of url: URL, at seconds: Double = 0.4) async -> NSImage? {
        let asset = AVURLAsset(url: url)
        let duration = (try? await asset.load(.duration))?.seconds ?? 0
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 400)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.08, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.08, preferredTimescale: 600)
        let time = CMTime(seconds: min(max(seconds, 0), max(duration - 0.05, 0)), preferredTimescale: 600)
        guard let result = try? await generator.image(at: time) else { return nil }
        return NSImage(
            cgImage: result.image,
            size: NSSize(width: result.image.width, height: result.image.height)
        )
    }
}
