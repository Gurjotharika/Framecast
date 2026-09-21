import Foundation

enum ExportSizeGroup: String, CaseIterable, Identifiable {
    case framerWeb
    case social
    case aspect_ratio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .framerWeb: "Framer & Web"
        case .social: "Social"
            case .aspect_ratio: "Aspect Ratio"
        }
    }
}

enum ExportScale: Int, CaseIterable, Identifiable {
    case one = 1
    case two = 2
    case three = 3

    var id: Int { rawValue }
    var title: String { "\(rawValue)x" }

    static func matching(_ value: Int) -> ExportScale {
        ExportScale(rawValue: value) ?? .one
    }
}

struct ExportSizePreset: Identifiable, Hashable {
    let id: String
    let name: String
    let width: Int
    let height: Int
    let group: ExportSizeGroup

    var isCustom: Bool { id == "custom" }

    var sizeLabel: String { "\(width)×\(height)" }

    var chipTitle: String {
        switch id {
        case "framer": "Framer 3.0"
        default: name
        }
    }

    static let all: [ExportSizePreset] = [
        ExportSizePreset(id: "framer", name: "Framer (1200x900)", width: 1200, height: 900, group: .framerWeb),
        ExportSizePreset(id: "opengraph", name: "Open Graph (1200x630)", width: 1200, height: 630, group: .framerWeb),
        ExportSizePreset(id: "product_hunt", name: "Product Hunt (1270x760)", width: 1270, height: 760, group: .framerWeb),
        ExportSizePreset(id: "dribbble", name: "Dribbble (1600x1200)", width: 1600, height: 1200, group: .framerWeb),
        ExportSizePreset(id: "square", name: "Square (1200x1200)", width: 1200, height: 1200, group: .framerWeb),

        ExportSizePreset(id: "x", name: "X (1600x900)", width: 1600, height: 900, group: .social),
        ExportSizePreset(id: "instagram", name: "Instagram (1080x1350)", width: 1080, height: 1350, group: .social),
        ExportSizePreset(id: "instagram-square", name: "Instagram Square (1080x1080)", width: 1080, height: 1080, group: .social),
        ExportSizePreset(id: "instagram-story", name: "Instagram Story (1080x1920)", width: 1080, height: 1920, group: .social),
        ExportSizePreset(id: "pinteres", name: "Pinterest (1000x1500)", width: 1000, height: 1500, group: .social),
        ExportSizePreset(id: "pinterest-long", name: "Pinterest Long (1000x2100)", width: 1000, height: 2100, group: .social),
        ExportSizePreset(id: "facebook-post", name: "Facebook Post (1200x630)", width: 1200, height: 630, group: .social),
        ExportSizePreset(id: "facebook-cover", name: "Facebook Cover (1640x924)", width: 1640, height: 924, group: .social),
        ExportSizePreset(id: "facebook-story", name: "Facebook Story (1080x1920)", width: 1080, height: 1920, group: .social),
        ExportSizePreset(id: "linkedin", name: "LinkedIn (1200x627)", width: 1200, height: 627, group: .social),
        ExportSizePreset(id: "youtube", name: "YouTube (1280x720)", width: 1280, height: 720, group: .social),
        ExportSizePreset(id: "tiktok", name: "TikTok (1080x1920)", width: 1080, height: 1920, group: .social),
        
        ExportSizePreset(id: "widescreen169", name: "16:9 (1920x1080)", width: 1920, height: 1080, group: .aspect_ratio),
        ExportSizePreset(id: "widescreen43", name: "4:3 (1600x1200)", width: 1600, height: 1200, group: .aspect_ratio),
        ExportSizePreset(id: "widescreen916", name: "9:16 (1080x1920", width: 1080, height: 1920, group: .aspect_ratio),
        ExportSizePreset(id: "widescreen34", name: "3:4 (1200x1600)", width: 1200, height: 1600, group: .aspect_ratio),
    ]

    static let framer = all[0]

    static func presets(in group: ExportSizeGroup) -> [ExportSizePreset] {
        all.filter { $0.group == group }
    }

    static func evenPixel(_ value: Int) -> Int {
        let clamped = min(max(value, 320), 7680)
        return clamped - (clamped % 2)
    }
}
