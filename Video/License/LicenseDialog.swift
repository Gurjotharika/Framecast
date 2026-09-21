import SwiftUI

struct LicenseDialog: View {
    @Bindable var access: AppAccessController
    @FocusState private var isKeyFocused: Bool
    @State private var selectedPlan: LicenseConfig.Plan = .onePC

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            card
        }
    }

    private var card: some View {
        VStack(spacing: 18) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)

            VStack(spacing: 6) {
                Text("Activate Framecast")
                    .font(.system(size: 22, weight: .semibold))
                Text("Unlock recording, mockups, and export on this Mac.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)
            }

            if access.isCheckingStoredKey {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Checking your license…")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.vertical, 28)
            } else {
                VStack(spacing: 8) {
                    ForEach(Self.features) { feature in
                        LicenseFeatureRow(feature: feature)
                    }
                }

                Button {
                    access.openPurchasePage(selectedPlan)
                } label: {
                    Text("Buy License")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(.white)
                        .glassEffect(.regular.tint(.orange).interactive())
                }
                .buttonStyle(.plain)

                alreadyPurchased
            }
        }
        .padding(.top, 28)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(width: 400)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(red: 0.07, green: 0.07, blue: 0.08).opacity(0.88))
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08))
        }
        .shadow(color: .black.opacity(0.45), radius: 40, y: 18)
    }

    private var alreadyPurchased: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)
                Text("ALREADY PURCHASED?")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.38))
                    .frame(width: 140)
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)
            }

            if let statusMessage = access.statusMessage {
                Text(statusMessage)
                    .font(.system(size: 11.5))
                    .foregroundStyle(access.statusIsError ? Color(red: 1, green: 0.45, blue: 0.4) : .white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                TextField(
                    "License key",
                    text: $access.licenseKey,
                    prompt: Text("Enter license key")
                )
                .font(.system(size: 12.5, design: .monospaced))
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .glassEffect(.regular)
                .focused($isKeyFocused)
                .disabled(access.isBusy)
                .onSubmit {
                    Task { await access.activateLicense() }
                }
                .accessibilityLabel("License key")

                Button {
                    Task { await access.activateLicense() }
                } label: {
                    HStack(spacing: 6) {
                        if access.isBusy {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(access.isBusy ? "…" : "Activate")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .foregroundStyle(.white.opacity(access.canActivate ? 1 : 0.45))
                    .glassEffect(.regular.tint(.orange).interactive())
                }
                .buttonStyle(.plain)
                .disabled(!access.canActivate)
                .keyboardShortcut(.defaultAction)
            }
        }
        .onAppear {
            isKeyFocused = true
        }
    }

    private static let features: [LicenseFeature] = [
        LicenseFeature(
            symbol: "link",
            title: "Record any website",
            detail: "Paste a URL and capture a clean 16:10 scroll of the page.",
            tint: Color(red: 0.22, green: 0.82, blue: 0.48)
        ),
        LicenseFeature(
            symbol: "laptopcomputer",
            title: "Device mockups",
            detail: "Drop the clip onto photographic Macs, displays, and studio scenes.",
            tint: Color(red: 0.62, green: 0.45, blue: 1)
        ),
        LicenseFeature(
            symbol: "square.and.arrow.up",
            title: "Export the shot",
            detail: "Ship MP4, MOV, GIF, or a still at the size you need.",
            tint: Color(red: 0.28, green: 0.62, blue: 1)
        ),
        LicenseFeature(
            symbol: "desktopcomputer",
            title: "1, 2, or 4 Macs",
            detail: "Pick a seat count. Framecast checks the key every launch.",
            tint: Color(red: 1, green: 0.42, blue: 0.38)
        )
    ]
}

private struct LicenseFeature: Identifiable {
    var id: String { title }
    var symbol: String
    var title: String
    var detail: String
    var tint: Color
}

private struct LicenseFeatureRow: View {
    var feature: LicenseFeature

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: feature.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(feature.tint)
                .frame(width: 32, height: 32)
                .background(feature.tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.system(size: 13, weight: .semibold))
                Text(feature.detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06))
        }
    }
}

#Preview("License dialog") {
    ZStack {
        EditorChrome.canvas
        LicenseDialog(access: .previewIdle)
    }
    .frame(width: 1100, height: 720)
    .preferredColorScheme(.dark)
}

#Preview("Checking license") {
    ZStack {
        EditorChrome.canvas
        LicenseDialog(access: .previewChecking)
    }
    .frame(width: 1100, height: 720)
    .preferredColorScheme(.dark)
}

#Preview("Invalid key") {
    ZStack {
        EditorChrome.canvas
        LicenseDialog(access: .previewInvalid)
    }
    .frame(width: 1100, height: 720)
    .preferredColorScheme(.dark)
}
