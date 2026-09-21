import AppKit
import Foundation
import SwiftUI

enum ScreenCorner: Int, CaseIterable, Identifiable {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .topLeft: "Top left"
        case .topRight: "Top right"
        case .bottomRight: "Bottom right"
        case .bottomLeft: "Bottom left"
        }
    }

    var shortTitle: String {
        switch self {
        case .topLeft: "TL"
        case .topRight: "TR"
        case .bottomRight: "BR"
        case .bottomLeft: "BL"
        }
    }
}

enum MockupCatalogFilter: String, CaseIterable, Identifiable {
    case all
    case fixedScene
    case customBG

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .fixedScene: "Fixed Scene"
        case .customBG: "Custom BG"
        }
    }
}

enum MockupCategory: String, Hashable, Codable {
    case blank
    case fixedScene
    case customBG
}

struct MockupScreenHole: Hashable, Codable {
    var points: [CGPoint]

    static func rect(_ rect: CGRect) -> MockupScreenHole {
        MockupScreenHole(points: [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY),
        ])
    }

    var boundingRect: CGRect {
        guard let first = points.first else { return .zero }
        var minX = first.x
        var minY = first.y
        var maxX = first.x
        var maxY = first.y
        for point in points.dropFirst() {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }
        return CGRect(x: minX, y: minY, width: max(maxX - minX, 0.01), height: max(maxY - minY, 0.01))
    }

    func visualAspect(in imageSize: CGSize) -> CGFloat {
        let mapped = mapped(in: CGRect(origin: .zero, size: imageSize))
        guard mapped.count == 4 else {
            let box = boundingRect
            return (box.width * imageSize.width) / max(box.height * imageSize.height, 1)
        }
        let top = hypot(mapped[1].x - mapped[0].x, mapped[1].y - mapped[0].y)
        let bottom = hypot(mapped[2].x - mapped[3].x, mapped[2].y - mapped[3].y)
        let left = hypot(mapped[3].x - mapped[0].x, mapped[3].y - mapped[0].y)
        let right = hypot(mapped[2].x - mapped[1].x, mapped[2].y - mapped[1].y)
        let width = (top + bottom) / 2
        let height = (left + right) / 2
        return max(width, 1) / max(height, 1)
    }

    func mapped(in imageRect: CGRect) -> [CGPoint] {
        points.map { point in
            CGPoint(
                x: imageRect.minX + point.x * imageRect.width,
                y: imageRect.minY + point.y * imageRect.height
            )
        }
    }

    func framed(size: Double, offsetX: Double, offsetY: Double) -> MockupScreenHole {
        let box = boundingRect
        let center = CGPoint(x: box.midX, y: box.midY)
        return MockupScreenHole(points: points.map { point in
            CGPoint(
                x: center.x + (point.x - center.x) * size + offsetX,
                y: center.y + (point.y - center.y) * size + offsetY
            )
        })
    }

    func ensuringFourPoints() -> MockupScreenHole {
        points.count == 4 ? self : .rect(boundingRect)
    }

    mutating func setPoint(_ corner: ScreenCorner, to point: CGPoint) {
        var next = ensuringFourPoints().points
        next[corner.rawValue] = point
        points = next
    }

    func point(_ corner: ScreenCorner) -> CGPoint {
        let pts = ensuringFourPoints().points
        return pts[corner.rawValue]
    }

    enum CodingKeys: String, CodingKey {
        case points
    }

    init(points: [CGPoint]) {
        self.points = points
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let pairs = try container.decode([[Double]].self, forKey: .points)
        points = pairs.map { pair in
            CGPoint(x: pair.first ?? 0, y: pair.count > 1 ? pair[1] : 0)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(points.map { [$0.x, $0.y] }, forKey: .points)
    }
}

struct MockupTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let blurb: String
    let imageName: String
    let category: MockupCategory
    let cornerRadius: Double
    let hole: MockupScreenHole
    let image: NSImage?

    var isFixedScene: Bool { category == .fixedScene }
    var isBlank: Bool { category == .blank }
    var screenCorner: Double { cornerRadius }

    static var catalog: [MockupTemplate] { BundledMockupCatalog.templates }

    static var fallback: MockupTemplate {
        catalog.first(where: { !$0.isBlank && $0.image != nil }) ?? catalog.first ?? MockupTemplate(
            id: "empty",
            name: "Mockup",
            blurb: "Add a PNG and screen coordinates in Mockups/catalog.json",
            imageName: "",
            category: .customBG,
            cornerRadius: 4,
            hole: .rect(CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.45)),
            image: nil
        )
    }

    func matches(_ filter: MockupCatalogFilter) -> Bool {
        switch filter {
        case .all:
            true
        case .fixedScene:
            category == .fixedScene
        case .customBG:
            category == .customBG || category == .blank
        }
    }
}

enum BundledMockupCatalog {
    private struct File: Decodable {
        var mockups: [Entry]
    }

    private struct Entry: Decodable {
        var id: String
        var name: String
        var blurb: String
        var image: String?
        var category: MockupCategory
        var cornerRadius: Double?
        var screen: Screen

        struct Screen: Decodable {
            var mode: String?
            var x: Double?
            var y: Double?
            var width: Double?
            var height: Double?
            var points: [[Double]]?
        }
    }

    static let templates: [MockupTemplate] = load()

    private static func load() -> [MockupTemplate] {
        let url =
            Bundle.main.url(forResource: "catalog", withExtension: "json", subdirectory: "Mockups")
            ?? Bundle.main.url(forResource: "catalog", withExtension: "json")
            ?? developmentCatalogURL()
        guard let url, let data = try? Data(contentsOf: url) else { return [] }
        guard let file = try? JSONDecoder().decode(File.self, from: data) else { return [] }

        return file.mockups.compactMap { entry in
            let fileName = entry.image ?? ""
            let image = fileName.isEmpty ? nil : loadImage(named: fileName)
            let catalogHole = hole(from: entry.screen)
            let hole = catalogHole
                ?? image.flatMap { ScreenHoleDetector.detect(in: $0) }
                ?? .rect(CGRect(x: 0.2, y: 0.18, width: 0.6, height: 0.48))
            return MockupTemplate(
                id: entry.id,
                name: entry.name,
                blurb: entry.blurb,
                imageName: fileName,
                category: entry.category,
                cornerRadius: entry.cornerRadius ?? 4,
                hole: hole,
                image: image
            )
        }
    }

    private static func hole(from screen: Entry.Screen) -> MockupScreenHole? {
        if let points = screen.points, points.count == 4 {
            return MockupScreenHole(points: points.map { CGPoint(x: $0.first ?? 0, y: $0.count > 1 ? $0[1] : 0) })
        }
        if let x = screen.x, let y = screen.y, let width = screen.width, let height = screen.height {
            return .rect(CGRect(x: x, y: y, width: width, height: height))
        }
        return nil
    }

    private static func loadImage(named fileName: String) -> NSImage? {
        BundledMedia.image(named: fileName)
    }

    private static func developmentCatalogURL() -> URL? {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Mockups/catalog.json")
    }
}
