import SwiftUI

struct FrameInspector: View {
    @Bindable var studio: MockupStudio

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Controls the video inside the mockup screen. The mockup itself stays locked on the canvas.")
                .font(.system(size: 12))
                .foregroundStyle(EditorChrome.muted)
                .fixedSize(horizontal: false, vertical: true)

            InspectorSlider(title: "Frame size", value: $studio.frameSize, range: 0.5...1.5, format: .percent)
            InspectorSlider(title: "X position", value: $studio.frameX, range: -0.3...0.3)
            InspectorSlider(title: "Y position", value: $studio.frameY, range: -0.3...0.3)

            InspectorMenu(
                title: "Fit mode",
                selection: $studio.footageFit,
                options: Array(FootageFitMode.allCases),
                optionTitle: \.title
            )

            //screenCorners

            cornerRadiusSection

            Button {
                studio.showFootagePosition = true
            } label: {
                Text("Footage position")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.tint(EditorChrome.export).interactive())
            .help("Open a dialog to pan and scale what shows inside the screen.")

            InspectorToggleBlock(title: "Border", isOn: $studio.borderEnabled) {
                InspectorColorField(title: "Color", color: $studio.borderColor)
                InspectorSlider(
                    title: "Width",
                    value: $studio.borderWidth,
                    range: 0.5...12,
                    format: .pixels
                )
            }

            InspectorToggleBlock(title: "Shadow", isOn: $studio.shadowEnabled) {
                VStack {
                    InspectorSlider(title: "Intensity", value: $studio.shadowIntensity, range: 0...1, format: .percent)
                    InspectorSlider(
                        title: "Corner radius",
                        value: $studio.shadowCornerRadius,
                        range: 0...80,
                        format: .pixels
                    )
                    InspectorSlider(
                        title: "Rotation",
                        value: $studio.shadowRotation,
                        range: -45...45,
                        format: .degrees
                    )
                    InspectorSlider(title: "Center X", value: $studio.shadowCenterX, range: -0.2...0.2)
                    InspectorSlider(title: "Center Y", value: $studio.shadowCenterY, range: -0.2...0.2)
                }
            }
        }
        .foregroundStyle(.white)
    }

    private var screenCorners: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Screen corners")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(EditorChrome.muted)
            Text("The clip should sit on the black display. If it drifts, click Snap to screen, then nudge TL TR BR BL.")
                .font(.system(size: 11))
                .foregroundStyle(EditorChrome.faint)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(ScreenCorner.allCases) { corner in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(corner.shortTitle)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(studio.selectedCorner == corner ? EditorChrome.export : EditorChrome.muted)
                            .frame(width: 22, alignment: .leading)
                        Text(corner.title)
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                    }
                    InspectorSlider(title: "X", value: studio.cornerX(corner), range: 0...1, format: .precise)
                    InspectorSlider(title: "Y", value: studio.cornerY(corner), range: 0...1, format: .precise)
                }
                .padding(10)
                .background(
                    studio.selectedCorner == corner ? EditorChrome.export.opacity(0.08) : EditorChrome.raised,
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .onTapGesture {
                    studio.selectedCorner = corner
                }
            }

            Button {
                studio.resetScreenCorners()
            } label: {
                Text("Snap to screen")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.black)
                    .background(EditorChrome.export, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.stageframeGlass)
            .help("Put the video back on the mockup display.")
        }
    }

    private var cornerRadiusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Corner radius")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(EditorChrome.muted)

            InspectorSlider(
                title: "All corners",
                value: $studio.overlayCorner,
                range: 0...64,
                format: .pixels
            )

            ForEach(ScreenCorner.allCases) { corner in
                InspectorSlider(
                    title: corner.title,
                    value: studio.cornerRadiusBinding(corner),
                    range: 0...64,
                    format: .pixels
                )
            }
        }
    }
}

#Preview("Frame inspector") {
    FrameInspector(studio: MockupStudio(previewOnly: true))
        .frame(width: 320)
        .padding()
        .background(EditorChrome.panel)
}
