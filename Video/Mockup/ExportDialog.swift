import SwiftUI

struct ExportDialog: View {
    @Bindable var studio: MockupStudio

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
                .onTapGesture {
                    studio.showExportSettings = false
                }

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Export")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Review size, format, and the estimated file size before saving.")
                        .font(.system(size: 12))
                        .foregroundStyle(EditorChrome.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ScrollView {
                    ExportSettingsForm(studio: studio)
                }
                .frame(maxHeight: 520)
                .scrollIndicators(.hidden)

                HStack {
                    Button("Cancel") {
                        studio.showExportSettings = false
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .glassEffect(.regular.interactive())
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button {
                        studio.exportVideo()
                    } label: {
                        Text(studio.isExporting ? "Exporting…" : "Export \(studio.exportFormat.title)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .glassEffect(.regular.tint(.orange).interactive())
                    }
                    .buttonStyle(.plain)
                    .disabled(!studio.canExportVideo)
                    .keyboardShortcut(.defaultAction)
                    .help(studio.canExportVideo ? "Save the framed mockup video" : "Record or open a clip first")
                }
            }
            .padding(24)
            .frame(width: 420)
            .contentShape(Rectangle())
            .background(EditorChrome.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08))
            }
            .shadow(color: .black.opacity(0.45), radius: 40, y: 16)
        }
        .preferredColorScheme(.dark)
        .accessibilityAddTraits(.isModal)
    }
}

#Preview("Export dialog") {
    let studio = MockupStudio(previewOnly: true)
    studio.trimEnd = 4.2
    studio.exportFormat = .mp4
    return ExportDialog(studio: studio)
        .frame(width: 720, height: 720)
}
