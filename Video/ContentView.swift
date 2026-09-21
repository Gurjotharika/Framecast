import SwiftUI
import AppKit
import UniformTypeIdentifiers

private enum WorkspaceScreen {
    case dashboard
    case record
    case editor
}

private enum CreateSheet: String, Identifiable {
    case compose
    var id: String { rawValue }
}

struct ContentView: View {
    @State private var session = CaptureSession()
    @State private var trimmer = TrimEditor()
    @State private var studio = MockupStudio()
    @State private var screen: WorkspaceScreen = .dashboard
    @State private var createSheet: CreateSheet?
    @State private var recents: [CaptureClip] = []
    @State private var isImportingMovie = false
    @State private var isDropTargeted = false

    var body: some View {
        Group {
            switch screen {
            case .dashboard:
                DashboardView(
                    recents: recents,
                    onCreate: { createSheet = .compose },
                    onOpen: { clip in
                        Task { await openEditor(clip.url, securityScoped: false) }
                    },
                    onReveal: revealClip,
                    onDuplicate: duplicateClip,
                    onDelete: deleteClip
                )
            case .record:
                RecordScreen(session: session, onBack: goDashboard)
            case .editor:
                EditorScreen(
                    session: session,
                    trimmer: trimmer,
                    studio: studio,
                    isImportingMovie: $isImportingMovie,
                    isDropTargeted: $isDropTargeted,
                    onBack: goDashboard,
                    onOpenDropped: { url in
                        Task { await openEditor(url, securityScoped: true, copyIntoLibrary: true) }
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
        .buttonStyle(.stageframeGlass)
        .textFieldStyle(.stageframeGlass)
        .frame(minWidth: 1100, minHeight: 720)
        .sheet(item: $createSheet) { _ in
            CreateProjectSheet(
                session: session,
                onRecordSite: startRecording,
                onChooseRecording: scheduleImport
            )
        }
        .onAppear(perform: reloadRecents)
        .onChange(of: screen) { _, newScreen in
            if newScreen == .dashboard {
                reloadRecents()
            }
        }
        .onChange(of: session.lastVideoURL) { _, url in
            guard screen == .record, let url else { return }
            Task { await openEditor(url, securityScoped: false) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .stageframeOpenVideo)) { _ in
            isImportingMovie = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .stageframeNewProject)) { _ in
            createSheet = .compose
        }
        .fileImporter(
            isPresented: $isImportingMovie,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task { await openEditor(url, securityScoped: true, copyIntoLibrary: true) }
            case .failure(let error):
                trimmer.errorMessage = error.localizedDescription
                trimmer.statusText = "Could not open the video."
            }
        }
        .onDisappear {
            studio.pause()
            trimmer.unload()
        }
    }

    private func startRecording() {
        session.lastVideoURL = nil
        session.errorMessage = nil
        session.load()
        screen = .record
    }

    private func scheduleImport() {
        createSheet = nil
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(360))
            presentMovieImporter()
        }
    }

    private func presentMovieImporter() {
        let panel = NSOpenPanel()
        panel.title = "Upload your own video"
        panel.prompt = "Add Video"
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie]
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false

        let finish: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK, let url = panel.url else { return }
            Task { await openEditor(url, securityScoped: true, copyIntoLibrary: true) }
        }

        if let window = NSApp.keyWindow ?? NSApp.windows.first(where: \.isVisible) {
            panel.beginSheetModal(for: window, completionHandler: finish)
        } else {
            finish(panel.runModal())
        }
    }

    private func openEditor(_ url: URL, securityScoped: Bool, copyIntoLibrary: Bool = false) async {
        guard !session.isRecording, !trimmer.isExporting, !studio.isBusy else { return }
        studio.pause()
        let accessed = securityScoped && url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        var clipURL = url
        if copyIntoLibrary {
            do {
                clipURL = try CaptureLibrary.importMovie(url)
            } catch {
                trimmer.errorMessage = error.localizedDescription
                trimmer.statusText = "Could not copy the video into Stageframe."
                return
            }
        }
        await trimmer.load(clipURL, securityScoped: securityScoped && !copyIntoLibrary)
        await studio.refresh(from: session, trimmer: trimmer)
        screen = .editor
    }

    private func goDashboard() {
        session.stopRecording()
        studio.pause()
        screen = .dashboard
        reloadRecents()
    }

    private func reloadRecents() {
        recents = CaptureLibrary.recents()
    }

    private func revealClip(_ clip: CaptureClip) {
        NSWorkspace.shared.activateFileViewerSelecting([clip.url])
    }

    private func duplicateClip(_ clip: CaptureClip) {
        do {
            _ = try CaptureLibrary.duplicate(clip)
            reloadRecents()
        } catch {
            trimmer.errorMessage = error.localizedDescription
            trimmer.statusText = "Could not duplicate the clip."
        }
    }

    private func deleteClip(_ clip: CaptureClip) {
        do {
            try CaptureLibrary.delete(clip)
            reloadRecents()
        } catch {
            trimmer.errorMessage = error.localizedDescription
            trimmer.statusText = "Could not delete the clip."
        }
    }
}

#Preview {
    ContentView()
}
