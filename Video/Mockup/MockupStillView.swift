import SwiftUI

struct MockupStillView: View {
    var studio: MockupStudio
    var playsVideo = false
    var artboard = CGSize(width: MockupCanvas.width, height: MockupCanvas.height)
    var showsBackground = true
    var showsOverlayGuides = false

    private var mockupImage: NSImage? {
        studio.displayMockupImage
    }

    private var imageRect: CGRect {
        studio.imageRect(in: artboard)
    }

    private var hole: MockupScreenHole {
        studio.displayHole
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if showsBackground {
                BackgroundCanvasView(studio: studio, canvas: artboard)
                    .frame(width: artboard.width, height: artboard.height)
            }

            if let mockupImage {
                pixelImage(mockupImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: imageRect.width, height: imageRect.height, alignment: .topLeading)
                    .offset(x: imageRect.minX, y: imageRect.minY)
                    .allowsHitTesting(false)
            }

            MockupScreenFootage(
                studio: studio,
                playsVideo: playsVideo,
                artboard: artboard,
                imageRect: imageRect,
                hole: hole
            )

            if showsOverlayGuides {
                QuadOutline(points: hole.mapped(in: imageRect))
                    .stroke(EditorChrome.selection, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .allowsHitTesting(false)
            }
        }
        .frame(width: artboard.width, height: artboard.height, alignment: .topLeading)
        .clipped()
        .contentShape(Rectangle())
    }

    private func pixelImage(_ image: NSImage) -> Image {
        if let cgImage = PNGSnapshot.cgImage(of: image) {
            return Image(decorative: cgImage, scale: 1)
        }
        return Image(nsImage: image)
    }
}

struct QuadOutline: Shape {
    var points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        guard points.count == 4 else { return Path() }
        var path = Path()
        path.move(to: points[0])
        path.addLine(to: points[1])
        path.addLine(to: points[2])
        path.addLine(to: points[3])
        path.closeSubpath()
        return path
    }
}

struct RoundedQuadOutline: Shape {
    var points: [CGPoint]
    var radii: [CGFloat]

    init(points: [CGPoint], radius: CGFloat) {
        self.points = points
        self.radii = Array(repeating: radius, count: max(points.count, 4))
    }

    init(points: [CGPoint], radii: [CGFloat]) {
        self.points = points
        self.radii = radii
    }

    func path(in rect: CGRect) -> Path {
        guard points.count >= 3 else { return QuadOutline(points: points).path(in: rect) }

        let count = points.count
        var path = Path()
        var drew = false
        for index in 0..<count {
            let previous = points[(index + count - 1) % count]
            let current = points[index]
            let next = points[(index + 1) % count]
            let inbound = CGVector(dx: previous.x - current.x, dy: previous.y - current.y)
            let outbound = CGVector(dx: next.x - current.x, dy: next.y - current.y)
            let inboundLength = hypot(inbound.dx, inbound.dy)
            let outboundLength = hypot(outbound.dx, outbound.dy)
            let radius = index < radii.count ? radii[index] : 0
            let corner = min(max(radius, 0), inboundLength / 2, outboundLength / 2)

            guard corner > 0.5, inboundLength > 0.001, outboundLength > 0.001 else {
                if !drew {
                    path.move(to: current)
                    drew = true
                } else {
                    path.addLine(to: current)
                }
                continue
            }

            let start = CGPoint(
                x: current.x + inbound.dx / inboundLength * corner,
                y: current.y + inbound.dy / inboundLength * corner
            )
            let end = CGPoint(
                x: current.x + outbound.dx / outboundLength * corner,
                y: current.y + outbound.dy / outboundLength * corner
            )
            if !drew {
                path.move(to: start)
                drew = true
            } else {
                path.addLine(to: start)
            }
            path.addQuadCurve(to: end, control: current)
        }
        path.closeSubpath()
        return path
    }
}

struct MockupLetterboxView: View {
    var studio: MockupStudio
    var playsVideo = false
    var canvas: CGSize
    var showsOverlayGuides = false

    var body: some View {
        MockupStillView(
            studio: studio,
            playsVideo: playsVideo,
            artboard: canvas,
            showsBackground: true,
            showsOverlayGuides: showsOverlayGuides
        )
        .frame(width: canvas.width, height: canvas.height, alignment: .topLeading)
        .clipped()
    }
}

#Preview("Mockup still") {
    MockupStillView(
        studio: MockupStudio(previewOnly: true),
        artboard: CGSize(width: 800, height: 450),
        showsOverlayGuides: true
    )
}

#Preview("Mockup letterbox") {
    MockupLetterboxView(
        studio: MockupStudio(previewOnly: true),
        canvas: CGSize(width: 800, height: 450),
        showsOverlayGuides: true
    )
}
