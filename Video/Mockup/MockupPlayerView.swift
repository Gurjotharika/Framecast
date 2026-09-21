import AppKit
import AVFoundation
import SwiftUI

struct MockupPlayerView: NSViewRepresentable {
    var player: AVPlayer
    var gravity: AVLayerVideoGravity = .resizeAspectFill

    func makeNSView(context: Context) -> PlayerNSView {
        let view = PlayerNSView()
        view.player = player
        view.gravity = gravity
        return view
    }

    func updateNSView(_ view: PlayerNSView, context: Context) {
        view.player = player
        view.gravity = gravity
    }
}

final class PlayerNSView: NSView {
    private let playerLayer = AVPlayerLayer()

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var gravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet { playerLayer.videoGravity = gravity }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
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
    }
}

#Preview("Mockup player") {
    MockupPlayerView(player: AVPlayer())
        .frame(width: 640, height: 360)
        .background(.black)
}
