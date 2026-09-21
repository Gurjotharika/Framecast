import AppKit
import SwiftUI

struct EditorTimeline: View {
    @Bindable var trimmer: TrimEditor
    var studio: MockupStudio
    var session: CaptureSession
    var onSeek: (Double) -> Void
    var onPlay: () -> Void
    var onSnapshot: () -> Void
    var onMuteToggle: () -> Void
    var onVolume: (Double) -> Void
    @State private var zoom = 1.0

    private var playhead: Double {
        studio.hasVideo ? studio.playhead : trimmer.playhead
    }

    private var isPlaying: Bool {
        studio.hasVideo ? studio.isPlaying : trimmer.isPlaying
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(EditorChrome.stroke)
                .frame(height: 1)

            metadataRow
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)

            HStack(alignment: .center, spacing: 12) {
                sideControls
                    .padding(.top, 12)

                GeometryReader { geo in
                    let stripWidth = max(geo.size.width * zoom, geo.size.width)
                    UnifiedTimelineView(
                        trimmer: trimmer,
                        playhead: playhead,
                        isPlaying: isPlaying,
                        zoom: zoom,
                        width: stripWidth,
                        height: geo.size.height,
                        visibleWidth: geo.size.width,
                        onSeek: onSeek
                    )
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .padding(.bottom, 10)
        }
        .frame(height: EditorChrome.timelineHeight)
        .background(EditorChrome.bar)
    }

    private var sideControls: some View {
        VStack(spacing: 8) {
            playButton
            audioControls
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 8) {
            Text(EditorTime.clock(playhead))
                .foregroundStyle(.white)
            
            Text(EditorTime.clock(trimmer.hasMovie ? trimmer.duration : 0))
                .foregroundStyle(EditorChrome.muted)
            
            Text("·")
                .foregroundStyle(EditorChrome.faint)
            
            Text("\(studio.exportPreset.chipTitle) \(studio.exportSizeLabel)")
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(EditorChrome.raised, in: Capsule())
            
            Text("·")
                .foregroundStyle(EditorChrome.faint)
            
            Text("\(EditorTime.clock(trimmer.trimStart))  →  \(EditorTime.clock(trimmer.trimEnd))")
                .foregroundStyle(EditorChrome.faint)
                .opacity(trimmer.hasMovie ? 1 : 0)

            Spacer(minLength: 8)

            Button(action: onSnapshot) {
                Image(systemName: "camera.fill")
            }
            .buttonStyle(.plain)
            .frame(width: 36, height: 32)
            .glassEffect(.regular)
            .foregroundStyle(EditorChrome.muted)
            .disabled(!studio.hasSource)
            .keyboardShortcut("s", modifiers: [.command])

            zoomSlider
        }
        .font(.system(size: 11, weight: .medium).monospacedDigit())
    }

    private var playButton: some View {
        Button(action: onPlay) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .frame(width: 48, height: 42)
        .glassEffect(.regular.tint(.white).interactive())
        .keyboardShortcut(.space, modifiers: [])
        .disabled(!studio.hasVideo && !trimmer.hasMovie)
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
    }

    private var audioControls: some View {
        VStack(spacing: 4) {
            Button(action: onMuteToggle) {
                Image(systemName: studio.isMuted || !(studio.hasAudio || trimmer.hasAudio) ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(studio.isMuted ? EditorChrome.export : .white.opacity(0.86))
                    .frame(width: 28, height: 22)
            }
            .buttonStyle(.plain)
            .disabled(!(studio.hasAudio || trimmer.hasAudio))
            .help(studio.isMuted ? "Unmute audio" : "Mute audio")
            .accessibilityLabel(studio.isMuted ? "Unmute" : "Mute")
        }
    }

    private var zoomSlider: some View {
        InspectorSlider(
            title: "Zoom",
            value: $zoom,
            range: 1...8,
            valueString: { _ in zoomLabel }
        )
        .frame(width: 168)
        .help("Zoom the timeline")
    }

    private var zoomLabel: String {
        abs(zoom - zoom.rounded()) < 0.05 ? "\(Int(zoom.rounded()))x" : String(format: "%.1fx", zoom)
    }

    private var clipLabel: String {
        if trimmer.hasMovie {
            return trimmer.clipName
        }
        if let host = session.loadedURL?.host {
            return host
        }
        return "No clip"
    }
}

private struct UnifiedTimelineView: View {
    @Bindable var trimmer: TrimEditor
    var playhead: Double
    var isPlaying: Bool
    var zoom: Double
    var width: CGFloat
    var height: CGFloat
    var visibleWidth: CGFloat
    var onSeek: (Double) -> Void
    @State private var handleOriginX: CGFloat?
    @State private var hoverTime: Double?
    @State private var hoverX: CGFloat?

    private let edgePad: CGFloat = 10
    private let rulerHeight: CGFloat = 16
    private let handleWidth: CGFloat = 8

    var body: some View {
        let playX = xPosition(for: playhead, width: width)
        HorizontalTimelineScroll(
            contentWidth: width,
            contentHeight: height,
            playheadX: playX,
            visibleWidth: visibleWidth,
            isPlaying: isPlaying,
            zoom: zoom
        ) {
            tracks
        }
        .accessibilityLabel("Timeline")
    }

    private var tracks: some View {
        let filmHeight = max(height - rulerHeight - 4, 56)

        return ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                ruler(width: width)
                filmstrip(width: width, height: filmHeight)
                    .padding(.top, 2)
            }

            if trimmer.hasMovie, trimmer.duration > 0 {
                TrimSelectionOverlay(
                    startX: xPosition(for: trimmer.trimStart, width: width),
                    endX: xPosition(for: trimmer.trimEnd, width: width),
                    width: width,
                    height: filmHeight,
                    handleWidth: handleWidth,
                    onStartDrag: handleDrag(isStart: true, width: width),
                    onEndDrag: handleDrag(isStart: false, width: width)
                )
                .padding(.top, rulerHeight + 2)
                .zIndex(10)

                if let hoverTime, let hoverX {
                    HoverPreviewCard(time: hoverTime, image: trimmer.nearestFilmstrip(at: hoverTime))
                        .offset(x: min(max(hoverX - 70, 0), max(width - 140, 0)), y: -92)
                        .zIndex(20)
                        .allowsHitTesting(false)

                    Rectangle()
                        .fill(EditorChrome.selection.opacity(0.85))
                        .frame(width: 1.5, height: filmHeight)
                        .offset(x: hoverX - 0.75, y: rulerHeight + 2)
                        .allowsHitTesting(false)
                }

                PlayheadMark(time: playhead, height: filmHeight + 8)
                    .offset(x: xPosition(for: playhead, width: width) - 18)
                    .zIndex(12)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .contentShape(Rectangle())
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                guard trimmer.hasMovie, trimmer.duration > 0 else { return }
                hoverX = min(max(location.x, edgePad), width - edgePad)
                hoverTime = time(for: location.x, width: width)
                if !isPlaying, let hoverTime {
                    onSeek(hoverTime)
                }
            case .ended:
                hoverTime = nil
                hoverX = nil
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard trimmer.hasMovie, trimmer.duration > 0 else { return }
                    hoverTime = nil
                    onSeek(time(for: value.location.x, width: width))
                }
        )
    }

    private func ruler(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            ForEach(tickTimes(width: width), id: \.self) { tick in
                Text(EditorTime.clock(tick))
                    .font(.system(size: 9, weight: .medium).monospacedDigit())
                    .foregroundStyle(EditorChrome.faint)
                    .offset(x: xPosition(for: tick, width: width) - 10)
            }
        }
        .frame(width: width, height: rulerHeight, alignment: .leading)
    }

    private func filmstrip(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.04))

            if trimmer.filmstrip.isEmpty {
                Text(trimmer.hasMovie ? "Building filmstrip…" : "Record or drop a clip to trim here")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(EditorChrome.faint)
            } else {
                HStack(spacing: 1) {
                    ForEach(trimmer.filmstrip) { frame in
                        Image(nsImage: frame.image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func handleDrag(isStart: Bool, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if handleOriginX == nil {
                    handleOriginX = xPosition(
                        for: isStart ? trimmer.trimStart : trimmer.trimEnd,
                        width: width
                    )
                }
                let x = (handleOriginX ?? 0) + value.translation.width
                let seconds = time(for: x, width: width)
                if isStart {
                    trimmer.setTrimStart(seconds)
                    onSeek(trimmer.trimStart)
                } else {
                    trimmer.setTrimEnd(seconds)
                    onSeek(trimmer.trimEnd)
                }
            }
            .onEnded { _ in
                handleOriginX = nil
            }
    }

    private func tickTimes(width: CGFloat) -> [Double] {
        guard trimmer.duration > 0, width > 0 else { return [] }
        let usable = max(width - edgePad * 2, 1)
        let secondsPerPoint = trimmer.duration / usable
        let minInterval = max(secondsPerPoint * 40, 0.5)
        let nice = [0.5, 1.0, 2.0, 5.0, 10.0, 15.0, 30.0, 60.0, 120.0]
        let interval = nice.first(where: { $0 >= minInterval }) ?? 120
        var times: [Double] = []
        var tick = 0.0
        while tick <= trimmer.duration + 0.001 {
            times.append(tick)
            tick += interval
        }
        return times
    }

    private func time(for x: CGFloat, width: CGFloat) -> Double {
        let usable = max(width - edgePad * 2, 1)
        let unit = min(max((x - edgePad) / usable, 0), 1)
        return Double(unit) * trimmer.duration
    }

    private func xPosition(for seconds: Double, width: CGFloat) -> CGFloat {
        let usable = max(width - edgePad * 2, 1)
        return edgePad + CGFloat(seconds / max(trimmer.duration, 0.001)) * usable
    }
}

private struct HorizontalTimelineScroll<Content: View>: NSViewRepresentable {
    var contentWidth: CGFloat
    var contentHeight: CGFloat
    var playheadX: CGFloat
    var visibleWidth: CGFloat
    var isPlaying: Bool
    var zoom: Double
    @ViewBuilder var content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WheelHorizontalScrollView {
        let scroll = WheelHorizontalScrollView()
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = true
        scroll.hasVerticalScroller = false
        scroll.autohidesScrollers = true
        scroll.horizontalScrollElasticity = .allowed
        scroll.verticalScrollElasticity = .none
        scroll.scrollerStyle = .overlay
        scroll.borderType = .noBorder
        let host = NSHostingView(rootView: content())
        host.frame = NSRect(origin: .zero, size: CGSize(width: contentWidth, height: contentHeight))
        scroll.documentView = host
        context.coordinator.hosting = host
        return scroll
    }

    func updateNSView(_ scroll: WheelHorizontalScrollView, context: Context) {
        guard let host = context.coordinator.hosting else { return }
        host.rootView = content()
        host.frame = NSRect(origin: .zero, size: CGSize(width: max(contentWidth, visibleWidth), height: contentHeight))

        let zoomChanged = abs(context.coordinator.lastZoom - zoom) > 0.001
        if zoomChanged {
            context.coordinator.lastZoom = zoom
            revealPlayhead(in: scroll, force: true)
        } else if isPlaying {
            revealPlayhead(in: scroll, force: false)
        }
    }

    private func revealPlayhead(in scroll: NSScrollView, force: Bool) {
        let visible = scroll.documentVisibleRect
        guard visible.width > 1 else { return }
        let margin: CGFloat = 64
        let outOfView = playheadX < visible.minX + margin || playheadX > visible.maxX - margin
        guard force || outOfView else { return }
        let maxOffset = max(contentWidth - visible.width, 0)
        let target = min(max(playheadX - visible.width * 0.4, 0), maxOffset)
        scroll.contentView.scroll(to: NSPoint(x: target, y: visible.minY))
        scroll.reflectScrolledClipView(scroll.contentView)
    }

    final class Coordinator {
        var hosting: NSHostingView<Content>?
        var lastZoom = 1.0
    }
}

final class WheelHorizontalScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        let vertical = abs(event.scrollingDeltaY)
        let horizontal = abs(event.scrollingDeltaX)
        if vertical > horizontal, vertical > 0.05 {
            let factor: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 18
            var origin = documentVisibleRect.origin
            origin.x -= event.scrollingDeltaY * factor
            let maxX = max((documentView?.frame.width ?? 0) - documentVisibleRect.width, 0)
            origin.x = min(max(origin.x, 0), maxX)
            contentView.scroll(to: origin)
            reflectScrolledClipView(contentView)
            return
        }
        super.scrollWheel(with: event)
    }
}

private struct TrimSelectionOverlay<StartDrag: Gesture, EndDrag: Gesture>: View {
    var startX: CGFloat
    var endX: CGFloat
    var width: CGFloat
    var height: CGFloat
    var handleWidth: CGFloat
    var onStartDrag: StartDrag
    var onEndDrag: EndDrag

    var body: some View {
        let leading = min(max(startX, 0), width)
        let trailing = min(max(endX, 0), width)
        let selected = max(trailing - leading, 2)

        ZStack(alignment: .leading) {
            Color.black.opacity(0.5)
                .frame(width: leading, height: height)
                .allowsHitTesting(false)

            Color.black.opacity(0.5)
                .frame(width: max(width - trailing, 0), height: height)
                .offset(x: trailing)
                .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(EditorChrome.selection, lineWidth: 2)
                .frame(width: selected, height: height)
                .offset(x: leading)
                .allowsHitTesting(false)

            TrimEdgeHandle(height: height, width: handleWidth)
                .offset(x: leading - handleWidth / 2)
                .zIndex(16)
                .highPriorityGesture(onStartDrag)
                .accessibilityLabel("Trim in")

            TrimEdgeHandle(height: height, width: handleWidth)
                .offset(x: trailing - handleWidth / 2)
                .zIndex(16)
                .highPriorityGesture(onEndDrag)
                .accessibilityLabel("Trim out")
        }
        .frame(width: width, height: height, alignment: .leading)
        .clipped()
    }
}

private struct TrimEdgeHandle: View {
    var height: CGFloat
    var width: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(EditorChrome.selection)
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .frame(width: 3, height: 14)
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle().inset(by: -6))
        .shadow(color: EditorChrome.selection.opacity(0.35), radius: 2, y: 0)
    }
}

private struct HoverPreviewCard: View {
    var time: Double
    var image: NSImage?

    var body: some View {
        VStack(spacing: 4) {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 132, height: 78)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            Text(EditorTime.precise(time))
                .font(.system(size: 10, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(6)
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
    }
}

private struct PlayheadMark: View {
    var time: Double
    var height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Text(EditorTime.clock(time))
                .font(.system(size: 9, weight: .semibold).monospacedDigit())
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(EditorChrome.selection, in: Capsule())
            Rectangle()
                .fill(EditorChrome.selection)
                .frame(width: 2, height: max(height - 2, 36))
        }
        .frame(width: 36, alignment: .top)
        .shadow(color: EditorChrome.selection.opacity(0.35), radius: 3, y: 0)
    }
}

#Preview("EditorTimeline") {
    // Minimal mock dependencies for preview
    let studio = MockupStudio(previewOnly: true)
    let session = CaptureSession()
    let trimmer = TrimEditor()
    return EditorTimeline(
        trimmer: trimmer,
        studio: studio,
        session: session,
        onSeek: { _ in },
        onPlay: {},
        onSnapshot: {},
        onMuteToggle: {},
        onVolume: { _ in }
    )
    .frame(height: EditorChrome.timelineHeight)
    .background(Color.black)
}
