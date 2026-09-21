import AppKit
import CoreMedia
import Foundation
import Observation
import UniformTypeIdentifiers
import WebKit

@MainActor
@Observable
final class CaptureSession {
    var urlText = StageframeMemory.urlText {
        didSet { StageframeMemory.urlText = urlText }
    }
    var loadedURL: URL?
    var loadToken = 0
    var isLoading = false
    var isSnapshotting = false
    var isRecording = false
    var hideCookieBanners = StageframeMemory.hideCookieBanners {
        didSet { StageframeMemory.hideCookieBanners = hideCookieBanners }
    }
    var durationSeconds = StageframeMemory.durationSeconds {
        didSet { StageframeMemory.durationSeconds = durationSeconds }
    }
    var recordWidth = StageframeMemory.recordWidth {
        didSet { StageframeMemory.recordWidth = ExportSizePreset.evenPixel(recordWidth) }
    }
    var recordHeight = StageframeMemory.recordHeight {
        didSet { StageframeMemory.recordHeight = ExportSizePreset.evenPixel(recordHeight) }
    }

    var recordSizeLabel: String {
        "\(recordWidth)×\(recordHeight)"
    }

    func applyRecordSize(width: Int) {
        applyRecordPreset(RecordSizePreset.matching(width: width))
    }

    func applyRecordPreset(_ preset: RecordSizePreset) {
        recordWidth = preset.width
        recordHeight = preset.height
    }

    func lockRecordAspect() {
        applyRecordPreset(RecordSizePreset.matching(width: recordWidth))
    }
    var statusText = "Load a site, record a clip, or drop an MP4."
    var errorMessage: String?
    var lastSnapshotURL: URL?
    var lastSnapshotPixelSize: CGSize?
    var lastVideoURL: URL?
    private(set) var lastPageImage: NSImage?

    private(set) weak var webView: WKWebView?
    private var recordingTask: Task<Void, Never>?
    private var userStoppedRecording = false

    var resolvedURL: URL? {
        WebsiteURL.resolve(urlText)
    }

    var isBusy: Bool {
        isLoading || isSnapshotting || isRecording
    }

    var canLoad: Bool {
        resolvedURL != nil && !isBusy
    }

    var canSnapshot: Bool {
        loadedURL != nil && webView != nil && !isBusy
    }

    var canRecord: Bool {
        loadedURL != nil && webView != nil && !isBusy
    }

    func attach(_ webView: WKWebView) {
        self.webView = webView
    }

    func load() {
        guard let url = resolvedURL else { return }
        errorMessage = nil
        isLoading = true
        statusText = "Loading \(url.host ?? url.absoluteString)…"
        loadedURL = url
        loadToken += 1
    }

    func didStart() {
        guard !isRecording else { return }
        isLoading = true
    }

    func didFinish(url: URL?) {
        guard !isRecording else { return }
        isLoading = false
        errorMessage = nil
        let host = url?.host ?? loadedURL?.host ?? "site"
        statusText = "Loaded \(host). Record a scrolling MP4, or Snapshot for a PNG."
    }

    func didFail(_ error: Error) {
        guard !isRecording else { return }
        isLoading = false
        errorMessage = error.localizedDescription
        statusText = "Could not load the site."
    }

    func snapshot() {
        Task { await captureSnapshot() }
    }

    func record() {
        recordingTask?.cancel()
        userStoppedRecording = false
        recordingTask = Task { await captureVideo() }
    }

    func stopRecording() {
        userStoppedRecording = true
        recordingTask?.cancel()
    }

    private func captureSnapshot() async {
        guard let webView else {
            failCapture(PageSnapshotError.noWebView, status: "Could not capture snapshot.")
            return
        }

        let bounds = webView.bounds
        guard bounds.width > 1, bounds.height > 1 else {
            failCapture(PageSnapshotError.emptyView, status: "Could not capture snapshot.")
            return
        }

        isSnapshotting = true
        errorMessage = nil
        statusText = "Capturing snapshot…"
        defer { isSnapshotting = false }

        do {
            if hideCookieBanners {
                await CookieBannerHider.hide(in: webView)
            }
            let image = try await snapshotImage(from: webView, afterScreenUpdates: true)
            let data = try PNGSnapshot.pngData(from: image)
            let destination = try await chooseSaveURL(
                host: webView.url?.host ?? loadedURL?.host,
                contentType: .png,
                filename: PNGSnapshot.defaultFilename(host: webView.url?.host ?? loadedURL?.host),
                title: "Save snapshot"
            )
            try data.write(to: destination, options: .atomic)

            lastSnapshotURL = destination
            lastSnapshotPixelSize = PNGSnapshot.pixelSize(of: image)
            lastPageImage = image
            let width = Int(lastSnapshotPixelSize?.width ?? 0)
            let height = Int(lastSnapshotPixelSize?.height ?? 0)
            statusText = "Saved \(width)×\(height) PNG. Opening in Preview."
            NSWorkspace.shared.open(destination)
        } catch is CancellationError {
            statusText = "Snapshot cancelled."
        } catch {
            failCapture(error, status: "Could not save snapshot.")
        }
    }

    private func captureVideo() async {
        guard let webView else {
            failCapture(PageSnapshotError.noWebView, status: "Could not record video.")
            return
        }

        let bounds = webView.bounds
        guard bounds.width > 1, bounds.height > 1 else {
            failCapture(PageSnapshotError.emptyView, status: "Could not record video.")
            return
        }

        isRecording = true
        errorMessage = nil
        statusText = "Recording…"
        defer {
            isRecording = false
            recordingTask = nil
        }

        if hideCookieBanners {
            await CookieBannerHider.hide(in: webView)
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("stageframe-\(UUID().uuidString).mp4")
        var writer: MP4FrameWriter?
        var frameCount = 0

        do {
            let encoder = try MP4FrameWriter(
                url: tempURL,
                width: ExportSizePreset.evenPixel(recordWidth),
                height: ExportSizePreset.evenPixel(recordHeight),
                realtime: false
            )
            writer = encoder

            await PageScroller.scroll(to: 0, in: webView)
            try await Task.sleep(for: .milliseconds(160))

            var metrics = try await PageScroller.metrics(in: webView)
            let fps = CaptureVideoFormat.fps
            let frameDuration = 1.0 / fps
            let start = CACurrentMediaTime()
            var lastTime = CMTime.negativeInfinity
            var frameIndex = 0
            var recordedDuration = 0.0

            while !Task.isCancelled {
                if frameIndex % 8 == 0, let latest = try? await PageScroller.metrics(in: webView) {
                    metrics = latest
                }

                let targetElapsed = Double(frameIndex) * frameDuration
                let total = ScrollTiming.totalDuration(maxScroll: metrics.maxScroll)
                if targetElapsed >= total {
                    recordedDuration = total
                    break
                }

                let wait = targetElapsed - (CACurrentMediaTime() - start)
                if wait > 0.002 {
                    try await Task.sleep(for: .seconds(wait))
                }

                let y = ScrollTiming.offset(elapsed: targetElapsed, maxScroll: metrics.maxScroll)
                await PageScroller.scroll(to: y, in: webView)
                try await Task.sleep(for: .milliseconds(8))

                let image = try await snapshotImage(from: webView, afterScreenUpdates: false)
                let buffer = try pixelBuffer(from: image)
                var time = CMTime(seconds: targetElapsed, preferredTimescale: CaptureVideoFormat.timescale)
                if time <= lastTime {
                    time = CMTimeAdd(lastTime, CMTime(value: 1, timescale: CaptureVideoFormat.timescale))
                }
                try await encoder.append(buffer, at: time)
                lastTime = time
                frameIndex += 1
                frameCount += 1
                recordedDuration = targetElapsed
                let progress = ScrollTiming.pageProgress(elapsed: targetElapsed, maxScroll: metrics.maxScroll)
                statusText = String(
                    format: "Recording %.0fs · %.0f%% of page",
                    targetElapsed,
                    progress * 100
                )
            }

            let stoppedEarly = Task.isCancelled || userStoppedRecording
            if frameCount == 0 {
                encoder.cancelAndDelete()
                statusText = stoppedEarly ? "Recording stopped." : VideoCaptureError.noFrames.localizedDescription
                return
            }

            if !stoppedEarly {
                let endTime = CMTime(seconds: recordedDuration, preferredTimescale: CaptureVideoFormat.timescale)
                if endTime > lastTime {
                    let image = try await snapshotImage(from: webView, afterScreenUpdates: false)
                    try await encoder.append(try pixelBuffer(from: image), at: endTime)
                }
            }

            try await encoder.finish()
            writer = nil
            await PageScroller.scroll(to: 0, in: webView)

            let host = webView.url?.host ?? loadedURL?.host
            try await keepRecording(
                from: tempURL,
                host: host,
                status: stoppedEarly
                    ? "Recorded a shorter clip."
                    : String(format: "Recorded %.0fs. Opening the editor.", recordedDuration)
            )
        } catch is CancellationError {
            if writer == nil {
                try? FileManager.default.removeItem(at: tempURL)
                statusText = "Recording stopped."
            } else if frameCount > 0, let encoder = writer {
                do {
                    try await encoder.finish()
                    writer = nil
                    let host = webView.url?.host ?? loadedURL?.host
                    try await keepRecording(
                        from: tempURL,
                        host: host,
                        status: "Recorded a shorter clip."
                    )
                } catch {
                    encoder.cancelAndDelete()
                    statusText = "Recording stopped."
                }
            } else {
                writer?.cancelAndDelete()
                statusText = "Recording stopped."
            }
        } catch {
            writer?.cancelAndDelete()
            try? FileManager.default.removeItem(at: tempURL)
            failCapture(error, status: "Could not record video.")
        }
    }

    private func keepRecording(from tempURL: URL, host: String?, status: String) async throws {
        let destination = try CaptureLibrary.keep(tempURL, host: host)
        lastVideoURL = destination
        statusText = status
    }

    func currentPageImage() async throws -> NSImage {
        if let webView {
            let bounds = webView.bounds
            if bounds.width > 1, bounds.height > 1 {
                let image = try await snapshotImage(from: webView, afterScreenUpdates: true)
                lastPageImage = image
                return image
            }
        }
        if let lastPageImage {
            return lastPageImage
        }
        throw webView == nil ? PageSnapshotError.noWebView : PageSnapshotError.emptyView
    }

    private func snapshotImage(from webView: WKWebView, afterScreenUpdates: Bool) async throws -> NSImage {
        let configuration = WKSnapshotConfiguration()
        configuration.rect = webView.bounds
        configuration.snapshotWidth = NSNumber(value: Double(ExportSizePreset.evenPixel(recordWidth)))
        configuration.afterScreenUpdates = afterScreenUpdates
        return try await webView.takeSnapshot(configuration: configuration)
    }

    private func pixelBuffer(from image: NSImage) throws -> CVPixelBuffer {
        var proposedRect = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
            throw PageSnapshotError.encodeFailed
        }
        let buffer = try PixelBufferFactory.make(
            width: ExportSizePreset.evenPixel(recordWidth),
            height: ExportSizePreset.evenPixel(recordHeight)
        )
        PixelBufferFactory.draw(cgImage, into: buffer)
        return buffer
    }

    private func chooseSaveURL(
        host: String?,
        contentType: UTType,
        filename: String,
        title: String
    ) async throws -> URL {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [contentType]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = title
        panel.nameFieldStringValue = filename

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            throw CancellationError()
        }
        return url
    }

    private func failCapture(_ error: Error, status: String) {
        errorMessage = error.localizedDescription
        statusText = status
    }
}
