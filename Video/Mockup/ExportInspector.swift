import SwiftUI

struct ExportInspector: View {
    @Bindable var studio: MockupStudio

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ExportSettingsForm(studio: studio)

            exportVideoButton
        }
        .foregroundStyle(.white)
    }

    private var exportVideoButton: some View {
        Button {
            studio.openExportDialog()
        } label: {
            Label("Export", systemImage: "arrow.down.to.line")
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .glassEffect(.regular.tint(.orange).interactive())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("e", modifiers: [.command, .option])
        .help("Open export settings and estimated file size")
    }
}

struct ExportSettingsForm: View {
    @Bindable var studio: MockupStudio
    @State private var showResolutionList = false
    @State private var showRateList = false
    @State private var showScaleList = false
    @State private var showQualityList = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            resolutionSection

            if studio.exportPreset.isCustom {
                customSizeFields
            }

            formatPills

            HStack(spacing: 8) {
                compactMenu(
                    title: studio.exportFrameRate.title,
                    accessibilityLabel: "Frame rate"
                ) {
                    showRateList.toggle()
                }
                .popover(isPresented: $showRateList, arrowEdge: .bottom) {
                    optionList(ExportFrameRate.allCases, title: \.title, selected: studio.exportFrameRate) { rate in
                        studio.exportFrameRate = rate
                        showRateList = false
                    }
                }

                compactMenu(
                    title: studio.exportScale.title,
                    accessibilityLabel: "Scale"
                ) {
                    showScaleList.toggle()
                }
                .popover(isPresented: $showScaleList, arrowEdge: .bottom) {
                    optionList(ExportScale.allCases, title: \.title, selected: studio.exportScale) { scale in
                        studio.exportScale = scale
                        showScaleList = false
                    }
                }
            }

            compactMenu(
                title: studio.exportQuality.title,
                accessibilityLabel: "Quality"
            ) {
                showQualityList.toggle()
            }
            .popover(isPresented: $showQualityList, arrowEdge: .bottom) {
                optionList(ExportQuality.allCases, title: \.title, selected: studio.exportQuality) { quality in
                    studio.exportQuality = quality
                    showQualityList = false
                }
            }

            estimatedSizeCard
        }
        .foregroundStyle(.white)
    }

    private var resolutionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Resolution")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(EditorChrome.muted)

            Button { showResolutionList.toggle() } label: {
                HStack(spacing: 8) {
                    Text(resolutionTitle)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(EditorChrome.muted)
                }
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(EditorChrome.raised, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showResolutionList, arrowEdge: .bottom) {
                resolutionMenu
            }
            .accessibilityLabel("Resolution")
            .accessibilityValue(resolutionTitle)

            Text("Export \(studio.exportWidth) × \(studio.exportHeight) px")
                .font(.system(size: 12))
                .foregroundStyle(EditorChrome.muted)
        }
    }

    private var resolutionMenu: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(ExportSizeGroup.allCases) { group in
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(EditorChrome.muted)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    ForEach(ExportSizePreset.presets(in: group)) { preset in
                        Button {
                            studio.exportPreset = preset
                            showResolutionList = false
                        } label: {
                            HStack {
                                Text(menuTitle(for: preset))
                                Spacer()
                                if preset.id == studio.exportPreset.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(8)
        .frame(minWidth: 220)
    }

    private var customSizeFields: some View {
        HStack(spacing: 8) {
            TextField("Width", value: $studio.customWidth, format: .number)
                .textFieldStyle(.plain)
            Text("×")
                .foregroundStyle(EditorChrome.muted)
            TextField("Height", value: $studio.customHeight, format: .number)
                .textFieldStyle(.plain)
        }
        .font(.system(size: 13, weight: .medium).monospacedDigit())
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(EditorChrome.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("Custom size")
    }

    private var formatPills: some View {
        HStack(spacing: 0) {
            ForEach(ExportVideoFormat.allCases) { format in
                let selected = studio.exportFormat == format
                Button {
                    studio.exportFormat = format
                } label: {
                    Text(format.title.uppercased())
                        .font(.system(size: 11, weight: selected ? .semibold : .medium))
                        .foregroundStyle(selected ? Color.white : EditorChrome.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selected ? Color.white.opacity(0.10) : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(format.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(EditorChrome.raised, in: Capsule())
    }

    private var estimatedSizeCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Estimated size")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(EditorChrome.muted)
            Text(studio.estimatedExportSizeLabel)
                .font(.system(size: 18, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white)
            Text(estimateDetail)
                .font(.system(size: 11))
                .foregroundStyle(EditorChrome.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(EditorChrome.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Estimated size")
        .accessibilityValue("\(studio.estimatedExportSizeLabel). \(estimateDetail)")
    }

    private var estimateDetail: String {
        let size = "\(studio.exportWidth) × \(studio.exportHeight)"
        if studio.hasVideo {
            return "\(EditorTime.precise(studio.exportDuration)) · \(size) · \(studio.exportFormat.title)"
        }
        return "\(size) · \(studio.exportFormat.title)"
    }

    private var resolutionTitle: String {
        let preset = studio.exportPreset
        return "\(preset.chipTitle) — \(studio.exportBaseWidth) × \(studio.exportBaseHeight)"
    }

    private func menuTitle(for preset: ExportSizePreset) -> String {
        if preset.isCustom {
            return "Custom — \(studio.customWidth) × \(studio.customHeight)"
        }
        return "\(preset.chipTitle) — \(preset.width) × \(preset.height)"
    }

    private func compactMenu(title: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(EditorChrome.muted)
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(EditorChrome.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(title)
    }

    private func optionList<Value: Hashable>(
        _ options: [Value],
        title: KeyPath<Value, String>,
        selected: Value,
        action: @escaping (Value) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(options, id: \.self) { option in
                Button {
                    action(option)
                } label: {
                    HStack {
                        Text(option[keyPath: title])
                        Spacer()
                        if option == selected {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(minWidth: 140)
    }
}

#Preview("Export inspector") {
    ExportInspector(studio: MockupStudio(previewOnly: true))
        .padding()
        .frame(width: 292)
        .background(EditorChrome.panel)
}
