import SwiftUI

struct EditorCanvas: View {
    @Bindable var studio: MockupStudio
    var statusText: String
    var errorMessage: String?
    var isBusy: Bool
    @Binding var isImportingMovie: Bool

    var body: some View {
        ZStack {
            EditorChrome.canvas
            MockupPreview(studio: studio)

            VStack {
                HStack {
                    Spacer()
//                    Button {
//                        isImportingMovie = true
//                    } label: {
//                        Label("Replace footage", systemImage: "film.stack")
//                            .font(.system(size: 12, weight: .medium))
//                            .padding(.horizontal, 10)
//                            .padding(.vertical, 6)
//                            .background(.black.opacity(0.55), in: Capsule())
//                            .overlay {
//                                Capsule().strokeBorder(EditorChrome.stroke)
//                            }
//                    }
//                    .buttonStyle(.stageframeGlass)
//                    .padding(16)
//                    .help("Open another MP4 or MOV")
                }
                Spacer()
            }

            VStack {
                Spacer()
                HStack(spacing: 8) {
                    if isBusy {
                        ProgressView()
                            .controlSize(.small)
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .lineLimit(1)
                    } else {
                        Text(statusText)
                            .foregroundStyle(EditorChrome.muted)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

struct MockupPreview: View {
    @Bindable var studio: MockupStudio

    var body: some View {
        GeometryReader { geo in
            let canvas = MockupLayout.previewCanvas(for: studio.exportPixelSize, fitting: geo.size)
            ZStack {
                MockupLetterboxView(
                    studio: studio,
                    playsVideo: true,
                    canvas: canvas,
                    showsOverlayGuides: false
                )
                .frame(width: canvas.width, height: canvas.height)
                .clipped()
                .allowsHitTesting(false)

                if studio.inspectorTab == .frame {
                    FrameCornerEditor(studio: studio, canvas: canvas)
                        .coordinateSpace(name: "mockupFrame")
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

#Preview("Editor canvas") {
    @Previewable @State var isImportingMovie = false
    let studio = MockupStudio(previewOnly: true)
    return EditorCanvas(
        studio: studio,
        statusText: "Ready to export",
        errorMessage: nil,
        isBusy: false,
        isImportingMovie: $isImportingMovie
    )
    .frame(width: 900, height: 600)
}

#Preview("Mockup preview") {
    MockupPreview(studio: MockupStudio(previewOnly: true))
        .frame(width: 900, height: 600)
}
