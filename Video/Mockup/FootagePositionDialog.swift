import AppKit
import SwiftUI

struct FootagePositionDialog: View {
    @Bindable var studio: MockupStudio
    @State private var scale: Double
    @State private var offsetX: Double
    @State private var offsetY: Double
    @State private var matte: RGBAColor
    @State private var hexText: String
    @State private var dragOrigin: CGSize?

    init(studio: MockupStudio) {
        self.studio = studio
        _scale = State(initialValue: studio.contentScale)
        _offsetX = State(initialValue: studio.contentOffsetX)
        _offsetY = State(initialValue: studio.contentOffsetY)
        _matte = State(initialValue: studio.footageMatte)
        _hexText = State(initialValue: studio.footageMatte.hex)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
                .onTapGesture {
                    studio.showFootagePosition = false
                }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Position your footage")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Drag to choose what shows inside the frame. The orange outline is the screen; anything outside it is cropped. Hold Shift to drag in a straight line. It snaps to the centre and edges; hold Ctrl or Cmd to move freely.")
                        .font(.system(size: 12))
                        .foregroundStyle(EditorChrome.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                preview
                    .frame(height: 340)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.06))
                    }


                HStack(alignment: .center, spacing: 16) {
                    scaleControl
                    Spacer(minLength: 12)
                    websiteColor
                }

                HStack {
                    Button {
                        resetDraft()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .glassEffect(.regular.interactive())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button("Cancel") {
                        studio.showFootagePosition = false
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .glassEffect(.regular.interactive())

                    Button {
                        save()
                    } label: {
                        Text("Save")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .glassEffect(.regular.tint(.orange).interactive())
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(24)
            .frame(width: 760)
            .contentShape(Rectangle())
            .background(EditorChrome.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08))
            }
            .shadow(color: .black.opacity(0.45), radius: 40, y: 16)
        }
        .preferredColorScheme(.dark)
    }

    private var preview: some View {
        GeometryReader { geo in
            let screen = screenRect(in: geo.size)
            ZStack {
                Color(red: 0.09, green: 0.09, blue: 0.1)
                matte.color
                    .frame(width: screen.width, height: screen.height)
                    .position(x: screen.midX, y: screen.midY)

                footage(in: screen)
                    .frame(width: geo.size.width, height: geo.size.height)

                Color.black.opacity(0.55)
                    .reverseMask {
                        Rectangle()
                            .frame(width: screen.width, height: screen.height)
                            .position(x: screen.midX, y: screen.midY)
                    }
                    .allowsHitTesting(false)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(EditorChrome.export, lineWidth: 2)
                    .frame(width: screen.width, height: screen.height)
                    .position(x: screen.midX, y: screen.midY)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let origin = dragOrigin ?? CGSize(width: offsetX, height: offsetY)
                        if dragOrigin == nil {
                            dragOrigin = origin
                        }
                        let flags = NSEvent.modifierFlags
                        var dx = value.translation.width / max(screen.width, 1)
                        var dy = value.translation.height / max(screen.height, 1)
                        if flags.contains(.shift) {
                            if abs(dx) > abs(dy) {
                                dy = 0
                            } else {
                                dx = 0
                            }
                        }
                        var nextX = origin.width + dx
                        var nextY = origin.height + dy
                        if !flags.contains(.command) && !flags.contains(.control) {
                            nextX = snap(nextX)
                            nextY = snap(nextY)
                        }
                        offsetX = min(max(nextX, -1.2), 1.2)
                        offsetY = min(max(nextY, -1.2), 1.2)
                    }
                    .onEnded { _ in
                        dragOrigin = nil
                    }
            )
            .accessibilityLabel("Footage position preview")
            .accessibilityHint("Drag to pan the footage inside the screen")
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.085))
    }

    @ViewBuilder
    private func footage(in screen: CGRect) -> some View {
        let image = studio.screenImage
        let fitted = footageRect(in: screen)
        Group {
            if let image {
                if studio.footageFit.stretches {
                    Image(nsImage: image)
                        .resizable()
                } else {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: studio.footageFit.usesFill ? .fill : .fit)
                }
            } else {
                Rectangle().fill(Color.white)
            }
        }
        .frame(width: fitted.width * scale, height: fitted.height * scale)
        .position(
            x: screen.midX + offsetX * screen.width,
            y: screen.midY + offsetY * screen.height
        )
    }

    private func footageRect(in screen: CGRect) -> CGRect {
        MockupLayout.aspectFit(
            studio.footagePixelSize,
            in: screen.size
        )
    }

    private var legendAndHint: some View {
        HStack {
            legendItem(color: EditorChrome.export, title: "Screen")
            legendItem(color: EditorChrome.muted, dashed: true, title: "Cropped footage")
            legendItem(color: .white, title: "Website background")
            Spacer()
            Text("Footage fills the screen. Dimmed areas are cropped out.")
                .font(.system(size: 11))
                .foregroundStyle(EditorChrome.muted)
        }
    }

    private func legendItem(color: Color, dashed: Bool = false, title: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(color, style: StrokeStyle(lineWidth: 1.4, dash: dashed ? [3, 2] : []))
                .background(dashed ? Color.clear : color.opacity(title == "Website background" ? 1 : 0))
                .frame(width: 11, height: 11)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(EditorChrome.muted)
        }
    }

    private var scaleControl: some View {
        InspectorSlider(
            title: "Scale",
            value: $scale,
            range: 0.5...3,
            format: .percent
        )
        .frame(width: 310)
    }

    private var websiteColor: some View {
        HStack(spacing: 8) {
            Text("Background Color")
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(EditorChrome.muted)
                .multilineTextAlignment(.trailing)
            
            TextField("Hex", text: $hexText)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 84)
                .onSubmit {
                    if let parsed = RGBAColor(hex: hexText) {
                        matte = parsed
                    } else {
                        hexText = matte.hex
                    }
                }
            
            ColorPicker("Website background", selection: Binding(
                get: { matte.color },
                set: { color in
                    matte = RGBAColor(color)
                    hexText = matte.hex
                }
            ), supportsOpacity: false)
            .labelsHidden()
            .frame(width: 28, height: 22)
            .stageframeGlassSurface(cornerRadius: 8, isInteractive: true)
        }
        .onChange(of: matte) { _, newValue in
            hexText = newValue.hex
        }
    }

    private func screenRect(in size: CGSize) -> CGRect {
        let ratio = max(studio.footageAspect, 0.05)
        let maxWidth = size.width * 0.72
        let maxHeight = size.height * 0.72
        var width = maxWidth
        var height = width / ratio
        if height > maxHeight {
            height = maxHeight
            width = height * ratio
        }
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }

    private func snap(_ value: Double) -> Double {
        let points = [0.0, -0.5, 0.5, -1.0, 1.0]
        if let match = points.first(where: { abs($0 - value) < 0.035 }) {
            return match
        }
        return value
    }

    private func resetDraft() {
        scale = 1
        offsetX = 0
        offsetY = 0
        matte = .white
        hexText = matte.hex
        dragOrigin = nil
    }

    private func save() {
        studio.contentScale = scale
        studio.contentOffsetX = offsetX
        studio.contentOffsetY = offsetY
        studio.footageMatte = matte
        studio.showFootagePosition = false
    }
}

private extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay {
                    mask()
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
        }
    }
}
#Preview("FootagePositionDialog") {
    let studio = MockupStudio(previewOnly: true)
    studio.footagePixelSize = CGSize(width: 1920, height: 1080)
    studio.footageMatte = .white
    studio.contentScale = 1
    studio.contentOffsetX = 0
    studio.contentOffsetY = 0
    return FootagePositionDialog(studio: studio)
        .frame(width: 800, height: 520)
}
