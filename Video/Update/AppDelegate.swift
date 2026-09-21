import AppKit
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        updaterController.updater.automaticallyDownloadsUpdates = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [updater = updaterController.updater] in
            updater.checkForUpdatesInBackground()
        }
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
