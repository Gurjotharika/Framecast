import SwiftUI

struct EditorTopBar: View {
    @Bindable var studio: MockupStudio
    var clipName: String
    var onBack: () -> Void
    @State private var showCustomSize = false

    var body: some View {
        HStack(spacing: 12) {
            
            brandChip
            Spacer()
            sizeChips
            exportButtons
        }
        .padding(.leading, 24)
        .padding(.trailing, 14)
        .frame(height: EditorChrome.topBarHeight)
        .background(EditorChrome.bar)
        .background {
            Color.clear
                .contentShape(Rectangle())
                .gesture(WindowDragGesture())
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(EditorChrome.stroke)
                .frame(height: 1)
        }
    }

    private var brandChip: some View {
        HStack(spacing: 4) {
            Button{
                onBack()
            } label: {
                Image(systemName: "house.fill")
                    .frame(width: 24, height: 18)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(EditorChrome.muted)
            
            Text("/")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(EditorChrome.muted)

            Text(clipName)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(EditorChrome.raised, in: Capsule())
        .accessibilityElement(children: .combine)
    }
    
    
    
    @State private var showSizeList = false

    private func selectPreset(_ preset: ExportSizePreset) {
        studio.exportPreset = preset
        showSizeList = false

        if preset.isCustom {
            // wait for the list popover to finish dismissing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showCustomSize = true
            }
        } else {
            showCustomSize = false
        }
    }

    private var sizeChips: some View {
        Button { showSizeList.toggle() } label: {
            HStack(spacing: 6) {
                Text(studio.exportPreset.chipTitle).lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(EditorChrome.raised, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        // Popover 1: the preset list
        .popover(isPresented: $showSizeList, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(ExportSizePreset.all) { preset in
                    Button {
                        selectPreset(preset)
                    } label: {
                        HStack {
                            Text(preset.chipTitle)
                            Spacer()
                            if preset == studio.exportPreset {
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
            .padding(6)
            .frame(width: 160)
        }
        // Popover 2: custom size, on a separate anchor so the two don't conflict
        .background {
            Color.clear
                .popover(isPresented: $showCustomSize, arrowEdge: .bottom) {
                    CustomSizePopover(studio: studio)
                }
        }
        .accessibilityLabel("Export size")
        .accessibilityValue(studio.exportPreset.chipTitle)
    }

    
    private var presetBinding: Binding<ExportSizePreset> {
        Binding(
            get: { studio.exportPreset },
            set: { preset in
                studio.exportPreset = preset
                showCustomSize = preset.isCustom
            }
        )
    }
    private var exportButtons: some View {
        HStack(spacing: 8) {
            Button {
                studio.openExportDialog()
            } label: {
                Text(studio.isExporting ? "Exporting…" : "Export")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .buttonStyle(.plain)
            .glassEffect(.regular.tint(studio.isBusy ? EditorChrome.export.opacity(0.35) : EditorChrome.export))
            .keyboardShortcut("e", modifiers: [.command, .option])
            .disabled(studio.isBusy)
            .help("Open export settings and estimated file size")
        }
    }
}

private struct CustomSizePopover: View {
    @Bindable var studio: MockupStudio

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom size")
                .font(.system(size: 12, weight: .semibold))
            HStack {
                TextField("Width", value: $studio.customWidth, format: .number)
                Text("×")
                TextField("Height", value: $studio.customHeight, format: .number)
            }
            .textFieldStyle(.stageframeGlass)
            .frame(width: 200)
            Text("Even pixels, 320–3840")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(14)
    }
}
#Preview("EditorTopBar") {
    let studio = MockupStudio(previewOnly: true)
    return EditorTopBar(studio: studio, clipName: "example.mov", onBack: {})
        .frame(height: EditorChrome.topBarHeight)
}

#Preview("CustomSizePopover") {
    let studio = MockupStudio(previewOnly: true)
    return CustomSizePopover(studio: studio)
        .padding()
        .frame(width: 220)
        .background(Color.black)
}
