import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppAccessController {
    enum Route: Equatable {
        case onboarding
        case workspace
    }

    var route: Route
    var isLicensed = false
    var licenseKey = ""
    var isBusy = false
    var isCheckingStoredKey = false
    var statusMessage: String?
    var statusIsError = false

    var needsLicenseDialog: Bool {
        route == .workspace && !isLicensed
    }

    var canActivate: Bool {
        !normalizedKey.isEmpty && !isBusy && !isCheckingStoredKey
    }

    var primaryActionTitle: String {
        if isBusy {
            return normalizedKey == StageframeMemory.licenseKey ? "Checking…" : "Activating…"
        }
        if statusIsError, normalizedKey == StageframeMemory.licenseKey {
            return "Try again"
        }
        return "Activate license"
    }

    init(validateOnLaunch: Bool = true) {
        licenseKey = StageframeMemory.licenseKey ?? ""
        if StageframeMemory.hasCompletedOnboarding {
            route = .workspace
            if validateOnLaunch {
                Task { await validateStoredKeyIfNeeded() }
            }
        } else {
            route = .onboarding
        }
    }

    func completeOnboarding() {
        StageframeMemory.hasCompletedOnboarding = true
        route = .workspace
        Task { await validateStoredKeyIfNeeded() }
    }

    func activateLicense() async {
        let key = normalizedKey
        guard !key.isEmpty else { return }
        guard LicenseConfig.isValidKeyFormat(key) else {
            fail(DodoLicenseError.malformedKey.localizedDescription)
            return
        }

        if key == StageframeMemory.licenseKey {
            await validateStoredKeyIfNeeded()
            return
        }

        isBusy = true
        statusMessage = nil
        statusIsError = false
        defer { isBusy = false }

        do {
            let instanceID = try await DodoLicenseClient.activate(
                licenseKey: key,
                deviceName: LicenseConfig.deviceName
            )
            store(key: key, instanceID: instanceID)
            unlockWorkspace()
        } catch DodoLicenseError.activationLimit {
            await recoverExistingActivation(key: key)
        } catch {
            fail(error.localizedDescription)
        }
    }

    func retryValidation() async {
        await validateStoredKeyIfNeeded()
    }

    func openPurchasePage(_ plan: LicenseConfig.Plan) {
        NSWorkspace.shared.open(plan.checkoutURL)
    }

    private var normalizedKey: String {
        LicenseConfig.normalizedKey(licenseKey)
    }

    private func validateStoredKeyIfNeeded() async {
        let key = LicenseConfig.normalizedKey(StageframeMemory.licenseKey ?? normalizedKey)
        guard !key.isEmpty else { return }
        guard LicenseConfig.isValidKeyFormat(key) else {
            fail(DodoLicenseError.malformedKey.localizedDescription)
            return
        }

        licenseKey = key
        isCheckingStoredKey = true
        statusMessage = nil
        statusIsError = false
        defer { isCheckingStoredKey = false }

        do {
            let valid = try await DodoLicenseClient.validate(
                licenseKey: key,
                instanceID: StageframeMemory.licenseInstanceID
            )
            if valid {
                StageframeMemory.licenseKey = key
                unlockWorkspace()
            } else {
                StageframeMemory.licenseInstanceID = nil
                fail("This license key is not valid.")
            }
        } catch {
            fail(error.localizedDescription)
        }
    }

    private func recoverExistingActivation(key: String) async {
        do {
            let valid = try await DodoLicenseClient.validate(licenseKey: key, instanceID: nil)
            if valid {
                store(key: key, instanceID: StageframeMemory.licenseInstanceID)
                unlockWorkspace()
            } else {
                fail(DodoLicenseError.activationLimit.localizedDescription)
            }
        } catch {
            fail(error.localizedDescription)
        }
    }

    private func store(key: String, instanceID: String?) {
        StageframeMemory.licenseKey = key
        StageframeMemory.licenseInstanceID = instanceID
        licenseKey = key
    }

    private func unlockWorkspace() {
        statusMessage = nil
        statusIsError = false
        isLicensed = true
        route = .workspace
    }

    private func fail(_ message: String) {
        isLicensed = false
        statusIsError = true
        statusMessage = message
        route = .workspace
    }
}

extension AppAccessController {
    static var previewIdle: AppAccessController {
        let access = AppAccessController(validateOnLaunch: false)
        access.route = .workspace
        access.isLicensed = false
        access.licenseKey = ""
        return access
    }

    static var previewChecking: AppAccessController {
        let access = previewIdle
        access.isCheckingStoredKey = true
        return access
    }

    static var previewInvalid: AppAccessController {
        let access = previewIdle
        access.licenseKey = "5be3115f-e678-4e7c-bc97-30fa1148ecbb"
        access.statusMessage = "This license key is not valid."
        access.statusIsError = true
        return access
    }
}
