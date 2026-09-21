import SwiftUI
import UniformTypeIdentifiers

struct EditorScreen: View {
    @Bindable var session: CaptureSession
    @Bindable var trimmer: TrimEditor
    @Bindable var studio: MockupStudio
    @Binding var isImportingMovie: Bool
    @Binding var isDropTargeted: Bool
    var onBack: () -> Void
    var onOpenDropped: (URL) -> Void

    var body: some View {
        VStack(spacing: 0) {
            EditorTopBar(
                studio: studio,
                clipName: clipName,
                onBack: onBack
            )

            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    EditorCanvas(
                        studio: studio,
                        statusText: statusText,
                        errorMessage: statusError,
                        isBusy: isBusy,
                        isImportingMovie: $isImportingMovie
                    )

                    EditorTimeline(
                        trimmer: trimmer,
                        studio: studio,
                        session: session,
                        onSeek: seekTimeline,
                        onPlay: togglePlay,
                        onSnapshot: snapshot,
                        onMuteToggle: { studio.isMuted.toggle() },
                        onVolume: { studio.volume = $0 }
                    )
                }

                Rectangle()
                    .fill(EditorChrome.stroke)
                    .frame(width: 1)

                MockupInspector(studio: studio, session: session)
            }
        }
        .background(EditorChrome.canvas)
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(EditorChrome.export, style: StrokeStyle(lineWidth: 3, dash: [10, 6]))
                    .padding(10)
                    .overlay {
                        Text("Drop MP4 or MOV")
                            .font(.title2.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(EditorChrome.bar.opacity(0.94), in: Capsule())
                    }
                    .allowsHitTesting(false)
            }
        }
        .onDrop(of: MovieImport.dropTypes, isTargeted: $isDropTargeted, perform: handleMovieDrop)
        .overlay {
            if studio.isExporting {
                ExportProgressDialog(studio: studio)
            }
        }
        .overlay {
            if studio.showFootagePosition {
                FootagePositionDialog(studio: studio)
            }
        }
        .overlay {
            if studio.showExportSettings && !studio.isExporting {
                ExportDialog(studio: studio)
            }
        }
        .onChange(of: trimmer.trimStart) { _, start in
            studio.applyTrim(start: start, end: trimmer.trimEnd)
        }
        .onChange(of: trimmer.trimEnd) { _, end in
            studio.applyTrim(start: trimmer.trimStart, end: end)
        }
    }

    private var clipName: String {
        if trimmer.hasMovie {
            return trimmer.clipName
        }
        return session.loadedURL?.host ?? "untitled"
    }

    private var statusText: String {
        if studio.isBusy {
            return studio.statusText
        }
        if trimmer.isExporting {
            return trimmer.statusText
        }
        return studio.statusText
    }

    private var statusError: String? {
        trimmer.errorMessage ?? studio.errorMessage
    }

    private var isBusy: Bool {
        trimmer.isExporting || studio.isBusy
    }

    private func seekTimeline(to seconds: Double) {
        trimmer.seek(to: seconds)
        if studio.hasVideo {
            studio.seek(to: seconds)
        }
    }

    private func togglePlay() {
        if studio.hasVideo {
            studio.togglePlay()
        } else {
            trimmer.togglePlay()
        }
    }

    private func snapshot() {
        studio.exportPNG()
    }

    private func handleMovieDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        let canLoad = MovieImport.dropTypes.contains { provider.hasItemConformingToTypeIdentifier($0.identifier) }
        guard canLoad else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?
            if let value = item as? URL {
                url = value
            } else if let value = item as? NSURL {
                url = value as URL
            } else if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else {
                url = nil
            }
            guard let url, MovieImport.isMovie(url) else { return }
            Task { @MainActor in
                onOpenDropped(url)
            }
        }
        return true
    }
}

private struct ExportProgressDialog: View {
    @Bindable var studio: MockupStudio

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Exporting video")
                    .font(.system(size: 16, weight: .semibold))
                Text(studio.exportProgressText.isEmpty ? "Rendering mockup…" : studio.exportProgressText)
                    .font(.system(size: 12))
                    .foregroundStyle(EditorChrome.muted)
                    .lineLimit(2)

                ProgressView(value: studio.exportProgress, total: 1)
                    .tint(EditorChrome.export)
                    .accessibilityLabel("Export progress")
                    .accessibilityValue("\(Int(studio.exportProgress * 100)) percent")

                Text("\(Int((studio.exportProgress * 100).rounded()))%")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(EditorChrome.muted)

                HStack {
                    Spacer()
                    Button("Cancel") {
                        studio.cancelExport()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(.regular.interactive())
                }
            }
            .padding(22)
            .frame(width: 360)
            .background(EditorChrome.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(EditorChrome.stroke)
            }
        }
        .allowsHitTesting(true)
    }
}

#Preview("Editor screen") {
    @Previewable @State var isImportingMovie = false
    @Previewable @State var isDropTargeted = false
    let session = CaptureSession()
    let trimmer = TrimEditor()
    let studio = MockupStudio(previewOnly: true)
    return EditorScreen(
        session: session,
        trimmer: trimmer,
        studio: studio,
        isImportingMovie: $isImportingMovie,
        isDropTargeted: $isDropTargeted,
        onBack: {},
        onOpenDropped: { _ in }
    )
    .frame(width: 1280, height: 800)
}
