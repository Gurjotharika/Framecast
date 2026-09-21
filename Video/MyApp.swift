import SwiftUI

public extension Dictionary
    where Key == NSApplication.AboutPanelOptionKey, Value == Any {

    static func framecast() -> Self {
        let center = NSMutableParagraphStyle()
        center.alignment = .center
        center.paragraphSpacing = 6

        let body: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.secondaryLabelColor,
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .paragraphStyle: center
        ]

        let credits = NSMutableAttributedString(
            string: "Turn any website into a launch-ready product video.\n"
                  + "Record a URL, place it on a Mac mockup, export MP4, MOV, GIF, or a still.\n\n"
                  + "Developed by ",
            attributes: body
        )

        var link = body
        link[.link] = URL(string: "https://x.com/jot_ui")!
        link[.foregroundColor] = NSColor.linkColor
        credits.append(NSAttributedString(string: "Pixels on X", attributes: link))

        var options: Self = [
            .applicationName: "Framecast",
            .credits: credits
        ]

        // Custom logo (optional): an Image Set named "FramecastLogo" in Assets.xcassets
        if let logo = NSImage(named: "logo") {
            options[.applicationIcon] = logo
        }

        return options
    }
}

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var access = AppAccessController()

    var body: some Scene {
        WindowGroup {
            RootView(access: access)
        }
        .defaultSize(
            access.route == .onboarding
                ? CGSize(width: 860, height: 720)
                : CGSize(width: 1440, height: 900)
        )
        .windowStyle(.hiddenTitleBar)
        .windowResizability(access.route == .onboarding ? .contentSize : .contentMinSize)
        .commands {
            
            CommandGroup(replacing: .appInfo) {
                Button("About Framecast") {
                    NSApplication.shared.orderFrontStandardAboutPanel(options: .framecast())
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            
            
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    appDelegate.checkForUpdates()
                }
            }

            CommandGroup(replacing: .newItem) {
                Button("New Capture") {
                    NotificationCenter.default.post(name: .stageframeNewProject, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                .disabled(!access.isLicensed)
                Button("Open Video") {
                    NotificationCenter.default.post(name: .stageframeOpenVideo, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command])
                .disabled(!access.isLicensed)
            }
        }
    }
}
