import SwiftUI


struct CreateProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: CaptureSession
    @FocusState private var isURLFieldFocused: Bool
    var onRecordSite: () -> Void
    var onChooseRecording: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add your video")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Capture a website, or upload one you already have.")
                        .font(.system(size: 13))
                        .foregroundStyle(EditorChrome.muted)
                }

                Spacer(minLength: 8)

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.86))
                        .frame(width: 28, height: 28)
                        .background(EditorChrome.raised, in: Circle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .help("Close")
                .accessibilityLabel("Close")
            }

            VStack(alignment: .leading, spacing: 8) {
                
                HStack {
                    
                    Image(systemName: "link")
                    
                    TextField(
                        "Website URL",
                        text: $session.urlText,
                        prompt: Text("Enter your website URL")
                    )
                }
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.gray.opacity(0.15))
                )
                .backgroundStyle(.clear)
                .background(.clear)
                .focused($isURLFieldFocused)
                .onSubmit(of: .text, startRecord)
                .accessibilityLabel("Website URL")
                
                Toggle("Hide cookie banners", isOn: $session.hideCookieBanners)
                    .toggleStyle(.checkbox)
                    .padding(.vertical, 4)
                    .tint(.orange)
            }

            RecordSizePicker(session: session)

            Button(action: startRecord) {
                Text("Record this site")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .glassEffect(
                .regular
                    .tint(canRecordSite ? EditorChrome.export : EditorChrome.export.opacity(0.35))
                    .interactive(canRecordSite),
                in: Capsule()
            )
            .disabled(!canRecordSite)
            .keyboardShortcut(.return, modifiers: [.command])

            HStack {
                Rectangle().fill(EditorChrome.stroke).frame(height: 1)
                Text("or")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(EditorChrome.faint)
                Rectangle().fill(EditorChrome.stroke).frame(height: 1)
            }

            Button(action: chooseRecording) {
                Text("Upload your own video")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .glassEffect(
                .regular
                    .tint(EditorChrome.raised)
                    .interactive(),
                in: Capsule()
            )
            .disabled(session.isBusy)
        }
        .padding(24)
        .frame(width: 440)
        .background(EditorChrome.panel)
        .preferredColorScheme(.dark)
        .onAppear {
            isURLFieldFocused = true
            session.lockRecordAspect()
        }
    }

    private var canRecordSite: Bool {
        session.resolvedURL != nil && !session.isBusy
    }

    private func startRecord() {
        guard canRecordSite else { return }
        dismiss()
        onRecordSite()
    }

    private func chooseRecording() {
        guard !session.isBusy else { return }
        dismiss()
        onChooseRecording()
    }
}

#Preview("Create project") {
    CreateProjectSheet(
        session: CaptureSession(),
        onRecordSite: {},
        onChooseRecording: {}
    )
}
