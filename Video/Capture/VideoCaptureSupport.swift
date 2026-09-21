import CoreGraphics
import CoreVideo
import Foundation

enum CaptureVideoFormat {
    static let defaultWidth = 1440
    static let defaultHeight = 900
    static let width = defaultWidth
    static let height = defaultHeight
    static let timescale: Int32 = 600
    static let fps = 24.0
    static let minDuration = 6.0
    static let maxDuration = 24.0
    static let defaultDuration = 12.0
    static let startHold = 0.7
    static let endHold = 0.8
    static let shortPageDuration = 3.0
    static let scrollPixelsPerSecond = 92.0
}

enum VideoCaptureError: LocalizedError {
    case pixelBuffer
    case writerStart
    case appendFailed
    case finishFailed
    case noFrames
    case pageMetrics

    var errorDescription: String? {
        switch self {
        case .pixelBuffer:
            return "Could not allocate a video frame."
        case .writerStart:
            return "Could not start the MP4 writer."
        case .appendFailed:
            return "Could not write a video frame."
        case .finishFailed:
            return "Could not finish the MP4 file."
        case .noFrames:
            return "Recording stopped before any frames were captured."
        case .pageMetrics:
            return "Could not read the page height for scrolling."
        }
    }
}

enum PixelBufferFactory {
    static func make(width: Int, height: Int) throws -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferCGImageCompatibilityKey: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            ] as CFDictionary,
            &buffer
        )
        guard status == kCVReturnSuccess, let buffer else {
            throw VideoCaptureError.pixelBuffer
        }
        return buffer
    }

    static func draw(_ image: CGImage, into buffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            return
        }

        context.setFillColor(CGColor(gray: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .high
        context.draw(image, in: aspectFit(CGSize(width: image.width, height: image.height), in: CGSize(width: width, height: height)))
    }

    private static func aspectFit(_ size: CGSize, in container: CGSize) -> CGRect {
        let scale = min(container.width / max(size.width, 1), container.height / max(size.height, 1))
        let width = size.width * scale
        let height = size.height * scale
        return CGRect(
            x: (container.width - width) / 2,
            y: (container.height - height) / 2,
            width: width,
            height: height
        )
    }
}

enum ScrollTiming {
    static func totalDuration(maxScroll: Double) -> Double {
        if maxScroll <= 1 {
            return CaptureVideoFormat.shortPageDuration
        }
        let travel = maxScroll / CaptureVideoFormat.scrollPixelsPerSecond
        return CaptureVideoFormat.startHold + travel + CaptureVideoFormat.endHold
    }

    static func offset(elapsed: Double, maxScroll: Double) -> Double {
        guard maxScroll > 1 else { return 0 }
        let start = CaptureVideoFormat.startHold
        if elapsed <= start {
            return 0
        }
        let traveled = (elapsed - start) * CaptureVideoFormat.scrollPixelsPerSecond
        return min(max(traveled, 0), maxScroll)
    }

    static func pageProgress(elapsed: Double, maxScroll: Double) -> Double {
        guard maxScroll > 1 else { return 1 }
        return min(max(offset(elapsed: elapsed, maxScroll: maxScroll) / maxScroll, 0), 1)
    }
}
