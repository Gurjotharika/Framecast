import SwiftUI

struct OnboardingView: View {
    var onContinue: () -> Void
    @State private var page: Int

    init(onContinue: @escaping () -> Void, initialPage: Int = 0) {
        self.onContinue = onContinue
        _page = State(initialValue: initialPage)
    }

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "Onboarding 1",
            title: "Record any website",
            body: "Paste a URL and Framecast captures a clean 16:10 scroll of the page — cookie banners optional."
        ),
        OnboardingPage(
            image: "Onboarding 2",
            title: "Drop it into a mockup",
            body: "Place the clip on photographic laptops and displays, then lock the screen to the device."
        ),
        OnboardingPage(
            image: "Onboarding 3",
            title: "Export the shot",
            body: "Pick size, format, and quality. Ship MP4, MOV, GIF, or a still."
        )
    ]

    var body: some View {
        let current = pages[page]

        VStack(spacing: 0) {

            Image(current.image)
                .resizable()
                .scaledToFill()
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .id(current.image)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            
            Spacer()

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(current.title)
                        .font(.system(size: 20, weight: .semibold))
                    Text(current.body)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(current.title)
                .transition(.opacity)
                
                Spacer()
                
                Button(action: advance) {
                    Text(page == pages.count - 1 ? "Get started" : "Continue")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(minWidth: 130)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.tint(.orange).interactive())
                }
                .buttonStyle(.plain)
                .tint(EditorChrome.export)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.vertical)
            
            Spacer()
        }
        .padding()
        .frame(width: 860, height: 720)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .background {
            Color.clear
                .contentShape(Rectangle())
                .gesture(WindowDragGesture())
        }
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation(.snappy(duration: 0.28)) {
                page += 1
            }
        } else {
            onContinue()
        }
    }
}

private struct OnboardingPage {
    var image: String
    var title: String
    var body: String
}

#Preview("Record") {
    OnboardingView(onContinue: {}, initialPage: 0)
}

#Preview("Mockup") {
    OnboardingView(onContinue: {}, initialPage: 1)
}

#Preview("Export") {
    OnboardingView(onContinue: {}, initialPage: 2)
}
