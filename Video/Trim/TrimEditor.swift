import AVFoundation
import AVKit
import AppKit
import CoreMedia
import Foundation
import Observation
import UniformTypeIdentifiers

struct FilmstripFrame: Identifiable {
    let id: Int
    let time: Double
    let image: NSImage
}

enum TrimError: LocalizedError {
    case noMovie
    case invalidRange
    case exportSession
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .noMovie:
            return "No video is loaded to trim."
        case .invalidRange:
            return "Set Out later than In before exporting."
        case .exportSession:
            return "This Mac could not create a trim export session."
        case .exportFailed(let message):
            return message
        }
    }
}

@MainActor
@Observable
final class TrimEditor {
    var assetURL: URL?
    var duration = 0.0
    var trimStart = 0.0
    var trimEnd = 0.0
    var playhead = 0.0
    var isPlaying = false
    var isExporting = false
    var statusText = "Drop an MP4 or MOV, or record a site."
    var errorMessage: String?
    var filmstrip: [FilmstripFrame] = []
    var hasAudio = false
    var waveform: [Float] = []

    let player = AVPlayer()

    var clipName: String {
        assetURL?.lastPathComponent ?? "No clip"
    }

    private var timeObserver: Any?
    private var endBoundaryObserver: Any?
    private var accessesSecurityScope = false

    var hasMovie: Bool { assetURL != nil && duration > 0 }

    var trimmedDuration: Double {
        max(trimEnd - trimStart, 0)
    }

    var canExport: Bool {
        hasMovie && trimmedDuration >= 0.2 && !isExporting
    }

    func load(_ url: URL, securityScoped: Bool = false) async {
        unload()
        if securityScoped {
            accessesSecurityScope = url.startAccessingSecurityScopedResource()
        }

        do {
            let asset = AVURLAsset(url: url)
            let loadedDuration = try await asset.load(.duration)
            let seconds = max(loadedDuration.seconds, 0)
            assetURL = url
            duration = seconds
            trimStart = 0
            trimEnd = seconds
            playhead = 0
            errorMessage = nil
            player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
            addObservers()
            seek(to: 0)
            statusText = String(format: "Loaded %.1fs clip. Drag the filmstrip range to trim.", seconds)
            hasAudio = await AudioWaveform.hasAudio(in: url)
            async let strip: Void = reloadFilmstrip()
            async let wave: Void = reloadWaveform()
            _ = await (strip, wave)
        } catch {
            errorMessage = error.localizedDescription
            statusText = "Could not open the video."
            if accessesSecurityScope {
                url.stopAccessingSecurityScopedResource()
                accessesSecurityScope = false
            }
        }
    }

    func unload() {
        pause()
        removeObservers()
        player.replaceCurrentItem(with: nil)
        if accessesSecurityScope, let assetURL {
            assetURL.stopAccessingSecurityScopedResource()
        }
        accessesSecurityScope = false
        assetURL = nil
        duration = 0
        trimStart = 0
        trimEnd = 0
        playhead = 0
        filmstrip = []
        hasAudio = false
        waveform = []
    }

    func togglePlay() {
        guard hasMovie else { return }
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        if playhead < trimStart || playhead >= trimEnd - 0.05 {
            seek(to: trimStart)
        }
        player.play()
        isPlaying = true
        refreshEndObserver()
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func seek(to seconds: Double) {
        let clamped = min(max(seconds, 0), max(duration, 0))
        playhead = clamped
        let time = CMTime(seconds: clamped, preferredTimescale: CaptureVideoFormat.timescale)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setTrimStart(_ seconds: Double) {
        trimStart = min(max(seconds, 0), max(trimEnd - 0.2, 0))
        refreshEndObserver()
    }

    func setTrimEnd(_ seconds: Double) {
        trimEnd = min(max(seconds, trimStart + 0.2), max(duration, trimStart + 0.2))
        refreshEndObserver()
    }

    func previewIn() {
        seek(to: trimStart)
    }

    func previewOut() {
        seek(to: max(trimEnd - 0.05, trimStart))
        refreshEndObserver()
    }

    func exportTrimmed() {
        Task { await export() }
    }

    func reloadFilmstrip() async {
        filmstrip = []
        guard let assetURL, duration > 0 else { return }

        let count = 64
        let asset = AVURLAsset(url: assetURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 160, height: 100)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: CaptureVideoFormat.timescale)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: CaptureVideoFormat.timescale)

        var frames: [FilmstripFrame] = []
        frames.reserveCapacity(count)
        for index in 0..<count {
            let time = duration * Double(index) / Double(max(count - 1, 1))
            let cmTime = CMTime(seconds: time, preferredTimescale: CaptureVideoFormat.timescale)
            guard let result = try? await generator.image(at: cmTime) else { continue }
            frames.append(
                FilmstripFrame(
                    id: index,
                    time: time,
                    image: NSImage(
                        cgImage: result.image,
                        size: NSSize(width: result.image.width, height: result.image.height)
                    )
                )
            )
        }
        filmstrip = frames
    }

    func reloadWaveform() async {
        waveform = []
        guard let assetURL else { return }
        waveform = await AudioWaveform.samples(from: assetURL)
    }

    func nearestFilmstrip(at seconds: Double) -> NSImage? {
        filmstrip.min(by: { abs($0.time - seconds) < abs($1.time - seconds) })?.image
    }

    func currentFrameImage() async throws -> NSImage {
        guard let assetURL else { throw TrimError.noMovie }
        let asset = AVURLAsset(url: assetURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let time = CMTime(seconds: playhead, preferredTimescale: CaptureVideoFormat.timescale)
        let result = try await generator.image(at: time)
        return NSImage(
            cgImage: result.image,
            size: NSSize(width: result.image.width, height: result.image.height)
        )
    }

    private func export() async {
        guard let assetURL else {
            fail(TrimError.noMovie)
            return
        }
        guard trimmedDuration >= 0.2 else {
            fail(TrimError.invalidRange)
            return
        }

        isExporting = true
        errorMessage = nil
        statusText = "Exporting trimmed clip…"
        pause()
        defer { isExporting = false }

        do {
            let destination = try await chooseSaveURL(from: assetURL)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }

            let asset = AVURLAsset(url: assetURL)
            guard let session = Self.makeExportSession(for: asset) else {
                throw TrimError.exportSession
            }

            session.timeRange = CMTimeRange(
                start: CMTime(seconds: trimStart, preferredTimescale: CaptureVideoFormat.timescale),
                end: CMTime(seconds: trimEnd, preferredTimescale: CaptureVideoFormat.timescale)
            )
            try await session.export(to: destination, as: .mp4)

            statusText = String(
                format: "Saved %.1fs trimmed MP4. Opening in QuickTime.",
                trimmedDuration
            )
            NSWorkspace.shared.open(destination)
        } catch is CancellationError {
            statusText = "Trim export cancelled."
        } catch {
            fail(error)
        }
    }

    private static func makeExportSession(for asset: AVAsset) -> AVAssetExportSession? {
        if let passthrough = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough),
           passthrough.supportedFileTypes.contains(.mp4) {
            return passthrough
        }
        return AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
    }

    private func chooseSaveURL(from source: URL) async throws -> URL {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = "Export trimmed video"
        panel.nameFieldStringValue = source.deletingPathExtension().lastPathComponent + "-trim.mp4"

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            throw CancellationError()
        }
        return url
    }

    private func addObservers() {
        removeObservers()
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.04, preferredTimescale: CaptureVideoFormat.timescale),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.playhead = time.seconds
            }
        }
        refreshEndObserver()
    }

    private func refreshEndObserver() {
        if let endBoundaryObserver {
            player.removeTimeObserver(endBoundaryObserver)
            self.endBoundaryObserver = nil
        }
        guard hasMovie else { return }
        let end = CMTime(seconds: trimEnd, preferredTimescale: CaptureVideoFormat.timescale)
        endBoundaryObserver = player.addBoundaryTimeObserver(
            forTimes: [NSValue(time: end)],
            queue: .main
        ) { [weak self] in
            Task { @MainActor in
                self?.pause()
                self?.seek(to: self?.trimEnd ?? 0)
            }
        }
    }

    private func removeObservers() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let endBoundaryObserver {
            player.removeTimeObserver(endBoundaryObserver)
            self.endBoundaryObserver = nil
        }
    }

    private func fail(_ error: Error) {
        errorMessage = error.localizedDescription
        statusText = "Could not export trimmed video."
    }
}
