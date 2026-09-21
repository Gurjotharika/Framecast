import Foundation

enum StageframeMemory {
    private static let defaults = UserDefaults.standard

    private enum Key {
        static let urlText = "stageframe.urlText"
        static let hideCookieBanners = "stageframe.hideCookieBanners"
        static let durationSeconds = "stageframe.durationSeconds"
        static let exportPresetID = "stageframe.exportPresetID"
        static let customWidth = "stageframe.customWidth"
        static let customHeight = "stageframe.customHeight"
        static let recordWidth = "stageframe.recordWidth"
        static let recordHeight = "stageframe.recordHeight"
        static let inset = "stageframe.inset"
        static let deviceOffsetX = "stageframe.deviceOffsetX"
        static let deviceOffsetY = "stageframe.deviceOffsetY"
        static let overlayX = "stageframe.overlayX"
        static let overlayY = "stageframe.overlayY"
        static let overlayWidth = "stageframe.overlayWidth"
        static let overlayHeight = "stageframe.overlayHeight"
        static let overlayCorner = "stageframe.overlayCorner"
        static let overlayCornerTL = "stageframe.overlayCornerTL"
        static let overlayCornerTR = "stageframe.overlayCornerTR"
        static let overlayCornerBR = "stageframe.overlayCornerBR"
        static let overlayCornerBL = "stageframe.overlayCornerBL"
        static let footageFit = "stageframe.footageFit"
        static let videoBehindMockup = "stageframe.videoBehindMockup"
        static let mockupPath = "stageframe.mockupPath"
        static let backgroundPath = "stageframe.backgroundPath"
        static let volume = "stageframe.volume"
        static let isMuted = "stageframe.isMuted"
        static let exportQuality = "stageframe.exportQuality"
        static let exportFPS = "stageframe.exportFPS"
        static let exportFormat = "stageframe.exportFormat"
        static let exportScale = "stageframe.exportScale"
        static let jpegQuality = "stageframe.jpegQuality"
        static let templateID = "stageframe.templateID"
        static let holePoints = "stageframe.screenHolePoints.v5"
        static let holeTemplateID = "stageframe.screenHoleTemplate.v5"
        static let hasCompletedOnboarding = "stageframe.hasCompletedOnboarding"
        static let licenseKey = "stageframe.licenseKey"
        static let licenseInstanceID = "stageframe.licenseInstanceID"
    }

    static var urlText: String {
        get { defaults.string(forKey: Key.urlText) ?? "apple.com" }
        set { defaults.set(newValue, forKey: Key.urlText) }
    }

    static var hideCookieBanners: Bool {
        get {
            if defaults.object(forKey: Key.hideCookieBanners) == nil {
                return true
            }
            return defaults.bool(forKey: Key.hideCookieBanners)
        }
        set { defaults.set(newValue, forKey: Key.hideCookieBanners) }
    }

    static var durationSeconds: Double {
        get {
            let value = defaults.double(forKey: Key.durationSeconds)
            return value == 0 ? CaptureVideoFormat.defaultDuration : value
        }
        set { defaults.set(newValue, forKey: Key.durationSeconds) }
    }

    static var exportPresetID: String? {
        get { defaults.string(forKey: Key.exportPresetID) }
        set { defaults.set(newValue, forKey: Key.exportPresetID) }
    }

    static var customWidth: Int {
        get {
            let value = defaults.integer(forKey: Key.customWidth)
            return value == 0 ? 1200 : value
        }
        set { defaults.set(newValue, forKey: Key.customWidth) }
    }

    static var customHeight: Int {
        get {
            let value = defaults.integer(forKey: Key.customHeight)
            return value == 0 ? 900 : value
        }
        set { defaults.set(newValue, forKey: Key.customHeight) }
    }

    static var recordWidth: Int {
        get {
            let value = defaults.integer(forKey: Key.recordWidth)
            return value == 0 ? CaptureVideoFormat.defaultWidth : value
        }
        set { defaults.set(newValue, forKey: Key.recordWidth) }
    }

    static var recordHeight: Int {
        get {
            let value = defaults.integer(forKey: Key.recordHeight)
            return value == 0 ? CaptureVideoFormat.defaultHeight : value
        }
        set { defaults.set(newValue, forKey: Key.recordHeight) }
    }

    static var inset: Double {
        get {
            if defaults.object(forKey: Key.inset) == nil { return 48 }
            return defaults.double(forKey: Key.inset)
        }
        set { defaults.set(newValue, forKey: Key.inset) }
    }

    static var deviceOffsetX: Double {
        get { defaults.object(forKey: Key.deviceOffsetX) as? Double ?? 0 }
        set { defaults.set(newValue, forKey: Key.deviceOffsetX) }
    }

    static var deviceOffsetY: Double {
        get { defaults.object(forKey: Key.deviceOffsetY) as? Double ?? 0 }
        set { defaults.set(newValue, forKey: Key.deviceOffsetY) }
    }

    static var overlayX: Double {
        get { defaults.object(forKey: Key.overlayX) as? Double ?? 0.18 }
        set { defaults.set(newValue, forKey: Key.overlayX) }
    }

    static var overlayY: Double {
        get { defaults.object(forKey: Key.overlayY) as? Double ?? 0.16 }
        set { defaults.set(newValue, forKey: Key.overlayY) }
    }

    static var overlayWidth: Double {
        get { defaults.object(forKey: Key.overlayWidth) as? Double ?? 0.64 }
        set { defaults.set(newValue, forKey: Key.overlayWidth) }
    }

    static var overlayHeight: Double {
        get { defaults.object(forKey: Key.overlayHeight) as? Double ?? 0.58 }
        set { defaults.set(newValue, forKey: Key.overlayHeight) }
    }

    static var overlayCorner: Double {
        get { defaults.object(forKey: Key.overlayCorner) as? Double ?? 18 }
        set { defaults.set(newValue, forKey: Key.overlayCorner) }
    }

    static var overlayCornerTL: Double {
        get { defaults.object(forKey: Key.overlayCornerTL) as? Double ?? overlayCorner }
        set { defaults.set(newValue, forKey: Key.overlayCornerTL) }
    }

    static var overlayCornerTR: Double {
        get { defaults.object(forKey: Key.overlayCornerTR) as? Double ?? overlayCorner }
        set { defaults.set(newValue, forKey: Key.overlayCornerTR) }
    }

    static var overlayCornerBR: Double {
        get { defaults.object(forKey: Key.overlayCornerBR) as? Double ?? overlayCorner }
        set { defaults.set(newValue, forKey: Key.overlayCornerBR) }
    }

    static var overlayCornerBL: Double {
        get { defaults.object(forKey: Key.overlayCornerBL) as? Double ?? overlayCorner }
        set { defaults.set(newValue, forKey: Key.overlayCornerBL) }
    }

    static var footageFit: FootageFitMode {
        get { FootageFitMode(rawValue: defaults.string(forKey: Key.footageFit) ?? "") ?? .fill }
        set { defaults.set(newValue.rawValue, forKey: Key.footageFit) }
    }

    static var videoBehindMockup: Bool {
        get {
            if defaults.object(forKey: Key.videoBehindMockup) == nil {
                return true
            }
            return defaults.bool(forKey: Key.videoBehindMockup)
        }
        set { defaults.set(newValue, forKey: Key.videoBehindMockup) }
    }

    static var mockupPath: String? {
        get { defaults.string(forKey: Key.mockupPath) }
        set { defaults.set(newValue, forKey: Key.mockupPath) }
    }

    static var backgroundPath: String? {
        get { defaults.string(forKey: Key.backgroundPath) }
        set { defaults.set(newValue, forKey: Key.backgroundPath) }
    }

    static var volume: Double {
        get {
            if defaults.object(forKey: Key.volume) == nil { return 1 }
            return defaults.double(forKey: Key.volume)
        }
        set { defaults.set(newValue, forKey: Key.volume) }
    }

    static var isMuted: Bool {
        get { defaults.bool(forKey: Key.isMuted) }
        set { defaults.set(newValue, forKey: Key.isMuted) }
    }

    static var exportQuality: ExportQuality {
        get { ExportQuality(rawValue: defaults.string(forKey: Key.exportQuality) ?? "") ?? .high }
        set { defaults.set(newValue.rawValue, forKey: Key.exportQuality) }
    }

    static var exportFPS: ExportFrameRate {
        get {
            let value = defaults.double(forKey: Key.exportFPS)
            return ExportFrameRate(rawValue: value) ?? .fps30
        }
        set { defaults.set(newValue.rawValue, forKey: Key.exportFPS) }
    }

    static var exportFormat: ExportVideoFormat {
        get { ExportVideoFormat(rawValue: defaults.string(forKey: Key.exportFormat) ?? "") ?? .mp4 }
        set { defaults.set(newValue.rawValue, forKey: Key.exportFormat) }
    }

    static var exportScale: ExportScale {
        get { ExportScale.matching(defaults.integer(forKey: Key.exportScale)) }
        set { defaults.set(newValue.rawValue, forKey: Key.exportScale) }
    }

    static var jpegQuality: Double {
        get {
            if defaults.object(forKey: Key.jpegQuality) == nil { return 0.92 }
            return min(max(defaults.double(forKey: Key.jpegQuality), 0.1), 1)
        }
        set { defaults.set(min(max(newValue, 0.1), 1), forKey: Key.jpegQuality) }
    }

    static var templateID: String? {
        get { defaults.string(forKey: Key.templateID) }
        set { defaults.set(newValue, forKey: Key.templateID) }
    }

    static var holeTemplateID: String? {
        get { defaults.string(forKey: Key.holeTemplateID) }
        set { defaults.set(newValue, forKey: Key.holeTemplateID) }
    }

    static var holePoints: [Double]? {
        get { defaults.array(forKey: Key.holePoints) as? [Double] }
        set { defaults.set(newValue, forKey: Key.holePoints) }
    }

    static var hasPlacement: Bool {
        defaults.object(forKey: Key.deviceOffsetX) != nil
    }

    static var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Key.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Key.hasCompletedOnboarding) }
    }

    static var licenseKey: String? {
        get {
            let value = defaults.string(forKey: Key.licenseKey)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return value.isEmpty ? nil : value
        }
        set {
            let trimmed = newValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if trimmed.isEmpty {
                defaults.removeObject(forKey: Key.licenseKey)
            } else {
                defaults.set(trimmed, forKey: Key.licenseKey)
            }
        }
    }

    static var licenseInstanceID: String? {
        get {
            let value = defaults.string(forKey: Key.licenseInstanceID) ?? ""
            return value.isEmpty ? nil : value
        }
        set {
            if let newValue, !newValue.isEmpty {
                defaults.set(newValue, forKey: Key.licenseInstanceID)
            } else {
                defaults.removeObject(forKey: Key.licenseInstanceID)
            }
        }
    }
}

extension Notification.Name {
    static let stageframeOpenVideo = Notification.Name("stageframe.openVideo")
    static let stageframeNewProject = Notification.Name("stageframe.newProject")
}
