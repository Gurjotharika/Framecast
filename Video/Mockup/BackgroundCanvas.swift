import SwiftUI

struct BackgroundCanvasView: View {
    var studio: MockupStudio
    var canvas: CGSize

    var body: some View {
        ZStack {
            switch studio.backgroundKind {
            case .preset:
                presetFill
            case .solid:
                studio.solidColor.color
            case .gradient:
                gradientFill
            case .image:
                imageFill
            }

            if studio.backgroundKind == .gradient, studio.gradientVignette {
                RadialGradient(
                    colors: [.clear, .black.opacity(0.62)],
                    center: .center,
                    startRadius: min(canvas.width, canvas.height) * 0.16,
                    endRadius: hypot(canvas.width, canvas.height) * 0.48
                )
                .allowsHitTesting(false)
            }
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipShape(RoundedRectangle(cornerRadius: studio.backgroundCornerRadius, style: .continuous))
        .clipped()
    }

    @ViewBuilder
    private var presetFill: some View {
        let look = BackgroundLibrary.preset(id: studio.presetLookID)
        if look.isBlank {
            Color.clear
        } else if let color = look.colors.first {
            color.color
        }
    }

    @ViewBuilder
    private var gradientFill: some View {
        let stops = studio.gradientStops.sorted { $0.location < $1.location }
        let gradientStops = stops.map {
            Gradient.Stop(color: $0.color.color, location: $0.location)
        }
        Group {
            switch studio.gradientStyle {
            case .linear:
                LinearGradient(
                    stops: gradientStops,
                    startPoint: linearPoints.start,
                    endPoint: linearPoints.end
                )
            case .radial:
                RadialGradient(
                    stops: gradientStops,
                    center: .center,
                    startRadius: 0,
                    endRadius: max(canvas.width, canvas.height) * 0.55 * studio.gradientScale
                )
            case .angular:
                AngularGradient(
                    stops: gradientStops,
                    center: .center,
                    angle: .degrees(studio.gradientAngle)
                )
            }
        }
        .scaleEffect(studio.gradientStyle == .linear ? studio.gradientScale : 1)
    }

    private var linearPoints: (start: UnitPoint, end: UnitPoint) {
        let radians = studio.gradientAngle * .pi / 180
        let dx = cos(radians)
        let dy = sin(radians)
        return (
            UnitPoint(x: 0.5 - dx / 2, y: 0.5 - dy / 2),
            UnitPoint(x: 0.5 + dx / 2, y: 0.5 + dy / 2)
        )
    }

    @ViewBuilder
    private var imageFill: some View {
        if let image = studio.backgroundImage {
            BackgroundImageLayer(
                image: image,
                fit: studio.imageFit,
                scale: studio.imageScale,
                blur: studio.imageBlur,
                opacity: studio.imageOpacity,
                offsetX: studio.imageOffsetX,
                offsetY: studio.imageOffsetY,
                tile: studio.imageTile,
                canvas: canvas
            )
        } else {
            Color.clear
        }
    }
}

private struct BackgroundImageLayer: View {
    var image: NSImage
    var fit: ImageFitMode
    var scale: Double
    var blur: Double
    var opacity: Double
    var offsetX: Double
    var offsetY: Double
    var tile: TilePattern
    var canvas: CGSize

    var body: some View {
        let placed = placement
        Image(nsImage: image)
            .resizable(resizingMode: tile == .none ? .stretch : .tile)
            .interpolation(.high)
            .frame(width: placed.width, height: placed.height)
            .offset(x: placed.minX + offsetX * canvas.width, y: placed.minY + offsetY * canvas.height)
            .scaleEffect(scale)
            .blur(radius: blur)
            .opacity(opacity)
            .frame(width: canvas.width, height: canvas.height, alignment: .topLeading)
            .clipped()
    }

    private var placement: CGRect {
        let size = image.size
        switch tile {
        case .repeat:
            let tileSize = CGSize(width: max(size.width * scale, 8), height: max(size.height * scale, 8))
            return CGRect(origin: .zero, size: CGSize(
                width: canvas.width + tileSize.width,
                height: canvas.height + tileSize.height
            ))
        case .repeatX:
            return CGRect(x: 0, y: 0, width: canvas.width * max(scale, 1), height: canvas.height)
        case .repeatY:
            return CGRect(x: 0, y: 0, width: canvas.width, height: canvas.height * max(scale, 1))
        case .none:
            switch fit {
            case .cover:
                return MockupLayout.aspectFill(size, in: canvas)
            case .contain, .fit:
                return MockupLayout.aspectFit(size, in: canvas)
            case .fill:
                return CGRect(origin: .zero, size: canvas)
            }
        }
    }
}

#Preview("Background canvas") {
    BackgroundCanvasView(
        studio: MockupStudio(previewOnly: true),
        canvas: CGSize(width: 640, height: 360)
    )
}
