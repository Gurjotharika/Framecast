import SwiftUI

struct RootView: View {
    @Bindable var access: AppAccessController

    var body: some View {
        Group {
            switch access.route {
            case .onboarding:
                OnboardingView(onContinue: access.completeOnboarding)
            case .workspace:
                ContentView()
                    .buttonStyle(.stageframeGlass)
                    .textFieldStyle(.stageframeGlass)
                    .frame(minWidth: 1100, minHeight: 720)
                    .overlay {
                        if access.needsLicenseDialog {
                            LicenseDialog(access: access)
                        }
                    }
            }
        }
        .preferredColorScheme(.dark)
        .background {
            AccessWindowFit(isCompact: access.route == .onboarding)
        }
    }
}
