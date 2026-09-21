import AppKit
import SwiftUI

enum InspectorSliderSize {
    case compact
    case regular

    var height: CGFloat {
        switch self {
        case .compact: 32
        case .regular: 38
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: 12
        case .regular: 14
        }
    }

    var titleSize: CGFloat {
        switch self {
        case .compact: 10
        case .regular: 11
        }
    }

    var valueSize: CGFloat {
        switch self {
        case .compact: 11
        case .regular: 12
        }
    }

    var dividerHeight: CGFloat {
        switch self {
        case .compact: 12
        case .regular: 14
        }
    }
}

struct InspectorSlider: View {
    var title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var format: InspectorValueFormat = .decimal
    var step: Double = 0
    var valueString: ((Double) -> String)?
    var size: InspectorSliderSize = .compact

    @State private var isEditing = false
    @State private var draft = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(EditorChrome.raised)
                EditorChrome.export.opacity(0.36)
                    .frame(width: width * progress)
                Capsule()
                    .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)

                HStack(spacing: 0) {
                    Text(title.uppercased())
                        .font(.system(size: size.titleSize, weight: .medium))
                        .foregroundStyle(EditorChrome.muted)
                        .lineLimit(1)
                        .padding(.trailing, 8)

                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: size.dividerHeight)

                    Spacer(minLength: 8)

                    if isEditing {
                        TextField("", text: $draft)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.trailing)
                            .focused($fieldFocused)
                            .onSubmit(commitDraft)
                            .onExitCommand(perform: cancelDraft)
                    } else {
                        Text(displayValue)
                            .font(.system(size: size.valueSize, weight: .medium).monospacedDigit())
                            .foregroundStyle(.white)
                            .onTapGesture(count: 2, perform: beginEditing)
                    }
                }
                .padding(.horizontal, size.horizontalPadding)
            }
            .clipShape(Capsule())
            .contentShape(Capsule())
            .gesture(sliderGesture(width: width))
        }
        .frame(height: size.height)
        .onHover { hovering in
            if hovering, !isEditing {
                NSCursor.resizeLeftRight.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        .accessibilityLabel(title)
        .accessibilityValue(displayValue)
    }

    private var displayValue: String {
        valueString?(value) ?? format.string(value)
    }

    private var progress: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat(min(max((value - range.lowerBound) / span, 0), 1))
    }

    private func sliderGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                guard !isEditing else { return }
                apply(at: drag.location.x, width: width)
            }
    }

    private func apply(at x: CGFloat, width: CGFloat) {
        let unit = min(max(x / width, 0), 1)
        let span = range.upperBound - range.lowerBound
        let raw = range.lowerBound + Double(unit) * span
        let increment = step > 0 ? step : defaultStep
        let snapped = (raw / increment).rounded() * increment
        value = min(max(snapped, range.lowerBound), range.upperBound)
    }

    private var defaultStep: Double {
        switch format {
        case .percent, .decimal: 0.01
        case .precise: 0.0001
        case .degrees, .pixels: 1
        }
    }

    private func beginEditing() {
        draft = editableText
        isEditing = true
        fieldFocused = true
    }

    private func commitDraft() {
        let parsed = Double(draft.replacingOccurrences(of: "[^0-9.\\-]", with: "", options: .regularExpression))
        if let parsed {
            let raw = format == .percent ? parsed / 100 : parsed
            value = min(max(raw, range.lowerBound), range.upperBound)
        }
        isEditing = false
        fieldFocused = false
    }

    private func cancelDraft() {
        isEditing = false
        fieldFocused = false
    }

    private var editableText: String {
        switch format {
        case .percent: String(Int((value * 100).rounded()))
        case .degrees, .pixels: String(Int(value.rounded()))
        case .decimal: String(format: "%.2f", value)
        case .precise: String(format: "%.4f", value)
        }
    }
}

enum InspectorValueFormat {
    case decimal
    case precise
    case percent
    case degrees
    case pixels

    func string(_ value: Double) -> String {
        switch self {
        case .decimal:
            String(format: "%.2f", value)
        case .precise:
            String(format: "%.4f", value)
        case .percent:
            "\(Int((value * 100).rounded()))%"
        case .degrees:
            "\(Int(value.rounded()))°"
        case .pixels:
            String(format: "%.0f px", value)
        }
    }
}


final class ColorPanelBridge: NSObject {
    static let shared = ColorPanelBridge()
    private var onChange: ((NSColor) -> Void)?

    func show(initial: NSColor, onChange: @escaping (NSColor) -> Void) {
        self.onChange = onChange
        let panel = NSColorPanel.shared
        panel.showsAlpha = false
        panel.setTarget(nil)
        panel.setAction(nil)
        panel.color = initial                       // set before wiring the action
        panel.setTarget(self)
        panel.setAction(#selector(colorChanged(_:)))
        panel.orderFront(nil)
    }

    @objc private func colorChanged(_ sender: NSColorPanel) {
        onChange?(sender.color)
    }
}

struct InspectorColorField: View {
    var title: String
    @Binding var color: RGBAColor
    @State private var hexText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(EditorChrome.muted)
            
            HStack(spacing: 8) {
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
                .accessibilityLabel(title)
                
                TextField("Hex", text: $hexText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(
                Capsule()
                    .fill(.gray.opacity(0.15))
            )
            .backgroundStyle(.clear)
            .background(.clear)
            .onSubmit(of: .text, applyHex)
            .accessibilityLabel("Website URL")
        }
        .onAppear {
            hexText = color.hex
        }
        .onChange(of: color) { _, newValue in
            hexText = newValue.hex
        }
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { color.color },
            set: { color = RGBAColor($0) }
        )
    }

    private func applyHex() {
        if let parsed = RGBAColor(hex: hexText) {
            color = parsed
        } else {
            hexText = color.hex
        }
    }
}

struct InspectorMenu<Value: Hashable>: View {
    var title: String
    @Binding var selection: Value
    var options: [Value]
    var optionTitle: (Value) -> String

    @State private var isOpen = false
    @State private var hovered: Value?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(EditorChrome.muted)

            Button { isOpen.toggle() } label: {
                HStack(spacing: 6) {
                    Text(optionTitle(selection))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(EditorChrome.raised, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isOpen, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selection = option
                            isOpen = false
                        } label: {
                            HStack {
                                Text(optionTitle(option))
                                Spacer()
                                if option == selection {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                hovered == option ? Color.white.opacity(0.08) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .onHover { hovered = $0 ? option : nil }
                    }
                }
                .padding(6)
                .frame(minWidth: 160)
            }
            .accessibilityLabel(title)
            .accessibilityValue(optionTitle(selection))
        }
    }
}

struct InspectorScrubField: View {
    var title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var format: InspectorValueFormat = .decimal
    var step: Double = 0
    var size: InspectorSliderSize = .compact

    var body: some View {
        InspectorSlider(title: title, value: $value, range: range, format: format, step: step, size: size)
    }
}

struct InspectorIconButton: View {
    var systemImage: String
    var accessibilityLabel: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))
                .frame(width: 42, height: 42)
                .background(EditorChrome.raised, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct InspectorToggleBlock<Content: View>: View {
    var title: String
    @Binding var isOn: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Toggle(title, isOn: $isOn)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.small)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .tint(.orange)
                
                
            }
            
            if isOn {
                content()
            }
            
        }
    }
}

struct LookCard<Preview: View>: View {
    var title: String
    var isSelected: Bool
    var isBlank: Bool
    var action: () -> Void
    @ViewBuilder var preview: () -> Preview

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    Color.clear
                    if isBlank {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(EditorChrome.stroke)
                        Text("Blank")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(EditorChrome.faint)
                    } else {
                        preview()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    }
                }
                .aspectRatio(1.25, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(isSelected ? EditorChrome.export : EditorChrome.stroke, lineWidth: isSelected ? 1.5 : 1)
                }
                
                Text(title)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(isSelected ? Color.white : EditorChrome.muted)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Inspector controls") {
    @Previewable @State var value = 0.5
    @Previewable @State var color = RGBAColor.orange
    @Previewable @State var isOn = true
    VStack(alignment: .leading, spacing: 18) {
        InspectorSlider(title: "Opacity", value: $value, range: 0...1, format: .percent)
        InspectorColorField(title: "Accent", color: $color)
        
        InspectorMenu(title: "Quality", selection: $value, options: [0.25, 0.5, 1.0]) { quality in
            switch quality {
            case 0.25: "Low"
            case 0.5: "Medium"
            default: "High"
            }
        }
        
        InspectorToggleBlock(title: "Shadow", isOn: $isOn) {
            
        }
        LookCard(title: "Gradient", isSelected: true, isBlank: false, action: {}) {
            LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .frame(width: 140)
    }
    .padding()
    .frame(width: 300)
    .background(EditorChrome.panel)
}
