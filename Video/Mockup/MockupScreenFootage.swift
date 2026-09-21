import AppKit
import AVFoundation
import SwiftUI

struct MockupScreenFootage: View {
    var studio: MockupStudio
    var playsVideo: Bool
    var artboard: CGSize
    var imageRect: CGRect
    var hole: MockupScreenHole

    private var quad: [CGPoint] {
        hole.mapped(in: imageRect)
    }

    private var transform: CATransform3D {
        QuadHomography.transform(
            from: CGRect(origin: .zero, size: artboard),
            to: quad
        )
    }

    private var destRadii: [CGFloat] {
        let scale = min(imageRect.width, imageRect.height) / MockupCanvas.width
        return ScreenCorner.allCases.map { studio.cornerRadius($0) * scale }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if studio.shadowEnabled {
                shadowLayer
            }

            footageLayer
                .frame(width: artboard.width, height: artboard.height)
                .projectionEffect(ProjectionTransform(transform))
                .compositingGroup()
                .mask {
                    RoundedQuadOutline(points: quad, radii: destRadii)
                        .fill(Color.white)
                }

            if studio.borderEnabled {
                RoundedQuadOutline(points: quad, radii: destRadii)
                    .stroke(studio.borderColor.color, lineWidth: studio.borderWidth)
            }
        }
        .frame(width: artboard.width, height: artboard.height)
        .clipped()
        .allowsHitTesting(false)
    }

    private var footageLayer: some View {
        ZStack {
            studio.footageMatte.color
            content
                .scaleEffect(studio.contentScale)
                .offset(
                    x: studio.contentOffsetX * artboard.width,
                    y: studio.contentOffsetY * artboard.height
                )
        }
        .frame(width: artboard.width, height: artboard.height)
        .clipped()
    }

    @ViewBuilder
    private var content: some View {
        if playsVideo, studio.hasVideo {
            MockupPlayerView(player: studio.player, gravity: playerGravity)
                .frame(width: artboard.width, height: artboard.height)
        } else if let image = studio.screenImage {
            stillImage(image)
        } else {
            Rectangle()
                .fill(Color.black)
                .overlay {
                    Text("Record or drop a clip")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
        }
    }

    @ViewBuilder
    private func stillImage(_ image: NSImage) -> some View {
        if studio.footageFit.stretches {
            Image(nsImage: image)
                .resizable()
                .frame(width: artboard.width, height: artboard.height)
        } else {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: studio.footageFit.usesFill ? .fill : .fit)
                .frame(width: artboard.width, height: artboard.height)
                .clipped()
        }
    }

    private var playerGravity: AVLayerVideoGravity {
        switch studio.footageFit {
        case .fill: .resize
        case .cover: .resizeAspectFill
        case .fit, .contain: .resizeAspect
        }
    }

    private var shadowLayer: some View {
        let box = boundingBox(of: quad)
        let radius = studio.shadowCornerRadius * min(artboard.width, artboard.height) / MockupCanvas.width
        return RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color.black.opacity(studio.shadowIntensity))
            .frame(width: box.width, height: box.height)
            .offset(
                x: box.minX + studio.shadowCenterX * artboard.width,
                y: box.minY + studio.shadowCenterY * artboard.height
            )
            .rotationEffect(.degrees(studio.shadowRotation))
            .blur(radius: 18 * studio.shadowIntensity)
            .allowsHitTesting(false)
    }

    private func boundingBox(of points: [CGPoint]) -> CGRect {
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
        return CGRect(x: minX, y: minY, width: max(maxX - minX, 1), height: max(maxY - minY, 1))
    }
}

struct PerspectivePlayerView: NSViewRepresentable {
    var player: AVPlayer
    var transform: CATransform3D
    var gravity: AVLayerVideoGravity = .resizeAspectFill

    func makeNSView(context: Context) -> PerspectivePlayerNSView {
        let view = PerspectivePlayerNSView()
        view.player = player
        view.layerTransform = transform
        view.gravity = gravity
        return view
    }

    func updateNSView(_ view: PerspectivePlayerNSView, context: Context) {
        view.player = player
        view.layerTransform = transform
        view.gravity = gravity
    }
}

final class PerspectivePlayerNSView: NSView {
    private let playerLayer = AVPlayerLayer()

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var layerTransform: CATransform3D = CATransform3DIdentity {
        didSet { applyTransform() }
    }

    var gravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet { playerLayer.videoGravity = gravity }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = false
        playerLayer.videoGravity = gravity
        playerLayer.masksToBounds = true
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
        applyTransform()
    }

    private func applyTransform() {
        playerLayer.anchorPoint = CGPoint(x: 0, y: 0)
        playerLayer.frame = bounds
        playerLayer.transform = layerTransform
    }
}
#Preview("MockupScreenFootage") {
    let studio = MockupStudio(previewOnly: true)
    studio.footageMatte = .white
    let artboard = CGSize(width: 600, height: 400)
    let imageRect = CGRect(origin: .zero, size: artboard)
    let hole = MockupScreenHole.rect(CGRect(x: 0.1, y: 0.12, width: 0.8, height: 0.7))
    return ZStack {
        Color.black
        MockupScreenFootage(
            studio: studio,
            playsVideo: false,
            artboard: artboard,
            imageRect: imageRect,
            hole: hole
        )
    }
    .frame(width: artboard.width, height: artboard.height)
}

