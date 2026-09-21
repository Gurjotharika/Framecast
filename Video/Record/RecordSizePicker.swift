import SwiftUI

enum RecordSizePreset: Int, CaseIterable, Identifiable {
    case wxga = 1280
    case wxgaPlus = 1440
    case wuxga = 1920
    case wqxga = 2560

    var id: Int { rawValue }

    var width: Int { rawValue }

    var height: Int { RecordAspect.height(for: width) }

    var title: String { "\(width)×\(height)" }

    var chipTitle: String { "\(width)" }

    static func matching(width: Int) -> RecordSizePreset {
        allCases.min(by: { abs($0.width - width) < abs($1.width - width) }) ?? .wxgaPlus
    }
}

struct RecordSizePicker: View {
    @Bindable var session: CaptureSession
    var compact = false

    var body: some View {
        Group {
            if compact {
                picker
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Size")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(EditorChrome.muted)
                        Spacer()
                        Text(sizeReadout)
                            .font(.system(size: 12, weight: .medium).monospacedDigit())
                            .foregroundStyle(.white.opacity(0.86))
                    }
                    picker
                }
            }
        }
        .accessibilityLabel("Recording size")
        .accessibilityValue(sizeReadout)
        .onAppear {
            session.lockRecordAspect()
        }
    }

    private var picker: some View {
        HStack(spacing: 0) {
            ForEach(RecordSizePreset.allCases) { format in
                let isSelected = (format == RecordSizePreset.matching(width: session.recordWidth))
                Button {
                    session.applyRecordPreset(format)
                } label: {
                    Text(format.title.uppercased())
                        .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? Color.white : EditorChrome.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(isSelected ? Color.white.opacity(0.10) : Color.clear, in: Capsule())
                }
                .disabled(session.isRecording)
                .buttonStyle(.plain)
                .accessibilityLabel(format.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(EditorChrome.raised, in: Capsule())
        
        
    }

    private var sizeReadout: String {
        "\(session.recordWidth)×\(session.recordHeight)  ·  16:10"
    }

    private var presetBinding: Binding<RecordSizePreset> {
        Binding(
            get: { RecordSizePreset.matching(width: session.recordWidth) },
            set: { session.applyRecordPreset($0) }
        )
    }
}

enum RecordAspect {
    static let ratio = 16.0 / 10.0
    static let minWidth = 640
    static let maxWidth = 2560

    static func height(for width: Int) -> Int {
        ExportSizePreset.evenPixel(Int((Double(width) / ratio).rounded()))
    }

    static func clampedWidth(_ width: Int) -> Int {
        min(max(ExportSizePreset.evenPixel(width), minWidth), maxWidth)
    }
}

#Preview("Record size picker") {
    RecordSizePicker(session: CaptureSession())
        .padding()
        .background(EditorChrome.panel)
}
