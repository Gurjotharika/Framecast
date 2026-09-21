import CoreGraphics
import Foundation

enum MockupLayout {
    static let previewMaxSize = CGSize(width: 960, height: 720)

    static func unit(in design: CGRect) -> CGFloat {
        design.width / MockupCanvas.width
    }

    static func fittedDesign(in canvas: CGSize) -> CGRect {
        let scale = min(
            canvas.width / MockupCanvas.width,
            canvas.height / MockupCanvas.height
        )
        let size = CGSize(width: MockupCanvas.width * scale, height: MockupCanvas.height * scale)
        return CGRect(
            x: (canvas.width - size.width) / 2,
            y: (canvas.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    static func previewCanvas(for export: CGSize) -> CGSize {
        previewCanvas(for: export, fitting: previewMaxSize)
    }

    static func previewCanvas(for export: CGSize, fitting available: CGSize, padding: CGFloat = 36) -> CGSize {
        let box = CGSize(
            width: max(available.width - padding * 2, 160),
            height: max(available.height - padding * 2, 120)
        )
        let scale = min(
            box.width / max(export.width, 1),
            box.height / max(export.height, 1)
        )
        return CGSize(width: export.width * scale, height: export.height * scale)
    }

    static func aspectFill(_ size: CGSize, in canvas: CGSize) -> CGRect {
        aspectFill(size, in: canvas, anchor: CGPoint(x: 0.5, y: 0.5))
    }

    static func aspectFill(_ size: CGSize, in canvas: CGSize, anchor: CGPoint) -> CGRect {
        let scale = max(
            canvas.width / max(size.width, 1),
            canvas.height / max(size.height, 1)
        )
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        var rect = CGRect(
            x: (canvas.width - fitted.width) / 2,
            y: (canvas.height - fitted.height) / 2,
            width: fitted.width,
            height: fitted.height
        )
        let focus = CGPoint(
            x: min(max(anchor.x, 0), 1),
            y: min(max(anchor.y, 0), 1)
        )
        let current = CGPoint(
            x: rect.minX + focus.x * rect.width,
            y: rect.minY + focus.y * rect.height
        )
        let shiftX = min(max(canvas.width / 2 - current.x, canvas.width - rect.maxX), -rect.minX)
        let shiftY = min(max(canvas.height / 2 - current.y, canvas.height - rect.maxY), -rect.minY)
        rect.origin.x += shiftX
        rect.origin.y += shiftY
        return rect
    }

    static func aspectFit(_ size: CGSize, in canvas: CGSize) -> CGRect {
        let scale = min(
            canvas.width / max(size.width, 1),
            canvas.height / max(size.height, 1)
        )
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(
            x: (canvas.width - fitted.width) / 2,
            y: (canvas.height - fitted.height) / 2,
            width: fitted.width,
            height: fitted.height
        )
    }

    static func overlayRect(
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        in canvas: CGSize
    ) -> CGRect {
        CGRect(
            x: x * canvas.width,
            y: y * canvas.height,
            width: max(width * canvas.width, 8),
            height: max(height * canvas.height, 8)
        )
    }
}
