import AppKit
import AVFoundation
import CoreMedia
import ImageIO
import Observation
import SwiftUI
import UniformTypeIdentifiers

enum MockupCanvas {
    static let width: CGFloat = 1200
    static let height: CGFloat = 900
    static let scale: CGFloat = 2
}

enum MockupError: LocalizedError {
    case noSource
    case noVideo
    case renderFailed
    case imageImport

    var errorDescription: String? {
        switch self {
        case .noSource:
            return "Load a website or a video frame first."
        case .noVideo:
            return "Record or open a clip first to export a mockup video."
        case .renderFailed:
            return "Could not render the mockup."
        case .imageImport:
            return "Could not import that image."
        }
    }
}

@MainActor
@Observable
final class MockupStudio {
    var addressText = "yoursite.com"
    var inset: Double = 48 {
        didSet { StageframeMemory.inset = inset }
    }
    var deviceOffsetX: Double = 0 {
        didSet { StageframeMemory.deviceOffsetX = deviceOffsetX }
    }
    var deviceOffsetY: Double = 0 {
        didSet { StageframeMemory.deviceOffsetY = deviceOffsetY }
    }
    var contentOffsetX: Double = 0
    var contentOffsetY: Double = 0
    var contentScale: Double = 1
    var overlayX: Double = 0.18 {
        didSet { StageframeMemory.overlayX = overlayX }
    }
    var overlayY: Double = 0.16 {
        didSet { StageframeMemory.overlayY = overlayY }
    }
    var overlayWidth: Double = 0.64 {
        didSet { StageframeMemory.overlayWidth = overlayWidth }
    }
    var overlayHeight: Double = 0.58 {
        didSet { StageframeMemory.overlayHeight = overlayHeight }
    }
    var overlayCorner: Double {
        get { overlayCornerTL }
        set { setAllCornerRadii(newValue) }
    }
    var overlayCornerTL: Double = 18 {
        didSet { StageframeMemory.overlayCornerTL = overlayCornerTL }
    }
    var overlayCornerTR: Double = 18 {
        didSet { StageframeMemory.overlayCornerTR = overlayCornerTR }
    }
    var overlayCornerBR: Double = 18 {
        didSet { StageframeMemory.overlayCornerBR = overlayCornerBR }
    }
    var overlayCornerBL: Double = 18 {
        didSet { StageframeMemory.overlayCornerBL = overlayCornerBL }
    }
    var videoBehindMockup = true {
        didSet { StageframeMemory.videoBehindMockup = videoBehindMockup }
    }

    var backgroundKind = BackgroundKind.preset
    var presetLookID = "dark"
    var backgroundCornerRadius: Double = 0
    var solidColor = RGBAColor.black
    var gradientCollection = GradientCollection.colorful
    var gradientLookID = "dusk"
    var gradientStyle = GradientStyleKind.linear
    var gradientScale: Double = 1
    var gradientAngle: Double = 135
    var gradientVignette = false
    var gradientStops: [GradientStopItem] = [
        GradientStopItem(color: RGBAColor(r: 0.08, g: 0.16, b: 0.26), location: 0),
        GradientStopItem(color: RGBAColor(r: 0.72, g: 0.48, b: 0.36), location: 1),
    ]
    var imageFit = ImageFitMode.cover
    var imageScale: Double = 1
    var imageBlur: Double = 40
    var imageOpacity: Double = 1
    var imageOffsetX: Double = 0
    var imageOffsetY: Double = 0
    var imageTile = TilePattern.none
    var selectedBackgroundImageID: UUID?
    var selectedBundledBackgroundID: String?
    var solidLookID = "s-black"
    var userBackgroundImages: [UserBackgroundImage] = []

    var frameSize: Double = 1
    var frameX: Double = 0
    var frameY: Double = 0
    var footageFit = FootageFitMode.fill {
        didSet { StageframeMemory.footageFit = footageFit }
    }
    var footageMatte = RGBAColor.white
    var footagePixelSize = CGSize(width: CaptureVideoFormat.defaultWidth, height: CaptureVideoFormat.defaultHeight)
    var borderEnabled = false
    var borderColor = RGBAColor.white
    var borderWidth: Double = 2
    var shadowEnabled = false
    var shadowIntensity: Double = 0.45
    var shadowCornerRadius: Double = 18
    var shadowRotation: Double = 0
    var shadowCenterX: Double = 0
    var shadowCenterY: Double = 0.04
    var showFootagePosition = false
    var selectedCorner: ScreenCorner?
    var defaultScreenHole = MockupTemplate.fallback.hole
    var screenHole = MockupTemplate.fallback.hole
    var mockupImage: NSImage?
    var backgroundImage: NSImage?
    var selectedTemplate: MockupTemplate = .fallback
    var catalogFilter: MockupCatalogFilter = .all
    var inspectorTab = MockupInspectorTab.mockup
    var pendingImport: MockupImportKind?
    var exportPreset = ExportSizePreset.framer {
        didSet {
            StageframeMemory.exportPresetID = exportPreset.id
        }
    }
    var customWidth = 1200 {
        didSet {
            StageframeMemory.customWidth = customWidth
        }
    }
    var customHeight = 900 {
        didSet {
            StageframeMemory.customHeight = customHeight
        }
    }
    var exportQuality = StageframeMemory.exportQuality {
        didSet { StageframeMemory.exportQuality = exportQuality }
    }
    var exportFrameRate = StageframeMemory.exportFPS {
        didSet { StageframeMemory.exportFPS = exportFrameRate }
    }
    var exportFormat = StageframeMemory.exportFormat {
        didSet { StageframeMemory.exportFormat = exportFormat }
    }
    var exportScale = StageframeMemory.exportScale {
        didSet { StageframeMemory.exportScale = exportScale }
    }
    var jpegQuality = StageframeMemory.jpegQuality {
        didSet { StageframeMemory.jpegQuality = jpegQuality }
    }
    var isMuted = StageframeMemory.isMuted {
        didSet {
            StageframeMemory.isMuted = isMuted
            applyAudio()
        }
    }
    var volume = StageframeMemory.volume {
        didSet {
            StageframeMemory.volume = volume
            applyAudio()
        }
    }
    var hasAudio = false
    var waveform: [Float] = []
    var screenImage: NSImage?
    var movieURL: URL?
    var trimStart = 0.0
    var trimEnd = 0.0
    var sourceDuration = 0.0
    var isPlaying = false
    var isRefreshing = false
    var isExporting = false
    var showExportSettings = false
    var exportProgress = 0.0
    var exportProgressText = ""
    var playhead = 0.0
    var statusText = "Add a mockup, then place your clip in the screen."
    var errorMessage: String?

    let player = AVPlayer()

    private var endBoundaryObserver: Any?
    private var timeObserver: Any?
    private var endNotification: NSObjectProtocol?
    private var exportTask: Task<Void, Never>?
    private var mockupPath: String?
    private var backgroundPath: String?

    init(previewOnly: Bool = false) {
        if previewOnly {
            return
        }
        if let id = StageframeMemory.exportPresetID,
           let stored = ExportSizePreset.all.first(where: { $0.id == id }) {
            exportPreset = stored
        }
        customWidth = StageframeMemory.customWidth
        customHeight = StageframeMemory.customHeight
        inset = StageframeMemory.inset
        overlayX = StageframeMemory.overlayX
        overlayY = StageframeMemory.overlayY
        overlayWidth = StageframeMemory.overlayWidth
        overlayHeight = StageframeMemory.overlayHeight
        overlayCornerTL = StageframeMemory.overlayCornerTL
        overlayCornerTR = StageframeMemory.overlayCornerTR
        overlayCornerBR = StageframeMemory.overlayCornerBR
        overlayCornerBL = StageframeMemory.overlayCornerBL
        footageFit = StageframeMemory.footageFit
        videoBehindMockup = StageframeMemory.videoBehindMockup
        if StageframeMemory.hasPlacement {
            deviceOffsetX = StageframeMemory.deviceOffsetX
            deviceOffsetY = StageframeMemory.deviceOffsetY
        }
        loadStoredImage(path: StageframeMemory.mockupPath, isMockup: true)
        loadStoredImage(path: StageframeMemory.backgroundPath, isMockup: false)
        if mockupImage == nil {
            if let id = StageframeMemory.templateID,
               let stored = MockupTemplate.catalog.first(where: { $0.id == id }) {
                select(stored, rememberLayout: false)
            } else {
                select(.fallback, rememberLayout: false)
            }
        } else if let image = mockupImage {
            defaultScreenHole = ScreenHoleDetector.detect(in: image)
                ?? .rect(CGRect(x: 0.2, y: 0.18, width: 0.6, height: 0.48))
        }
        restorePersistedHoleIfNeeded()
        if isBlankMockup {
            applyBlankFrameToFootage()
        }
        applyAudio()
    }

    var hasSource: Bool { screenImage != nil || hasVideo }
    var hasVideo: Bool { movieURL != nil && trimEnd > trimStart }
    var isCustomMockup: Bool { mockupImage != nil }
    var isBlankMockup: Bool { !isCustomMockup && selectedTemplate.isBlank }
    var hasMockup: Bool { displayMockupImage != nil }

    var displayMockupImage: NSImage? {
        mockupImage ?? selectedTemplate.image
    }

    var activeScreenHole: MockupScreenHole { screenHole }

    func isSelected(_ template: MockupTemplate) -> Bool {
        !isCustomMockup && selectedTemplate.id == template.id
    }
    var hasCustomBackground: Bool { backgroundImage != nil }
    var isBusy: Bool { isRefreshing || isExporting }
    var canExportVideo: Bool { hasVideo && !isBusy }
    var canExportStill: Bool { hasSource && !isBusy }

    var exportBaseWidth: Int {
        ExportSizePreset.evenPixel(exportPreset.isCustom ? customWidth : exportPreset.width)
    }

    var exportBaseHeight: Int {
        ExportSizePreset.evenPixel(exportPreset.isCustom ? customHeight : exportPreset.height)
    }

    var exportWidth: Int {
        ExportSizePreset.evenPixel(exportBaseWidth * exportScale.rawValue)
    }

    var exportHeight: Int {
        ExportSizePreset.evenPixel(exportBaseHeight * exportScale.rawValue)
    }

    var exportPixelSize: CGSize {
        CGSize(width: exportBaseWidth, height: exportBaseHeight)
    }

    var exportSizeLabel: String {
        "\(exportWidth)×\(exportHeight)"
    }

    var exportBaseSizeLabel: String {
        "\(exportBaseWidth) × \(exportBaseHeight)"
    }

    var exportDuration: Double {
        max(trimEnd - trimStart, 0)
    }

    var estimatedExportBytes: Int64 {
        ExportFileSizeEstimate.bytes(
            width: exportWidth,
            height: exportHeight,
            fps: exportFrameRate.rawValue,
            duration: max(exportDuration, 0.2),
            quality: exportQuality,
            format: exportFormat,
            includesAudio: hasAudio && !isMuted && effectiveVolume > 0.001
        )
    }

    var estimatedExportSizeLabel: String {
        guard hasVideo else { return "Open a clip to estimate size" }
        return "~\(ExportFileSizeEstimate.format(estimatedExportBytes))"
    }

    var effectiveVolume: Float {
        isMuted ? 0 : Float(min(max(volume, 0), 1.5))
    }

    func select(_ template: MockupTemplate, rememberLayout: Bool = true) {
        selectedTemplate = template
        StageframeMemory.templateID = template.id
        mockupImage = nil
        mockupPath = nil
        StageframeMemory.mockupPath = nil
        videoBehindMockup = false
        if rememberLayout {
            overlayCorner = template.screenCorner
        }
        if template.isBlank {
            let hole = footageFittedHole()
            defaultScreenHole = hole
            applyHole(hole)
        } else {
            defaultScreenHole = template.hole
            applyHole(template.hole)
            frameSize = 1
            frameX = 0
            frameY = 0
        }
        if rememberLayout {
            inset = 0
            deviceOffsetX = 0
            deviceOffsetY = 0
            contentOffsetX = 0
            contentOffsetY = 0
            contentScale = 1
            frameSize = 1
            frameX = 0
            frameY = 0
        }
        statusText = template.isBlank
            ? "Blank mockup. Your clip sits on the background."
            : "Video plays in the black screen of \(template.name)."
        errorMessage = nil
    }

    func setAllCornerRadii(_ value: Double) {
        let clamped = min(max(value, 0), 64)
        overlayCornerTL = clamped
        overlayCornerTR = clamped
        overlayCornerBR = clamped
        overlayCornerBL = clamped
        StageframeMemory.overlayCorner = clamped
    }

    func cornerRadius(_ corner: ScreenCorner) -> Double {
        switch corner {
        case .topLeft: overlayCornerTL
        case .topRight: overlayCornerTR
        case .bottomRight: overlayCornerBR
        case .bottomLeft: overlayCornerBL
        }
    }

    func cornerRadiusBinding(_ corner: ScreenCorner) -> Binding<Double> {
        Binding(
            get: { self.cornerRadius(corner) },
            set: { value in
                switch corner {
                case .topLeft: self.overlayCornerTL = value
                case .topRight: self.overlayCornerTR = value
                case .bottomRight: self.overlayCornerBR = value
                case .bottomLeft: self.overlayCornerBL = value
                }
            }
        )
    }

    func applyHole(_ hole: MockupScreenHole) {
        screenHole = hole.ensuringFourPoints()
        let box = screenHole.boundingRect
        overlayX = box.minX
        overlayY = box.minY
        overlayWidth = box.width
        overlayHeight = box.height
        persistHole()
    }

    func rebuildHoleFromOverlay() {
        applyHole(.rect(
            CGRect(x: overlayX, y: overlayY, width: overlayWidth, height: overlayHeight)
        ))
    }

    func imageRect(in canvas: CGSize) -> CGRect {
        guard let image = displayMockupImage else {
            return CGRect(origin: .zero, size: canvas)
        }
        let box = activeScreenHole.boundingRect
        return MockupLayout.aspectFill(
            PNGSnapshot.pixelSize(of: image),
            in: canvas,
            anchor: CGPoint(x: box.midX, y: box.midY)
        )
    }

    var displayHole: MockupScreenHole {
        activeScreenHole.framed(size: frameSize, offsetX: frameX, offsetY: frameY)
    }

    var footageAspect: CGFloat {
        footagePixelSize.width / max(footagePixelSize.height, 1)
    }

    var screenFrameAspect: CGFloat {
        let imageSize = displayMockupImage.map(PNGSnapshot.pixelSize(of:)) ?? exportPixelSize
        return displayHole.visualAspect(in: imageSize)
    }

    func rememberFootageSize(_ size: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        footagePixelSize = size
        if isBlankMockup {
            applyBlankFrameToFootage()
        }
    }

    func footageFittedHole(padding: CGFloat = 0.08) -> MockupScreenHole {
        let canvas = exportPixelSize
        let box = CGSize(
            width: max(canvas.width * (1 - padding * 2), 1),
            height: max(canvas.height * (1 - padding * 2), 1)
        )
        let fitted = MockupLayout.aspectFit(footagePixelSize, in: box)
        let width = fitted.width / max(canvas.width, 1)
        let height = fitted.height / max(canvas.height, 1)
        return .rect(
            CGRect(
                x: (1 - width) / 2,
                y: (1 - height) / 2,
                width: width,
                height: height
            )
        )
    }

    func applyBlankFrameToFootage() {
        let hole = footageFittedHole()
        defaultScreenHole = hole
        applyHole(hole)
        frameSize = 1
        frameX = 0
        frameY = 0
    }

    func mappedCorners(in canvas: CGSize) -> [CGPoint] {
        displayHole.mapped(in: imageRect(in: canvas))
    }

    func point(for corner: ScreenCorner) -> CGPoint {
        screenHole.ensuringFourPoints().point(corner)
    }

    func setCorner(_ corner: ScreenCorner, x: Double, y: Double) {
        var hole = screenHole.ensuringFourPoints()
        hole.setPoint(corner, to: CGPoint(x: min(max(x, 0), 1), y: min(max(y, 0), 1)))
        applyHole(hole)
    }

    func moveMappedCorner(_ corner: ScreenCorner, to canvasPoint: CGPoint, in canvas: CGSize) {
        let image = imageRect(in: canvas)
        let framed = CGPoint(
            x: (canvasPoint.x - image.minX) / max(image.width, 1),
            y: (canvasPoint.y - image.minY) / max(image.height, 1)
        )
        let box = screenHole.boundingRect
        let scale = max(frameSize, 0.001)
        let raw = CGPoint(
            x: box.midX + (framed.x - box.midX - frameX) / scale,
            y: box.midY + (framed.y - box.midY - frameY) / scale
        )
        setCorner(corner, x: raw.x, y: raw.y)
    }

    func resetScreenCorners() {
        frameSize = 1
        frameX = 0
        frameY = 0
        if isBlankMockup {
            applyBlankFrameToFootage()
            statusText = "Frame sized to \(Int(footagePixelSize.width))×\(Int(footagePixelSize.height))."
        } else {
            applyHole(defaultScreenHole)
            statusText = "Video frame snapped to the mockup screen."
        }
        selectedCorner = nil
    }

    func cornerX(_ corner: ScreenCorner) -> Binding<Double> {
        Binding(
            get: { self.point(for: corner).x },
            set: { self.setCorner(corner, x: $0, y: self.point(for: corner).y) }
        )
    }

    func cornerY(_ corner: ScreenCorner) -> Binding<Double> {
        Binding(
            get: { self.point(for: corner).y },
            set: { self.setCorner(corner, x: self.point(for: corner).x, y: $0) }
        )
    }

    private func persistHole() {
        let points = screenHole.ensuringFourPoints().points
        StageframeMemory.holePoints = points.flatMap { [$0.x, $0.y] }
        StageframeMemory.holeTemplateID = isCustomMockup ? "custom" : selectedTemplate.id
    }

    func restorePersistedHoleIfNeeded() {
        guard isCustomMockup else { return }
        let expected = "custom"
        guard StageframeMemory.holeTemplateID == expected,
              let values = StageframeMemory.holePoints,
              values.count == 8
        else { return }
        applyHole(MockupScreenHole(points: [
            CGPoint(x: values[0], y: values[1]),
            CGPoint(x: values[2], y: values[3]),
            CGPoint(x: values[4], y: values[5]),
            CGPoint(x: values[6], y: values[7]),
        ]))
    }

    func applySolidLook(_ look: BackgroundLook) {
        backgroundKind = .solid
        solidLookID = look.id
        solidColor = look.isBlank ? .clear : (look.colors.first ?? .black)
    }

    func selectBundledBackground(_ item: BundledBackgroundImage) {
        backgroundKind = .image
        selectedBundledBackgroundID = item.id
        selectedBackgroundImageID = nil
        backgroundImage = item.image
        backgroundPath = nil
        StageframeMemory.backgroundPath = nil
    }

    func applyPresetLook(_ look: BackgroundLook) {
        backgroundKind = .preset
        presetLookID = look.id
        if look.isBlank {
            backgroundImage = nil
            backgroundPath = nil
            StageframeMemory.backgroundPath = nil
        }
    }

    func applyGradientLook(_ look: BackgroundLook) {
        backgroundKind = .gradient
        gradientLookID = look.id
        if look.isBlank {
            gradientStops = [
                GradientStopItem(color: RGBAColor.clear, location: 0),
                GradientStopItem(color: RGBAColor.clear, location: 1),
            ]
            return
        }
        if look.colors.count == 1 {
            gradientStops = [
                GradientStopItem(color: look.colors[0], location: 0),
                GradientStopItem(color: look.colors[0], location: 1),
            ]
        } else {
            let last = Double(max(look.colors.count - 1, 1))
            gradientStops = look.colors.enumerated().map { index, color in
                GradientStopItem(color: color, location: Double(index) / last)
            }
        }
    }

    func selectBackgroundImage(_ item: UserBackgroundImage?) {
        backgroundKind = .image
        selectedBundledBackgroundID = nil
        selectedBackgroundImageID = item?.id
        if let item {
            backgroundImage = item.image
            backgroundPath = item.path
            StageframeMemory.backgroundPath = item.path
        } else {
            backgroundImage = nil
            backgroundPath = nil
            StageframeMemory.backgroundPath = nil
        }
    }

    func addGradientStop(at location: Double? = nil) {
        guard gradientStops.count < 8 else { return }
        let next = location ?? min((gradientStops.map(\.location).max() ?? 0.5) + 0.15, 1)
        let clamped = min(max(next, 0), 1)
        gradientStops.append(
            GradientStopItem(color: interpolatedGradientColor(at: clamped) ?? .white, location: clamped)
        )
    }

    func removeGradientStop(_ stop: GradientStopItem) {
        guard gradientStops.count > 2 else { return }
        gradientStops.removeAll { $0.id == stop.id }
    }

    func reverseGradient() {
        for index in gradientStops.indices {
            gradientStops[index].location = 1 - gradientStops[index].location
        }
    }

    func resetGradientSettings() {
        gradientStyle = .linear
        gradientScale = 1
        gradientAngle = 90
        gradientVignette = false
        backgroundCornerRadius = 0
        gradientLookID = "custom"
        gradientStops = [
            GradientStopItem(color: RGBAColor(hex: "#1A1A2E") ?? .black, location: 0),
            GradientStopItem(color: RGBAColor(hex: "#0F0F0F") ?? .black, location: 1),
        ]
    }

    func interpolatedGradientColor(at location: Double) -> RGBAColor? {
        let stops = gradientStops.sorted { $0.location < $1.location }
        guard let first = stops.first, let last = stops.last else { return nil }
        if location <= first.location { return first.color }
        if location >= last.location { return last.color }
        for (leading, trailing) in zip(stops, stops.dropFirst()) {
            guard location >= leading.location && location <= trailing.location else { continue }
            let span = max(trailing.location - leading.location, 0.0001)
            let t = (location - leading.location) / span
            return RGBAColor(
                r: leading.color.r + (trailing.color.r - leading.color.r) * t,
                g: leading.color.g + (trailing.color.g - leading.color.g) * t,
                b: leading.color.b + (trailing.color.b - leading.color.b) * t,
                a: leading.color.a + (trailing.color.a - leading.color.a) * t
            )
        }
        return last.color
    }

    func resetFootagePosition() {
        contentOffsetX = 0
        contentOffsetY = 0
        contentScale = 1
        footageMatte = .white
    }

    func resetSettings() {
        if mockupImage != nil {
            inset = 48
            overlayX = 0.18
            overlayY = 0.16
            overlayWidth = 0.64
            overlayHeight = 0.58
            overlayCorner = 18
        }
        select(selectedTemplate)
        statusText = "Layout reset to \(selectedTemplate.name)."
        errorMessage = nil
    }

    func chooseAndImportImage(kind: MockupImportKind) {
        pendingImport = nil
        let panel = NSOpenPanel()
        panel.title = kind == .mockup ? "Choose a mockup image" : "Choose a background image"
        panel.prompt = "Add Image"
        panel.allowedContentTypes = [.png, .jpeg, .webP, .heic, .bmp, .tiff, .gif]
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false

        let finish: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return }
            self.importImage(from: url, kind: kind)
        }

        if let window = NSApp.keyWindow ?? NSApp.windows.first(where: \.isVisible) {
            panel.beginSheetModal(for: window, completionHandler: finish)
        } else {
            finish(panel.runModal())
        }
    }

    func importImage(from url: URL, kind: MockupImportKind) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let copied = try CaptureLibrary.importImage(url, prefix: kind.rawValue)
            guard let image = NSImage(contentsOf: copied) else {
                throw MockupError.imageImport
            }
            switch kind {
            case .mockup:
                mockupImage = image
                mockupPath = copied.path
                StageframeMemory.mockupPath = copied.path
                StageframeMemory.templateID = "custom"
                videoBehindMockup = false
                if let hole = ScreenHoleDetector.detect(in: image) {
                    defaultScreenHole = hole
                    applyHole(hole)
                    statusText = "Custom mockup added. Drag the screen corners in the Frame tab to align."
                } else {
                    defaultScreenHole = .rect(CGRect(x: 0.2, y: 0.18, width: 0.6, height: 0.48))
                    applyHole(defaultScreenHole)
                    statusText = "Custom mockup added. Drag the screen corners in the Frame tab to align."
                }
                inspectorTab = .frame
            case .background:
                let item = UserBackgroundImage(
                    id: UUID(),
                    name: url.deletingPathExtension().lastPathComponent,
                    image: image,
                    path: copied.path
                )
                userBackgroundImages.append(item)
                selectBackgroundImage(item)
                inspectorTab = .background
                statusText = "Background image added. It sits behind the mockup."
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            statusText = "Could not import that image."
        }
    }

    func clearMockup() {
        mockupImage = nil
        mockupPath = nil
        StageframeMemory.mockupPath = nil
        select(.fallback)
    }

    func clearBackgroundImage() {
        backgroundImage = nil
        backgroundPath = nil
        StageframeMemory.backgroundPath = nil
        selectedBackgroundImageID = nil
        selectedBundledBackgroundID = nil
        statusText = "Using a color background. Add an image anytime from the Background tab."
    }

    func refresh(from session: CaptureSession, trimmer: TrimEditor) async {
        isRefreshing = true
        errorMessage = nil
        statusText = "Updating mockup source…"
        defer { isRefreshing = false }

        do {
            if trimmer.hasMovie {
                try await attachVideo(from: trimmer)
                statusText = hasMockup
                    ? "Clip in the \(selectedTemplate.name) screen."
                    : "Clip ready. Add a mockup image, or export on a background."
            } else {
                clearVideo()
                guard session.loadedURL != nil || session.lastPageImage != nil else {
                    throw MockupError.noSource
                }
                screenImage = try await session.currentPageImage()
                rememberFootageSize(screenImage?.size ?? CGSize(width: session.recordWidth, height: session.recordHeight))
                addressText = session.loadedURL?.host ?? session.urlText
                statusText = "Using the loaded website. Record to export a mockup video."
            }
        } catch {
            errorMessage = error.localizedDescription
            statusText = "Could not capture a mockup source."
        }
    }

    func togglePlay() {
        guard hasVideo else { return }
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard hasVideo else { return }
        let time = player.currentTime().seconds
        if time < trimStart || time >= trimEnd - 0.05 {
            seek(to: trimStart)
        }
        applyAudio()
        player.play()
        isPlaying = true
        refreshLoopObserver()
    }

    func seek(to seconds: Double) {
        let upper = max(sourceDuration, trimEnd)
        let clamped = min(max(seconds, 0), max(upper, 0))
        playhead = clamped
        let time = CMTime(seconds: clamped, preferredTimescale: CaptureVideoFormat.timescale)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func previewFrame(at seconds: Double) {
        guard hasVideo else { return }
        if isPlaying {
            pause()
        }
        seek(to: seconds)
    }

    func applyTrim(start: Double, end: Double) {
        trimStart = start
        trimEnd = end
        if playhead < start || playhead > end {
            seek(to: start)
        }
        refreshLoopObserver()
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func exportPNG() {
        exportTask?.cancel()
        exportTask = Task { await exportStill() }
    }

    func openExportDialog() {
        inspectorTab = .export
        showExportSettings = true
    }

    func beginVideoExport() {
        openExportDialog()
    }

    func resetExportSettings() {
        exportPreset = .framer
        customWidth = 1200
        customHeight = 900
        exportScale = .one
        jpegQuality = 0.92
        exportQuality = .high
        exportFrameRate = .fps30
        exportFormat = .mp4
    }

    func exportVideo() {
        showExportSettings = false
        exportTask?.cancel()
        exportTask = Task { await renderVideo() }
    }

    func cancelExport() {
        exportTask?.cancel()
    }

    func applyAudio() {
        player.isMuted = isMuted || !hasAudio
        player.volume = effectiveVolume
    }

    private func attachVideo(from trimmer: TrimEditor) async throws {
        guard let url = trimmer.assetURL else { throw MockupError.noVideo }
        screenImage = try await trimmer.currentFrameImage()
        if let size = screenImage?.size {
            rememberFootageSize(size)
        }
        if let track = try await AVURLAsset(url: url).loadTracks(withMediaType: .video).first {
            let natural = try await track.load(.naturalSize)
            let transform = try await track.load(.preferredTransform)
            let rendered = natural.applying(transform)
            rememberFootageSize(CGSize(width: abs(rendered.width), height: abs(rendered.height)))
        }
        addressText = url.deletingPathExtension().lastPathComponent
        movieURL = url
        trimStart = trimmer.trimStart
        trimEnd = trimmer.trimEnd
        sourceDuration = trimmer.duration
        playhead = trimmer.trimStart
        hasAudio = trimmer.hasAudio
        waveform = trimmer.waveform
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        player.actionAtItemEnd = .none
        applyAudio()
        addTimeObserver()
        seek(to: trimStart)
        refreshLoopObserver()
    }

    private func clearVideo() {
        pause()
        removeLoopObserver()
        removeTimeObserver()
        player.replaceCurrentItem(with: nil)
        movieURL = nil
        trimStart = 0
        trimEnd = 0
        sourceDuration = 0
        playhead = 0
        hasAudio = false
        waveform = []
    }

    private func loop() {
        guard isPlaying else { return }
        seek(to: trimStart)
        player.play()
    }

    private func refreshLoopObserver() {
        removeLoopObserver()
        guard hasVideo else { return }

        let end = CMTime(seconds: trimEnd, preferredTimescale: CaptureVideoFormat.timescale)
        endBoundaryObserver = player.addBoundaryTimeObserver(
            forTimes: [NSValue(time: end)],
            queue: .main
        ) { [weak self] in
            Task { @MainActor in
                self?.loop()
            }
        }

        endNotification = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loop()
            }
        }
    }

    private func removeLoopObserver() {
        if let endBoundaryObserver {
            player.removeTimeObserver(endBoundaryObserver)
            self.endBoundaryObserver = nil
        }
        if let endNotification {
            NotificationCenter.default.removeObserver(endNotification)
            self.endNotification = nil
        }
    }

    private func addTimeObserver() {
        removeTimeObserver()
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.04, preferredTimescale: CaptureVideoFormat.timescale),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.playhead = time.seconds
            }
        }
    }

    private func removeTimeObserver() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }

    private func exportStill() async {
        errorMessage = nil
        statusText = "Choose where to save the PNG…"
        pause()

        do {
            if hasVideo {
                screenImage = try await frameImage(at: player.currentTime().seconds)
            }
            guard screenImage != nil else {
                throw MockupError.noSource
            }
            let destination = try await chooseSaveURL(
                contentTypes: [.png, .jpeg],
                filename: exportFilename(extension: "png"),
                title: "Export mockup image"
            )
            isExporting = true
            exportProgress = 0.2
            exportProgressText = "Rendering PNG…"
            defer {
                isExporting = false
                exportProgress = 0
                exportProgressText = ""
            }
            try Task.checkCancellation()
            let image = try renderImage()
            exportProgress = 0.7
            let isJPEG = ["jpg", "jpeg"].contains(destination.pathExtension.lowercased())
            let data = isJPEG
                ? try PNGSnapshot.jpegData(from: image, quality: jpegQuality)
                : try PNGSnapshot.pngData(from: image)
            try data.write(to: destination, options: .atomic)
            exportProgress = 1
            let pixels = PNGSnapshot.pixelSize(of: image)
            let kind = isJPEG ? "JPEG" : "PNG"
            statusText = "Saved \(Int(pixels.width))×\(Int(pixels.height)) \(exportPreset.name) \(kind). Opening in Preview."
            NSWorkspace.shared.open(destination)
        } catch is CancellationError {
            statusText = "Mockup export cancelled."
        } catch {
            errorMessage = error.localizedDescription
            statusText = "Could not export mockup."
        }
    }

    private func renderVideo() async {
        guard let movieURL else {
            errorMessage = MockupError.noVideo.localizedDescription
            statusText = "Could not export mockup video."
            return
        }

        errorMessage = nil
        pause()

        let duration = max(trimEnd - trimStart, 0.2)
        let fps = exportFrameRate.rawValue
        let frames = max(Int((duration * fps).rounded(.toNearestOrAwayFromZero)), 1)
        let width = exportWidth
        let height = exportHeight
        let format = exportFormat

        do {
            let destination = try await chooseSaveURL(
                contentType: format.contentType,
                filename: exportFilename(extension: format.fileExtension),
                title: "Export mockup \(format.title)"
            )
            isExporting = true
            exportProgress = 0
            exportProgressText = "Starting export…"
            defer {
                isExporting = false
                exportProgress = 0
                exportProgressText = ""
            }

            if format == .gif {
                try await exportGIF(to: destination, frames: frames, fps: fps)
            } else {
                try await exportMovie(
                    to: destination,
                    source: movieURL,
                    frames: frames,
                    fps: fps,
                    duration: duration,
                    width: width,
                    height: height,
                    fileType: format.avFileType ?? .mp4
                )
            }

            exportProgress = 1
            statusText = String(
                format: "Saved %.1fs \(exportPreset.name) \(format.title) (%dx%d). Opening…",
                duration,
                width,
                height
            )
            NSWorkspace.shared.open(destination)
        } catch is CancellationError {
            statusText = "Mockup video export cancelled."
        } catch {
            errorMessage = error.localizedDescription
            statusText = "Could not export mockup video."
        }
    }

    private func exportMovie(
        to destination: URL,
        source: URL,
        frames: Int,
        fps: Double,
        duration: Double,
        width: Int,
        height: Int,
        fileType: AVFileType
    ) async throws {
        let videoURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("stageframe-export-\(UUID().uuidString).\(fileType == .mov ? "mov" : "mp4")")
        let writer = try MP4FrameWriter(
            url: videoURL,
            width: width,
            height: height,
            realtime: false,
            bitRate: exportQuality.bitRate(width: width, height: height, fps: fps),
            fps: fps,
            fileType: fileType
        )
        do {
            try await writeFrames(from: source, frames: frames, fps: fps, into: .movie(writer), width: width, height: height)
            exportProgressText = "Finishing file…"
            exportProgress = 0.92
            try await writer.finish()
        } catch {
            writer.cancelAndDelete()
            throw error
        }

        let shouldMixAudio = formatIncludesAudio && hasAudio && !isMuted && effectiveVolume > 0.001
        if shouldMixAudio {
            exportProgressText = "Mixing audio…"
            exportProgress = 0.96
            do {
                try await ExportAudioMixer.mix(
                    videoURL: videoURL,
                    sourceMovieURL: source,
                    start: trimStart,
                    duration: duration,
                    volume: effectiveVolume,
                    outputURL: destination,
                    fileType: fileType
                )
                try? FileManager.default.removeItem(at: videoURL)
            } catch {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try? FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: videoURL, to: destination)
            }
        } else {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: videoURL, to: destination)
        }
    }

    private var formatIncludesAudio: Bool {
        exportFormat.includesAudio
    }

    private func exportGIF(to destination: URL, frames: Int, fps: Double) async throws {
        guard let movieURL else { throw MockupError.noVideo }
        let gif = try GIFExporter.start(url: destination, frameCount: frames, delay: 1.0 / fps)
        try await writeFrames(
            from: movieURL,
            frames: frames,
            fps: fps,
            into: .gif(gif, delay: 1.0 / fps),
            width: exportWidth,
            height: exportHeight
        )
        exportProgressText = "Finishing GIF…"
        exportProgress = 0.98
        try GIFExporter.finish(gif)
    }

    private enum FrameSink {
        case movie(MP4FrameWriter)
        case gif(CGImageDestination, delay: Double)
    }

    private func writeFrames(
        from movieURL: URL,
        frames: Int,
        fps: Double,
        into sink: FrameSink,
        width: Int,
        height: Int
    ) async throws {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: movieURL))
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        for index in 0..<frames {
            try Task.checkCancellation()
            exportProgress = Double(index) / Double(max(frames, 1)) * 0.9
            exportProgressText = "Rendering \(index + 1) of \(frames)"
            statusText = exportProgressText
            if index % 2 == 0 {
                await Task.yield()
            }

            let sourceSeconds = min(trimStart + Double(index) / fps, max(trimEnd - 0.001, trimStart))
            let sourceTime = CMTime(seconds: sourceSeconds, preferredTimescale: CaptureVideoFormat.timescale)
            let frame = try await generator.image(at: sourceTime)
            screenImage = NSImage(
                cgImage: frame.image,
                size: NSSize(width: frame.image.width, height: frame.image.height)
            )
            let rendered = try renderImage()
            var proposed = NSRect(origin: .zero, size: rendered.size)
            guard let cgImage = rendered.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else {
                throw MockupError.renderFailed
            }

            switch sink {
            case .movie(let writer):
                let buffer = try PixelBufferFactory.make(width: width, height: height)
                PixelBufferFactory.draw(cgImage, into: buffer)
                let presentation = CMTime(
                    seconds: Double(index) / fps,
                    preferredTimescale: CaptureVideoFormat.timescale
                )
                try await writer.append(buffer, at: presentation)
            case .gif(let destination, let delay):
                GIFExporter.append(cgImage, to: destination, delay: delay)
            }
        }
    }

    private func frameImage(at seconds: Double) async throws -> NSImage {
        guard let movieURL else { throw MockupError.noVideo }
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: movieURL))
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let time = CMTime(seconds: max(seconds, trimStart), preferredTimescale: CaptureVideoFormat.timescale)
        let result = try await generator.image(at: time)
        return NSImage(
            cgImage: result.image,
            size: NSSize(width: result.image.width, height: result.image.height)
        )
    }

    private func renderImage() throws -> NSImage {
        let canvas = CGSize(width: exportWidth, height: exportHeight)
        let renderer = ImageRenderer(
            content: MockupLetterboxView(studio: self, canvas: canvas)
                .frame(width: canvas.width, height: canvas.height)
        )
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: canvas.width, height: canvas.height)
        guard let image = renderer.nsImage else {
            throw MockupError.renderFailed
        }
        return image
    }

    private func exportFilename(extension fileExtension: String) -> String {
        let slug = PNGSnapshot.defaultFilename(host: addressText)
            .replacingOccurrences(of: "-snapshot.png", with: "")
        return "\(slug)-mockup-\(exportPreset.id)-\(exportWidth)x\(exportHeight).\(fileExtension)"
    }

    private func chooseSaveURL(contentType: UTType, filename: String, title: String) async throws -> URL {
        try await chooseSaveURL(contentTypes: [contentType], filename: filename, title: title)
    }

    private func chooseSaveURL(contentTypes: [UTType], filename: String, title: String) async throws -> URL {
        let panel = NSSavePanel()
        panel.allowedContentTypes = contentTypes
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

    private func loadStoredImage(path: String?, isMockup: Bool) {
        guard let path, FileManager.default.fileExists(atPath: path) else { return }
        guard let image = NSImage(contentsOf: URL(fileURLWithPath: path)) else { return }
        if isMockup {
            mockupImage = image
            mockupPath = path
        } else {
            backgroundImage = image
            backgroundPath = path
            let item = UserBackgroundImage(
                id: UUID(),
                name: URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent,
                image: image,
                path: path
            )
            userBackgroundImages.append(item)
            selectedBackgroundImageID = item.id
            backgroundKind = .image
        }
    }
}
