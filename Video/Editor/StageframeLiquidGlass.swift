import SwiftUI

struct StageframeGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .symbolEffect(.bounce, value: configuration.isPressed)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .stageframeGlassSurface(cornerRadius: 10, isInteractive: true)
            .animation(.smooth(duration: 0.16), value: configuration.isPressed)
    }
}

struct StageframeGlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .stageframeGlassSurface(cornerRadius: 8)
    }
}

extension ButtonStyle where Self == StageframeGlassButtonStyle {
    static var stageframeGlass: StageframeGlassButtonStyle {
        StageframeGlassButtonStyle()
    }
}

private struct StageframeGlassSurface: ViewModifier {
    let cornerRadius: CGFloat
    let isInteractive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(
                    isInteractive ? .regular.interactive() : .regular,
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14))
                }
        }
    }
}

extension View {
    func stageframeGlassSurface(
        cornerRadius: CGFloat = 10,
        isInteractive: Bool = false
    ) -> some View {
        modifier(
            StageframeGlassSurface(
                cornerRadius: cornerRadius,
                isInteractive: isInteractive
            )
        )
    }
}

extension TextFieldStyle where Self == StageframeGlassTextFieldStyle {
    static var stageframeGlass: StageframeGlassTextFieldStyle {
        StageframeGlassTextFieldStyle()
    }
}
