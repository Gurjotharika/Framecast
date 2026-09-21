import AVFoundation
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ExportVideoFormat: String, CaseIterable, Identifiable {
    case mp4
    case mov
    case gif

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mp4: "MP4"
        case .mov: "MOV"
        case .gif: "GIF"
        }
    }

    var fileExtension: String { rawValue }

    var contentType: UTType {
        switch self {
        case .mp4: .mpeg4Movie
        case .mov: .quickTimeMovie
        case .gif: .gif
        }
    }

    var avFileType: AVFileType? {
        switch self {
        case .mp4: .mp4
        case .mov: .mov
        case .gif: nil
        }
    }

    var includesAudio: Bool { self != .gif }
}

enum ExportQuality: String, CaseIterable, Identifiable {
    case low
    case medium
    case high
    case maximum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .maximum: "Maximum"
        }
    }

    func bitRate(width: Int, height: Int, fps: Double) -> Int {
        let pixels = max(width * height, 1)
        let factor: Double
        switch self {
        case .low: factor = 1.6
        case .medium: factor = 3.2
        case .high: factor = 5.5
        case .maximum: factor = 8.5
        }
        let rate = Double(pixels) * factor * max(fps / 30, 0.7)
        return min(40_000_000, max(1_200_000, Int(rate)))
    }
}

enum ExportFileSizeEstimate {
    static func format(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: max(bytes, 1))
    }

    static func bytes(
        width: Int,
        height: Int,
        fps: Double,
        duration: Double,
        quality: ExportQuality,
        format: ExportVideoFormat,
        includesAudio: Bool
    ) -> Int64 {
        let seconds = max(duration, 0.2)
        switch format {
        case .gif:
            let frames = max(Int((seconds * fps).rounded()), 1)
            return Int64(Double(max(width, 1) * max(height, 1) * frames) * 0.12)
        case .mp4, .mov:
            let videoBytes = Double(quality.bitRate(width: width, height: height, fps: fps)) * seconds / 8
            let audioBytes = includesAudio && format.includesAudio ? 128_000 * seconds / 8 : 0
            return Int64((videoBytes + audioBytes) * 1.04)
        }
    }
}

enum ExportFrameRate: Double, CaseIterable, Identifiable {
    case fps24 = 24
    case fps30 = 30
    case fps60 = 60

    var id: Double { rawValue }
    var title: String { "\(Int(rawValue)) fps" }
}

enum GIFExporter {
    static func start(url: URL, frameCount: Int, delay: Double) throws -> CGImageDestination {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.gif.identifier as CFString,
            frameCount,
            nil
        ) else {
            throw MockupError.renderFailed
        }
        CGImageDestinationSetProperties(
            destination,
            [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFLoopCount: 0,
                ],
            ] as CFDictionary
        )
        return destination
    }

    static func append(_ image: CGImage, to destination: CGImageDestination, delay: Double) {
        CGImageDestinationAddImage(
            destination,
            image,
            [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime: delay,
                    kCGImagePropertyGIFUnclampedDelayTime: delay,
                ],
            ] as CFDictionary
        )
    }

    static func finish(_ destination: CGImageDestination) throws {
        guard CGImageDestinationFinalize(destination) else {
            throw MockupError.renderFailed
        }
    }
}
