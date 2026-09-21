import SwiftUI

struct GradientEditor: View {
    @Bindable var studio: MockupStudio
    @State private var showStyleList = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            typeRow
            
            GradientStopBar(studio: studio)

            if studio.gradientStyle == .radial {
                InspectorScrubField(
                    title: "Scale",
                    value: $studio.gradientScale,
                    range: 0.5...2.2,
                    format: .decimal,
                    step: 0.01
                )
            } else {
                InspectorScrubField(
                    title: "Angle",
                    value: $studio.gradientAngle,
                    range: 0...360,
                    format: .degrees
                )
            }

            stopList

            InspectorScrubField(
                title: "Corner radius",
                value: $studio.backgroundCornerRadius,
                range: 0...80,
                format: .pixels
            )
            
            Button("Reset all settings") {
                studio.resetGradientSettings()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(EditorChrome.muted)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
        }
    }
    
    @State private var hoveredStyle: GradientStyleKind?
    @State private var isTriggerHovered = false

    private var typeRow: some View {
        Button { showStyleList.toggle() } label: {
            HStack(spacing: 8) {
                Text(studio.gradientStyle.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(EditorChrome.muted)
                    .rotationEffect(.degrees(showStyleList ? 180 : 0))
                    .animation(.easeOut(duration: 0.15), value: showStyleList)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(EditorChrome.raised, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isTriggerHovered = $0 }
        .popover(isPresented: $showStyleList, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(GradientStyleKind.allCases) { style in
                    Button {
                        studio.gradientStyle = style
                        showStyleList = false
                    } label: {
                        HStack {
                            Text(style.title)
                                .font(.system(size: 13, weight: .medium))
                            Spacer(minLength: 12)
                            if style == studio.gradientStyle {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            hoveredStyle == style ? Color.white.opacity(0.08) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .onHover { hoveredStyle = $0 ? style : nil }
                }
            }
            .padding(6)
            .frame(minWidth: 180)
        }
        .accessibilityLabel("Gradient type")
        .accessibilityValue(studio.gradientStyle.title)
    }

    private var stopList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Stops")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(EditorChrome.muted)
                Spacer()
                Button {
                    studio.addGradientStop()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 22, height: 22)
                        .background(EditorChrome.raised, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(studio.gradientStops.count >= 8)
                .accessibilityLabel("Add stop")
            }

            ForEach(sortedStopIDs, id: \.self) { id in
                if let index = studio.gradientStops.firstIndex(where: { $0.id == id }) {
                    GradientStopRow(
                        stop: $studio.gradientStops[index],
                        canRemove: studio.gradientStops.count > 2
                    ) {
                        studio.removeGradientStop(studio.gradientStops[index])
                    }
                }
            }
        }
    }

    private var sortedStopIDs: [UUID] {
        studio.gradientStops.sorted { $0.location < $1.location }.map(\.id)
    }
}

private struct GradientStopBar: View {
    @Bindable var studio: MockupStudio

    private let thumbSize: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let travel = max(width - thumbSize, 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            stops: previewStops,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 14)
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    }
                    .contentShape(Capsule())
                    .onTapGesture { location in
                        studio.addGradientStop(at: min(max(Double((location.x - thumbSize / 2) / travel), 0), 1))
                    }

                ForEach(studio.gradientStops) { stop in
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay {
                            Circle()
                                .fill(stop.color.color)
                                .padding(2)
                        }
                        .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                        .offset(x: CGFloat(stop.location) * travel)
                        .gesture(
                            DragGesture(minimumDistance: 1, coordinateSpace: .named("gradientStopBar"))
                                .onChanged { drag in
                                    guard let index = studio.gradientStops.firstIndex(where: { $0.id == stop.id }) else {
                                        return
                                    }
                                    let x = min(max(drag.location.x - thumbSize / 2, 0), travel)
                                    studio.gradientStops[index].location = Double(x / travel)
                                }
                        )
                        .accessibilityLabel("Gradient stop")
                        .accessibilityValue("\(Int((stop.location * 100).rounded()))")
                }
            }
            .coordinateSpace(name: "gradientStopBar")
        }
        .frame(height: 16)
        .padding(.vertical, 8)
    }

    private var previewStops: [Gradient.Stop] {
        studio.gradientStops
            .sorted { $0.location < $1.location }
            .map { Gradient.Stop(color: $0.color.color, location: $0.location) }
    }
}

private struct GradientStopRow: View {
    @Binding var stop: GradientStopItem
    var canRemove: Bool
    var onRemove: () -> Void

    @State private var hexText = ""
    @State private var positionText = ""
    @State private var opacityText = ""
    @State private var showMenu = false

    var body: some View {
        HStack(spacing: 6) {
            compactField(text: $positionText, width: 36) {
                commitUnit(&positionText, current: stop.location) { stop.location = $0 }
            }

            Button {
                ColorPanelBridge.shared.show(initial: NSColor(colorBinding.wrappedValue)) { newColor in
                    colorBinding.wrappedValue = Color(nsColor: newColor)
                }
            } label: {
                RoundedRectangle(cornerRadius: 6)   // or RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(colorBinding.wrappedValue)
                    .frame(width: 18, height: 18)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(EditorChrome.stroke))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            
            TextField("Hex", text: $hexText)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium).monospaced())
                .foregroundStyle(.white.opacity(0.86))
                .onSubmit(commitHex)
                .accessibilityLabel("Stop hex")

            compactField(text: $opacityText, width: 36) {
                commitUnit(&opacityText, current: stop.color.a) { alpha in
                    stop.color.a = alpha
                }
            }

            Button {
                showMenu = false
                onRemove()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(EditorChrome.muted)
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .disabled(!canRemove)
            .accessibilityLabel("Stop actions")
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(EditorChrome.raised, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onAppear(perform: syncFields)
        .onChange(of: stop) { _, _ in
            syncFields()
        }
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { stop.color.color },
            set: { next in
                let parsed = RGBAColor(next)
                stop.color = RGBAColor(r: parsed.r, g: parsed.g, b: parsed.b, a: stop.color.a)
            }
        )
    }

    private func compactField(text: Binding<String>, width: CGFloat, commit: @escaping () -> Void) -> some View {
        TextField("", text: text)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .font(.system(size: 11, weight: .medium).monospacedDigit())
            .foregroundStyle(.white.opacity(0.86))
            .frame(width: width)
            .onSubmit(commit)
    }

    private func syncFields() {
        hexText = stop.color.hex
        positionText = String(Int((stop.location * 100).rounded()))
        opacityText = String(Int((stop.color.a * 100).rounded()))
    }

    private func commitHex() {
        if let updated = stop.color.replacingHex(hexText) {
            stop.color = updated
        }
        hexText = stop.color.hex
    }

    private func commitUnit(_ text: inout String, current: Double, update: (Double) -> Void) {
        if let parsed = Double(text.replacingOccurrences(of: "[^0-9.\\-]", with: "", options: .regularExpression)) {
            update(min(max(parsed / 100, 0), 1))
        } else {
            text = String(Int((current * 100).rounded()))
        }
    }
}

#Preview("Gradient editor") {
    GradientEditor(studio: MockupStudio(previewOnly: true))
        .padding()
        .frame(width: 292)
        .background(EditorChrome.panel)
}
