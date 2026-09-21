import AVFoundation
import CoreMedia
import Foundation

enum AudioWaveform {
    static func hasAudio(in url: URL) async -> Bool {
        let asset = AVURLAsset(url: url)
        let tracks = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
        return !tracks.isEmpty
    }

    static func samples(from url: URL, binCount: Int = 180) async -> [Float] {
        let count = max(binCount, 8)
        let asset = AVURLAsset(url: url)
        guard let track = try? await asset.loadTracks(withMediaType: .audio).first else {
            return []
        }

        return await Task.detached(priority: .utility) {
            readPeaks(asset: asset, track: track, binCount: count)
        }.value
    }

    nonisolated private static func readPeaks(asset: AVAsset, track: AVAssetTrack, binCount: Int) -> [Float] {
        guard let reader = try? AVAssetReader(asset: asset) else { return [] }
        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsNonInterleaved: false,
            ]
        )
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { return [] }
        reader.add(output)
        guard reader.startReading() else { return [] }

        var samples: [Int16] = []
        samples.reserveCapacity(220_000)
        while reader.status == .reading {
            guard let buffer = output.copyNextSampleBuffer() else { break }
            guard let block = CMSampleBufferGetDataBuffer(buffer) else { continue }
            var length = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
            if let dataPointer, length > 1 {
                dataPointer.withMemoryRebound(to: Int16.self, capacity: length / 2) { pointer in
                    samples.append(contentsOf: UnsafeBufferPointer(start: pointer, count: length / 2))
                }
            }
        }

        guard !samples.isEmpty else { return [] }
        let binSize = max(samples.count / binCount, 1)
        var peaks = [Float](repeating: 0, count: binCount)
        for index in 0..<binCount {
            let start = index * binSize
            let end = min(start + binSize, samples.count)
            guard start < end else { break }
            var peak: Int16 = 0
            for sample in samples[start..<end] {
                let magnitude = sample == Int16.min ? Int16.max : abs(sample)
                if magnitude > peak {
                    peak = magnitude
                }
            }
            peaks[index] = Float(peak) / Float(Int16.max)
        }
        if let maxPeak = peaks.max(), maxPeak > 0.04 {
            peaks = peaks.map { min($0 / maxPeak, 1) }
        }
        return peaks
    }
}

enum ExportAudioMixer {
    static func mix(
        videoURL: URL,
        sourceMovieURL: URL,
        start: Double,
        duration: Double,
        volume: Float,
        outputURL: URL,
        fileType: AVFileType
    ) async throws {
        let videoAsset = AVURLAsset(url: videoURL)
        let sourceAsset = AVURLAsset(url: sourceMovieURL)
        let composition = AVMutableComposition()

        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first,
              let compositionVideo = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
              ) else {
            throw MockupError.renderFailed
        }

        let videoDuration = try await videoAsset.load(.duration)
        try compositionVideo.insertTimeRange(
            CMTimeRange(start: .zero, duration: videoDuration),
            of: videoTrack,
            at: .zero
        )

        let audioTracks = try await sourceAsset.loadTracks(withMediaType: .audio)
        var audioMix: AVMutableAudioMix?
        if let sourceAudio = audioTracks.first,
           let compositionAudio = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            let timescale = CaptureVideoFormat.timescale
            let sourceStart = CMTime(seconds: max(start, 0), preferredTimescale: timescale)
            let sourceDuration = CMTime(seconds: max(duration, 0.05), preferredTimescale: timescale)
            try compositionAudio.insertTimeRange(
                CMTimeRange(start: sourceStart, duration: sourceDuration),
                of: sourceAudio,
                at: .zero
            )
            let parameters = AVMutableAudioMixInputParameters(track: compositionAudio)
            parameters.setVolume(max(volume, 0), at: .zero)
            let mix = AVMutableAudioMix()
            mix.inputParameters = [parameters]
            audioMix = mix
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw TrimError.exportSession
        }
        session.outputFileType = fileType
        session.audioMix = audioMix
        try await session.export(to: outputURL, as: fileType)
    }
}
