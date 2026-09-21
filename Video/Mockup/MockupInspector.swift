import SwiftUI

struct MockupInspector: View {
    @Bindable var studio: MockupStudio
    @Bindable var session: CaptureSession

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(studio.inspectorTab.title)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                Divider()
                    .overlay(EditorChrome.stroke)

                ScrollView {
                    inspectorBody
                        .padding(14)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(EditorChrome.panel)

            Divider()
                .overlay(EditorChrome.stroke)

            VStack(spacing: 4) {
                ForEach(MockupInspectorTab.allCases) { tab in
                    InspectorRailButton(
                        tab: tab,
                        isSelected: studio.inspectorTab == tab
                    ) {
                        studio.showExportSettings = false
                        studio.inspectorTab = tab
                    }
                }
                Spacer()
            }
            .padding(.vertical, 10)
            .frame(width: EditorChrome.railWidth)
            .background(EditorChrome.rail)
        }
        .frame(width: 320)
        .background(EditorChrome.panel)
    }

    @ViewBuilder
    private var inspectorBody: some View {
        switch studio.inspectorTab {
        case .mockup:
            MockupCatalogPanel(studio: studio)
        case .background:
            BackgroundInspector(studio: studio)
        case .frame:
            FrameInspector(studio: studio)
        case .export:
            ExportInspector(studio: studio)
        }
    }
}

private struct InspectorRailButton: View {
    var tab: MockupInspectorTab
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: tab.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : EditorChrome.muted)
                .frame(width: 36, height: 36)
                .glassEffect(.regular.tint(isSelected ? EditorChrome.raised : Color.clear).interactive())
                .help(tab.title)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
        .buttonStyle(.plain)
       
    }
}

private struct MockupCatalogPanel: View {
    @Bindable var studio: MockupStudio
    
    private let columns = [
        GridItem(.flexible(minimum: 0), spacing: 10),
        GridItem(.flexible(minimum: 0), spacing: 10),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(filteredTemplates) { template in
                    MockupCatalogCard(
                        template: template,
                        isSelected: studio.isSelected(template)
                    ) {
                        studio.select(template)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                studio.chooseAndImportImage(kind: .mockup)
            } label: {
                Text("Add your image")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
    }
    
    private var filteredTemplates: [MockupTemplate] {
        MockupTemplate.catalog.filter { $0.matches(studio.catalogFilter) }
    }
    
    
    @Namespace private var filterNamespace
    
    private var filterBar: some View {
        HStack(spacing: 2) {
            ForEach(MockupCatalogFilter.allCases) { filter in
                let selected = studio.catalogFilter == filter
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        studio.catalogFilter = filter
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(EditorChrome.export)
                            .frame(width: 6, height: 6)
                            .opacity(selected ? 1 : 0)
                            .frame(width: selected ? 6 : 0)   // collapses the dot's space when unselected
                        Text(filter.title)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(selected ? Color.white : EditorChrome.muted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selected {
                            Capsule()
                                .fill(Color.white.opacity(0.10))
                                .matchedGeometryEffect(id: "filterPill", in: filterNamespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(filter.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(EditorChrome.raised, in: Capsule())
        .overlay(Capsule().strokeBorder(EditorChrome.stroke))
    }
}

private struct MockupCatalogCard: View {
    var template: MockupTemplate
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                    if template.isBlank {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                            .foregroundStyle(EditorChrome.stroke)
                        Text("Blank")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(EditorChrome.faint)
                    } else if let image = template.image {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(EditorChrome.faint)
                    }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isSelected ? EditorChrome.export : EditorChrome.stroke, lineWidth: isSelected ? 1.5 : 1)
                }
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(template.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(template.blurb)
                        .font(.system(size: 10))
                        .foregroundStyle(EditorChrome.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.stageframeGlass)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityLabel(template.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("MockupInspector") {
    let studio = MockupStudio(previewOnly: true)
    let session = CaptureSession()
    return MockupInspector(studio: studio, session: session)
        .frame(width: EditorChrome.inspectorWidth, height: 600)
        .background(Color.black)
}

#Preview("InspectorRailButton") {
    InspectorRailButton(tab: .mockup, isSelected: true, action: {})
        .padding()
        .background(Color.black)
}

#Preview("MockupCatalogPanel") {
    let studio = MockupStudio(previewOnly: true)
    return MockupCatalogPanel(studio: studio)
        .frame(width: 380, height: 500)
        .background(Color.black)
}

#Preview("MockupCatalogCard") {
    let template = MockupTemplate.fallback
    return MockupCatalogCard(template: template, isSelected: false, action: {})
        .frame(width: 220)
        .padding()
        .background(Color.black)
}

#Preview("ExportInspector") {
    let studio = MockupStudio(previewOnly: true)
    return ExportInspector(studio: studio)
        .frame(width: 320)
        .padding()
        .background(Color.black)
}
