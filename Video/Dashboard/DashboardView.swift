import AppKit
import SwiftUI

struct DashboardView: View {
    var recents: [CaptureClip]
    var onCreate: () -> Void
    var onOpen: (CaptureClip) -> Void
    var onReveal: (CaptureClip) -> Void
    var onDuplicate: (CaptureClip) -> Void
    var onDelete: (CaptureClip) -> Void
    @State private var previews: [String: ClipCardPreview] = [:]
    @State private var clipToDelete: CaptureClip?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32)
                Text("Framecast")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button(action: onCreate) {
                    HStack(spacing: 4) {
                        Image(systemName: "record.circle")
                        
                        Text("Create new")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .glassEffect(.regular.tint(.orange).interactive())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Create new")
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
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

            if recents.isEmpty {
                emptyState
            } else {
                recentGrid
            }
        }
        .background(EditorChrome.canvas)
        .confirmationDialog(
            "Delete this recording?",
            isPresented: Binding(
                get: { clipToDelete != nil },
                set: { if !$0 { clipToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let clipToDelete {
                    onDelete(clipToDelete)
                }
                clipToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                clipToDelete = nil
            }
        } message: {
            Text("This removes the file from Stageframe’s library.")
        }
        .task(id: recents.map(\.id).joined(separator: "|")) {
            await loadPreviews()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            
            VStack(spacing: 8) {
                Image("record-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                
                
                Text("New product shot")
                    .font(.system(size: 28, weight: .semibold))
                Text("Record a website or open a clip you already have.")
                    .font(.system(size: 14))
                    .foregroundStyle(EditorChrome.muted)
            }
            
            Button(action: onCreate) {
                HStack {
                    Image(systemName: "record.circle")
                    
                    Text("Create new")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .glassEffect(.regular.tint(.orange).interactive())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var recentGrid: some View {
        GeometryReader { geo in
            let metrics = DashboardGridMetrics(containerWidth: geo.size.width)
            ScrollView {
                LazyVGrid(
                    columns: metrics.columns,
                    alignment: .leading,
                    spacing: DashboardGridMetrics.spacing
                ) {
                    ForEach(recents) { clip in
                        Button {
                            onOpen(clip)
                        } label: {
                            RecentClipCard(clip: clip, preview: previews[clip.id])
                        }
                        .buttonStyle(.plain)
                        .frame(width: metrics.cardWidth)
                        .clipped()
                        .accessibilityLabel(clip.name)
                        .contextMenu {
                            Button("Edit") { onOpen(clip) }
                            Button("Open in Finder") { onReveal(clip) }
                            Button("Duplicate") { onDuplicate(clip) }
                            Divider()
                            Button("Delete", role: .destructive) { clipToDelete = clip }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DashboardGridMetrics.padding)
            }
        }
    }

    private func loadPreviews() async {
        for clip in recents {
            if previews[clip.id] != nil { continue }
            let duration = await ClipPreview.duration(of: clip.url)
            let thumbnail = await ClipPreview.thumbnail(of: clip.url)
            previews[clip.id] = ClipCardPreview(duration: duration, thumbnail: thumbnail)
        }
    }
}

private struct DashboardGridMetrics {
    static let padding: CGFloat = 24
    static let spacing: CGFloat = 16
    static let minCard: CGFloat = 260

    var containerWidth: CGFloat

    var columnCount: Int {
        let available = max(containerWidth - Self.padding * 2, Self.minCard)
        return max(1, Int((available + Self.spacing) / (Self.minCard + Self.spacing)))
    }

    var cardWidth: CGFloat {
        let available = max(containerWidth - Self.padding * 2, Self.minCard)
        let gaps = Self.spacing * CGFloat(columnCount - 1)
        return floor((available - gaps) / CGFloat(columnCount))
    }

    var columns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(cardWidth), spacing: Self.spacing),
            count: columnCount
        )
    }
}

private struct ClipCardPreview {
    var duration: Double
    var thumbnail: NSImage?
}

private struct RecentClipCard: View {
    var clip: CaptureClip
    var preview: ClipCardPreview?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Color.clear
                .aspectRatio(16 / 10, contentMode: .fit)
                .overlay {
                    Group {
                        if let thumbnail = preview?.thumbnail {
                            Image(nsImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                        } else {
                            ZStack {
                                EditorChrome.raised
                                Image(systemName: "film")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(EditorChrome.muted)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(EditorChrome.stroke)
                }
                .overlay(alignment: .bottomTrailing) {
                    if let preview {
                        Text(EditorTime.clock(preview.duration))
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.62), in: Capsule())
                            .padding(8)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(clip.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(EditorTime.clock(preview?.duration ?? 0) + "  ·  " + clip.modified.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundStyle(EditorChrome.muted)
                    .lineLimit(1)
                Text(clip.pathDisplay)
                    .font(.system(size: 10).monospaced())
                    .foregroundStyle(EditorChrome.faint)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(clip.pathDisplay)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(EditorChrome.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(EditorChrome.stroke)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview("Dashboard") {
    DashboardView(
        recents: [],
        onCreate: {},
        onOpen: { _ in },
        onReveal: { _ in },
        onDuplicate: { _ in },
        onDelete: { _ in }
    )
    .frame(width: 1100, height: 720)
}

