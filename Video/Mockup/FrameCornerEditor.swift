import SwiftUI

struct FrameCornerEditor: View {
    @Bindable var studio: MockupStudio
    var canvas: CGSize

    private let handleSize: CGFloat = 28

    var body: some View {
        let corners = studio.mappedCorners(in: canvas)
        ZStack {
            QuadOutline(points: corners)
                .stroke(EditorChrome.selection, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .allowsHitTesting(false)

            ForEach(ScreenCorner.allCases) { corner in
                if corner.rawValue < corners.count {
                    let point = corners[corner.rawValue]
                    FrameCornerHandle(
                        corner: corner,
                        canvasPoint: point,
                        isSelected: studio.selectedCorner == corner
                    ) { next in
                        studio.selectedCorner = corner
                        studio.moveMappedCorner(corner, to: next, in: canvas)
                    }
                    .frame(width: handleSize, height: handleSize)
                    .position(x: point.x, y: point.y)
                }
            }
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipped()
        .coordinateSpace(name: "mockupFrame")
        .allowsHitTesting(true)
    }
}

private struct FrameCornerHandle: View {
    var corner: ScreenCorner
    var canvasPoint: CGPoint
    var isSelected: Bool
    var onMove: (CGPoint) -> Void

    @State private var dragOrigin: CGPoint?

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? EditorChrome.export : Color.white)
                .frame(width: isSelected ? 14 : 12, height: isSelected ? 14 : 12)
                .overlay {
                    Circle()
                        .strokeBorder(isSelected ? Color.white : EditorChrome.export, lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
            Text(corner.shortTitle)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.65), in: Capsule())
                .offset(y: -18)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("mockupFrame"))
                .onChanged { value in
                    let origin = dragOrigin ?? canvasPoint
                    if dragOrigin == nil {
                        dragOrigin = origin
                    }
                    onMove(CGPoint(
                        x: origin.x + value.translation.width,
                        y: origin.y + value.translation.height
                    ))
                }
                .onEnded { _ in
                    dragOrigin = nil
                }
        )
        .accessibilityLabel("\(corner.title) screen corner")
        .accessibilityHint("Drag to align this corner of the video frame")
    }
}

#Preview("Frame corner editor") {
    FrameCornerEditor(
        studio: MockupStudio(previewOnly: true),
        canvas: CGSize(width: 640, height: 360)
    )
    .background(EditorChrome.canvas)
}
