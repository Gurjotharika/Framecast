import SwiftUI

struct RecordScreen: View {
    @Bindable var session: CaptureSession
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.plain)
                .symbolEffect(.bounce, value: session.isRecording == false)
                .disabled(session.isRecording)

                Text(session.loadedURL?.host ?? session.urlText)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                Spacer()
                
                if session.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(session.errorMessage ?? session.statusText)
                    .font(.system(size: 12))
                    .foregroundStyle(session.errorMessage == nil ? EditorChrome.muted : .red)
                    .lineLimit(1)
                
            }
            .padding(.leading, 24)
            .padding(.trailing, 16)
            .frame(height: EditorChrome.topBarHeight)
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

            ZStack {
                EditorChrome.canvas
                RecordSiteStage(session: session)
                    .padding(24)
                    .opacity(session.loadedURL == nil ? 0 : 1)

                if session.loadedURL == nil || session.isLoading {
                    VStack(spacing: 10) {
                        if session.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(session.loadedURL == nil ? "Loading your site…" : session.statusText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(EditorChrome.muted)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                HStack {
                    Toggle("Hide banners", isOn: $session.hideCookieBanners)
                        .toggleStyle(.checkbox)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: session.hideCookieBanners)
                        .disabled(session.isRecording)
                        .tint(.orange)
                    
                    Spacer()
                }
                
                if session.isRecording {
                    Button(role: .destructive) {
                        session.stopRecording()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .glassEffect(.regular.tint(.orange))
                            .keyboardShortcut("r", modifiers: [.command, .shift])
                            .symbolEffect(.pulse, value: session.isRecording)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        session.record()
                    } label: {
                        Label("Record", systemImage: "record.circle")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .glassEffect(.regular.tint(.orange))
                            .symbolEffect(.breathe, value: session.canRecord)
                            .disabled(!session.canRecord)
                            .keyboardShortcut("r", modifiers: [.command, .shift])
                    }
                    .buttonStyle(.plain)
                   
                }
                
                HStack {
                    Spacer()
                    
                    RecordSizePicker(session: session, compact: true)
                        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: session.isRecording)
                        .disabled(session.isRecording)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                GlassEffectContainer(spacing: 24) {
                    Color.clear
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 0))
                }
            }
        }
        .background(EditorChrome.canvas)
        .onAppear {
            session.lockRecordAspect()
            if session.loadedURL == nil {
                session.load()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: session.isRecording)
        .animation(.easeInOut(duration: 0.2), value: session.isLoading)
        .animation(.easeInOut(duration: 0.2), value: session.canRecord)
    }
}

#Preview("Record screen") {
    RecordScreen(session: CaptureSession(), onBack: {})
        .frame(width: 1100, height: 720)
}

private struct RecordSiteStage: View {
    @Bindable var session: CaptureSession

    var body: some View {
        GeometryReader { geo in
            let record = CGSize(
                width: CGFloat(session.recordWidth),
                height: CGFloat(session.recordHeight)
            )
            let scale = min(
                geo.size.width / max(record.width, 1),
                geo.size.height / max(record.height, 1)
            )
            let display = CGSize(width: record.width * scale, height: record.height * scale)

            SiteWebView(
                session: session,
                url: session.loadedURL,
                loadToken: session.loadToken,
                hideCookieBanners: session.hideCookieBanners,
                viewportWidth: session.recordWidth,
                viewportHeight: session.recordHeight,
                onStarted: session.didStart,
                onFinished: session.didFinish,
                onFailed: session.didFail
            )
            .frame(width: record.width, height: record.height)
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(
                        EditorChrome.export.opacity(session.isRecording ? 0.35 : 0.9),
                        lineWidth: 1.5 / max(scale, 0.001)
                    )
                    .allowsHitTesting(false)
            }
            .scaleEffect(scale, anchor: .center)
            .frame(width: display.width, height: display.height)
            .clipped()
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .animation(.easeInOut(duration: 0.2), value: session.recordWidth)
            .accessibilityLabel("Recording frame")
            .accessibilityValue(session.recordSizeLabel)
        }
    }
}
