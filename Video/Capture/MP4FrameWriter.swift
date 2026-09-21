import AVFoundation
import CoreMedia
import CoreVideo
import Foundation

final class MP4FrameWriter {
    let url: URL
    private let writer: AVAssetWriter
    private let input: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor

    init(
        url: URL,
        width: Int,
        height: Int,
        realtime: Bool = true,
        bitRate: Int = 8_000_000,
        fps: Double = CaptureVideoFormat.fps,
        fileType: AVFileType = .mp4
    ) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        writer = try AVAssetWriter(outputURL: url, fileType: fileType)
        let frameRate = max(Int(fps.rounded()), 1)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: bitRate,
                AVVideoExpectedSourceFrameRateKey: frameRate,
                AVVideoMaxKeyFrameIntervalKey: frameRate,
            ],
        ]

        input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = realtime
        adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
            ]
        )

        guard writer.canAdd(input) else {
            throw VideoCaptureError.writerStart
        }
        writer.add(input)

        guard writer.startWriting() else {
            throw writer.error ?? VideoCaptureError.writerStart
        }
        writer.startSession(atSourceTime: .zero)
        self.url = url
    }

    func append(_ buffer: CVPixelBuffer, at time: CMTime) async throws {
        while !input.isReadyForMoreMediaData {
            try Task.checkCancellation()
            try await Task.sleep(for: .milliseconds(4))
        }

        guard adaptor.append(buffer, withPresentationTime: time) else {
            throw writer.error ?? VideoCaptureError.appendFailed
        }
    }

    func finish() async throws {
        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else {
            throw writer.error ?? VideoCaptureError.finishFailed
        }
    }

    func cancelAndDelete() {
        if writer.status == .writing {
            writer.cancelWriting()
        }
        try? FileManager.default.removeItem(at: url)
    }
}
