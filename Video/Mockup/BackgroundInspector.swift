import SwiftUI

struct BackgroundInspector: View {
    @Bindable var studio: MockupStudio

    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
    ]

    private let imageColumns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            backgroundTypeRow
            
            switch studio.backgroundKind {
                case .preset:
                    presetSettings
                case .solid:
                    solidSettings
                case .gradient:
                    gradientSettings
                case .image:
                    imageSettings
            }
            
        }
        .foregroundStyle(.white)
        .frame(maxWidth: 300)
    }
    
    @State private var showTypeList = false

    private var backgroundTypeRow: some View {
        HStack {
            Text("Type")
                .font(.callout)
                .fontWeight(.medium)

            Spacer()

            Button { showTypeList.toggle() } label: {
                HStack(spacing: 6) {
                    Text(studio.backgroundKind.title)
                        .lineLimit(1)
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
            .popover(isPresented: $showTypeList, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(BackgroundKind.allCases) { kind in
                        Button {
                            studio.backgroundKind = kind
                            showTypeList = false
                        } label: {
                            HStack {
                                Text(kind.title)
                                Spacer()
                                if kind == studio.backgroundKind {
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
            .accessibilityLabel("Background type")
            .accessibilityValue(studio.backgroundKind.title)
        }
    }

    private var presetSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Preset")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(EditorChrome.muted)
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(BackgroundLibrary.presets) { look in
                        LookCard(
                            title: look.name,
                            isSelected: studio.presetLookID == look.id,
                            isBlank: look.isBlank
                        ) {
                            studio.applyPresetLook(look)
                        } preview: {
                            (look.colors.first ?? .black).color
                        }
                    }
                }
            }
            
            InspectorSlider(
                title: "Corner radius",
                value: $studio.backgroundCornerRadius,
                range: 0...80,
                format: .pixels
            )
        }
    }

    private var solidSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Solid")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(EditorChrome.muted)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(BackgroundLibrary.solids) { look in
                    LookCard(
                        title: look.name,
                        isSelected: studio.solidLookID == look.id,
                        isBlank: look.isBlank
                    ) {
                        studio.applySolidLook(look)
                    } preview: {
                        (look.colors.first ?? .black).color
                    }
                }
            }
            
            InspectorColorField(title: "Custom color", color: $studio.solidColor)
                .onChange(of: studio.solidColor) { _, _ in
                    if !BackgroundLibrary.solids.contains(where: { $0.id == studio.solidLookID && $0.colors.first == studio.solidColor }) {
                        studio.solidLookID = "custom"
                    }
                }
            InspectorSlider(
                title: "Corner radius",
                value: $studio.backgroundCornerRadius,
                range: 0...80,
                format: .pixels
            )
        }
    }

    
    @State private var showCollectionList = false

    private var gradientSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            gradientCollection(title: "Colorful", collection: .colorful)
            gradientCollection(title: "Dark", collection: .dark)

            GradientEditor(studio: studio)
        }
    }

    private func gradientCollection(title: String, collection: GradientCollection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(EditorChrome.muted)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(BackgroundLibrary.gradients(in: collection)) { look in
                    LookCard(
                        title: look.name,
                        isSelected: studio.gradientLookID == look.id,
                        isBlank: look.isBlank
                    ) {
                        studio.applyGradientLook(look)
                    } preview: {
                        LinearGradient(
                            colors: look.colors.map(\.color),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            }
        }
    }

    private var imageSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: imageColumns, spacing: 10) {
                LookCard(
                    title: "Blank",
                    isSelected: studio.selectedBundledBackgroundID == nil && studio.selectedBackgroundImageID == nil,
                    isBlank: true
                ) {
                    studio.selectBackgroundImage(nil)
                } preview: {
                    Color.clear
                }
                
                ForEach(BackgroundLibrary.images) { item in
                    LookCard(
                        title: item.name,
                        isSelected: studio.selectedBundledBackgroundID == item.id,
                        isBlank: false
                    ) {
                        studio.selectBundledBackground(item)
                    } preview: {
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .overlay {
                                if let image = item.image {
                                    Image(nsImage: image)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Color.white.opacity(0.08)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                
                
                ForEach(studio.userBackgroundImages) { item in
                    LookCard(
                        title: item.name,
                        isSelected: studio.selectedBackgroundImageID == item.id,
                        isBlank: false
                    ) {
                        studio.selectBackgroundImage(item)
                    } preview: {
                        Image(nsImage: item.image)
                            .resizable()
                            .scaledToFill()
                    }
                }
            }

            Button {
                studio.chooseAndImportImage(kind: .background)
            } label: {
                Text("Add your image")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive())

            InspectorMenu(
                title: "Size",
                selection: $studio.imageFit,
                options: Array(ImageFitMode.allCases),
                optionTitle: \.title
            )
            
            InspectorSlider(title: "Scale", value: $studio.imageScale, range: 0.4...2.5, format: .percent)
            
            InspectorSlider(title: "Image blur", value: $studio.imageBlur, range: 0...40, format: .pixels)
            
            InspectorSlider(title: "Opacity", value: $studio.imageOpacity, range: 0...1, format: .percent)
            
            InspectorSlider(title: "Position X", value: $studio.imageOffsetX, range: -0.5...0.5)
            
            InspectorSlider(title: "Position Y", value: $studio.imageOffsetY, range: -0.5...0.5)
    
            InspectorSlider(
                title: "Corner radius",
                value: $studio.backgroundCornerRadius,
                range: 0...80,
                format: .pixels
            )
        }
    }
}

#Preview("Background inspector") {
    BackgroundInspector(studio: MockupStudio(previewOnly: true))
        .frame(width: 320)
        .padding()
        .background(EditorChrome.panel)
}
