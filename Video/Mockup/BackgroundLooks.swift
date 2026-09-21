import AppKit
import SwiftUI

enum BackgroundKind: String, CaseIterable, Identifiable {
    case preset
    case solid
    case gradient
    case image

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preset: "Preset"
        case .solid: "Solid"
        case .gradient: "Gradient"
        case .image: "Image"
        }
    }
}

enum ImageFitMode: String, CaseIterable, Identifiable {
    case cover
    case contain
    case fit
    case fill

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum TilePattern: String, CaseIterable, Identifiable {
    case none
    case `repeat`
    case repeatX
    case repeatY

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "None"
        case .repeat: "Repeat"
        case .repeatX: "Repeat X"
        case .repeatY: "Repeat Y"
        }
    }
}

enum GradientStyleKind: String, CaseIterable, Identifiable {
    case linear
    case radial
    case angular

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum GradientCollection: String, CaseIterable, Identifiable {
    case colorful
    case dark

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum FootageFitMode: String, CaseIterable, Identifiable {
    case fit
    case fill
    case contain
    case cover

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var usesFill: Bool {
        self == .cover
    }

    var stretches: Bool {
        self == .fill
    }
}

struct RGBAColor: Hashable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double = 1

    var color: Color {
        Color(red: r, green: g, blue: b, opacity: a)
    }

    var hex: String {
        String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }

    func replacingHex(_ hex: String) -> RGBAColor? {
        guard let parsed = RGBAColor(hex: hex) else { return nil }
        return RGBAColor(r: parsed.r, g: parsed.g, b: parsed.b, a: a)
    }

    static let black = RGBAColor(r: 0.07, g: 0.07, b: 0.08)
    static let white = RGBAColor(r: 1, g: 1, b: 1)
    static let orange = RGBAColor(r: 1, g: 0.48, b: 0.14)
    static let gray = RGBAColor(r: 0.82, g: 0.83, b: 0.85)
    static let clear = RGBAColor(r: 0, g: 0, b: 0, a: 0)

    init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    init(_ color: Color) {
        let resolved = color.resolve(in: EnvironmentValues())
        r = Double(resolved.red)
        g = Double(resolved.green)
        b = Double(resolved.blue)
        a = Double(resolved.opacity)
    }

    init?(hex: String) {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("#") {
            raw.removeFirst()
        }
        guard raw.count == 6, let value = UInt32(raw, radix: 16) else {
            return nil
        }
        r = Double((value >> 16) & 0xFF) / 255
        g = Double((value >> 8) & 0xFF) / 255
        b = Double(value & 0xFF) / 255
        a = 1
    }
}

struct GradientStopItem: Identifiable, Hashable {
    var id = UUID()
    var color: RGBAColor
    var location: Double
}

struct BackgroundLook: Identifiable, Hashable {
    let id: String
    let name: String
    let isBlank: Bool
    let colors: [RGBAColor]
}

struct UserBackgroundImage: Identifiable {
    let id: UUID
    var name: String
    var image: NSImage
    var path: String
}

struct BundledBackgroundImage: Identifiable {
    let id: String
    let name: String
    let fileName: String
    var image: NSImage?
}

enum BackgroundLibrary {
    static let presets: [BackgroundLook] = [
        BackgroundLook(id: "blank", name: "Blank", isBlank: true, colors: [RGBAColor.clear]),
        BackgroundLook(id: "dark", name: "Dark", isBlank: false, colors: [RGBAColor(r: 0.07, g: 0.07, b: 0.08)]),
        BackgroundLook(id: "light", name: "Light", isBlank: false, colors: [RGBAColor(r: 0.93, g: 0.93, b: 0.94)]),
        BackgroundLook(id: "orange", name: "Orange", isBlank: false, colors: [RGBAColor.orange]),
        BackgroundLook(id: "soft-gray", name: "Soft gray", isBlank: false, colors: [RGBAColor(r: 0.78, g: 0.79, b: 0.81)]),
    ]

    static let colorfulGradients: [BackgroundLook] = [
        BackgroundLook(id: "g-blank", name: "Blank", isBlank: true, colors: [RGBAColor.clear, RGBAColor.clear]),
        BackgroundLook(id: "dusk", name: "Dusk", isBlank: false, colors: [RGBAColor(r: 0.08, g: 0.16, b: 0.26), RGBAColor(r: 0.72, g: 0.48, b: 0.36)]),
        BackgroundLook(id: "candy", name: "Candy", isBlank: false, colors: [RGBAColor(r: 0.83, g: 0.22, b: 0.55), RGBAColor(r: 0.98, g: 0.55, b: 0.24)]),
        BackgroundLook(id: "ocean", name: "Ocean", isBlank: false, colors: [RGBAColor(r: 0.05, g: 0.28, b: 0.48), RGBAColor(r: 0.18, g: 0.78, b: 0.72)]),
        BackgroundLook(id: "aurora", name: "Aurora", isBlank: false, colors: [RGBAColor(r: 0.16, g: 0.72, b: 0.48), RGBAColor(r: 0.23, g: 0.28, b: 0.86)]),
        BackgroundLook(id: "sunset", name: "Sunset", isBlank: false, colors: [RGBAColor(r: 0.95, g: 0.35, b: 0.32), RGBAColor(r: 0.98, g: 0.76, b: 0.28)]),
        BackgroundLook(id: "citrus", name: "Citrus", isBlank: false, colors: [RGBAColor(r: 0.72, g: 0.88, b: 0.16), RGBAColor(r: 0.98, g: 0.78, b: 0.18)]),
        BackgroundLook(id: "tropic", name: "Tropic", isBlank: false, colors: [RGBAColor(r: 0.08, g: 0.78, b: 0.70), RGBAColor(r: 0.86, g: 0.22, b: 0.62)]),
        BackgroundLook(id: "orchid", name: "Orchid", isBlank: false, colors: [RGBAColor(r: 0.48, g: 0.20, b: 0.82), RGBAColor(r: 0.94, g: 0.40, b: 0.64)]),
        BackgroundLook(id: "flame", name: "Flame", isBlank: false, colors: [RGBAColor(r: 0.82, g: 0.10, b: 0.18), RGBAColor(r: 0.98, g: 0.56, b: 0.14)]),
    ]

    static let darkGradients: [BackgroundLook] = [
        BackgroundLook(id: "d-blank", name: "Blank", isBlank: true, colors: [RGBAColor.clear, RGBAColor.clear]),
        BackgroundLook(id: "carbon", name: "Carbon", isBlank: false, colors: [RGBAColor(r: 0.05, g: 0.05, b: 0.06), RGBAColor(r: 0.16, g: 0.16, b: 0.18)]),
        BackgroundLook(id: "night", name: "Night", isBlank: false, colors: [RGBAColor(r: 0.04, g: 0.06, b: 0.12), RGBAColor(r: 0.12, g: 0.16, b: 0.28)]),
        BackgroundLook(id: "ember", name: "Ember", isBlank: false, colors: [RGBAColor(r: 0.08, g: 0.03, b: 0.03), RGBAColor(r: 0.28, g: 0.08, b: 0.05)]),
        BackgroundLook(id: "forest", name: "Forest", isBlank: false, colors: [RGBAColor(r: 0.03, g: 0.08, b: 0.05), RGBAColor(r: 0.08, g: 0.18, b: 0.12)]),
        BackgroundLook(id: "ink", name: "Ink", isBlank: false, colors: [RGBAColor(r: 0.02, g: 0.02, b: 0.03), RGBAColor(r: 0.10, g: 0.10, b: 0.14)]),
        BackgroundLook(id: "plum", name: "Plum", isBlank: false, colors: [RGBAColor(r: 0.08, g: 0.03, b: 0.10), RGBAColor(r: 0.26, g: 0.10, b: 0.32)]),
        BackgroundLook(id: "abyss", name: "Abyss", isBlank: false, colors: [RGBAColor(r: 0.02, g: 0.06, b: 0.10), RGBAColor(r: 0.05, g: 0.18, b: 0.24)]),
        BackgroundLook(id: "slate", name: "Slate", isBlank: false, colors: [RGBAColor(r: 0.07, g: 0.09, b: 0.12), RGBAColor(r: 0.22, g: 0.26, b: 0.32)]),
        BackgroundLook(id: "bronze", name: "Bronze", isBlank: false, colors: [RGBAColor(r: 0.08, g: 0.05, b: 0.02), RGBAColor(r: 0.28, g: 0.18, b: 0.08)]),
    ]

    static func gradients(in collection: GradientCollection) -> [BackgroundLook] {
        switch collection {
        case .colorful: colorfulGradients
        case .dark: darkGradients
        }
    }

    static let solids: [BackgroundLook] = [
        BackgroundLook(id: "s-blank", name: "Blank", isBlank: true, colors: [RGBAColor.clear]),
        BackgroundLook(id: "s-white", name: "White", isBlank: false, colors: [RGBAColor.white]),
        BackgroundLook(id: "s-ivory", name: "Ivory", isBlank: false, colors: [RGBAColor(r: 0.97, g: 0.95, b: 0.90)]),
        BackgroundLook(id: "s-soft-gray", name: "Soft gray", isBlank: false, colors: [RGBAColor(r: 0.82, g: 0.83, b: 0.85)]),
        BackgroundLook(id: "s-stone", name: "Stone", isBlank: false, colors: [RGBAColor(r: 0.55, g: 0.56, b: 0.58)]),
        BackgroundLook(id: "s-charcoal", name: "Charcoal", isBlank: false, colors: [RGBAColor(r: 0.18, g: 0.18, b: 0.20)]),
        BackgroundLook(id: "s-black", name: "Black", isBlank: false, colors: [RGBAColor.black]),
        BackgroundLook(id: "s-orange", name: "Orange", isBlank: false, colors: [RGBAColor.orange]),
        BackgroundLook(id: "s-amber", name: "Amber", isBlank: false, colors: [RGBAColor(r: 0.96, g: 0.72, b: 0.22)]),
        BackgroundLook(id: "s-coral", name: "Coral", isBlank: false, colors: [RGBAColor(r: 0.94, g: 0.38, b: 0.36)]),
        BackgroundLook(id: "s-navy", name: "Navy", isBlank: false, colors: [RGBAColor(r: 0.10, g: 0.18, b: 0.36)]),
        BackgroundLook(id: "s-sky", name: "Sky", isBlank: false, colors: [RGBAColor(r: 0.42, g: 0.64, b: 0.92)]),
        BackgroundLook(id: "s-teal", name: "Teal", isBlank: false, colors: [RGBAColor(r: 0.12, g: 0.52, b: 0.50)]),
        BackgroundLook(id: "s-mint", name: "Mint", isBlank: false, colors: [RGBAColor(r: 0.62, g: 0.86, b: 0.74)]),
        BackgroundLook(id: "s-lavender", name: "Lavender", isBlank: false, colors: [RGBAColor(r: 0.72, g: 0.68, b: 0.90)]),
        BackgroundLook(id: "s-blush", name: "Blush", isBlank: false, colors: [RGBAColor(r: 0.94, g: 0.72, b: 0.76)]),
    ]

    private static let imageSpecs: [(id: String, name: String, fileName: String)] = [
        ("canopy", "Canopy", "canopy.jpg"),
        ("charcoal", "Charcoal", "Charcoal.png"),
        ("cosmic", "Cosmic", "Cosmic.png"),
        ("dreamy", "Dreamy", "dreamy.png"),
        ("ethereal", "Ethereal", "Ethereal.png"),
        ("green-motion", "Green Motion", "Green Motion.png"),
        ("stidop", "Studio", "studio.jpg"),
        ("textured", "Textured", "Textured.png"),
        ("urban-lightscape", "Urban Lightscape", "Urban Lightscape.png"),
    ]

    private static var cachedImages: [BundledBackgroundImage]?

    static var images: [BundledBackgroundImage] {
        if let cachedImages, cachedImages.contains(where: { $0.image != nil }) {
            return cachedImages
        }
        let loaded = imageSpecs.map { spec in
            BundledBackgroundImage(id: spec.id, name: spec.name, fileName: spec.fileName, image: loadBackground(spec.fileName))
        }
        if loaded.contains(where: { $0.image != nil }) {
            cachedImages = loaded
        }
        return loaded
    }

    static func preset(id: String) -> BackgroundLook {
        presets.first(where: { $0.id == id }) ?? presets[1]
    }

    static func solid(id: String) -> BackgroundLook {
        solids.first(where: { $0.id == id }) ?? solids[1]
    }

    private static func loadBackground(_ fileName: String) -> NSImage? {
        BundledMedia.image(named: fileName)
    }
}
