import Foundation

enum LicenseConfig {
    enum Environment: CaseIterable {
        case test
        case live

        var apiRoot: URL {
            switch self {
            case .test:
                URL(string: "https://test.dodopayments.com")!
            case .live:
                URL(string: "https://live.dodopayments.com")!
            }
        }

        var checkoutRoot: URL {
            switch self {
            case .test:
                URL(string: "https://test.checkout.dodopayments.com")!
            case .live:
                URL(string: "https://checkout.dodopayments.com")!
            }
        }

        var fallback: Environment {
            self == .test ? .live : .test
        }
    }

    /// Current Dodo account is test mode. Switch to `.live` for production keys.
    static let environment: Environment = .test

    static let keyPlaceholder = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

    enum Plan: String, CaseIterable, Identifiable {
        case onePC
        case twoPC
        case fourPC

        var id: String { rawValue }

        var productID: String {
            switch self {
            case .onePC: "pdt_0No0RWckDlYflQw2cR6jo"
            case .twoPC: "pdt_0No0RWevSU66TcuJoxoeM"
            case .fourPC: "pdt_0No0RWhGTl1cco5BbSAYI"
            }
        }

        var title: String {
            switch self {
            case .onePC: "1 PC"
            case .twoPC: "2 PCs"
            case .fourPC: "4 PCs"
            }
        }

        var priceLabel: String {
            switch self {
            case .onePC: "$49"
            case .twoPC: "$69"
            case .fourPC: "$99"
            }
        }

        var checkoutURL: URL {
            LicenseConfig.environment.checkoutRoot
                .appending(path: "buy")
                .appending(path: productID)
        }
    }

    static var deviceName: String {
        let host = ProcessInfo.processInfo.hostName.trimmingCharacters(in: .whitespacesAndNewlines)
        return host.isEmpty ? "Framecast Mac" : host
    }

    static func normalizedKey(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func isValidKeyFormat(_ key: String) -> Bool {
        let pattern = #"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"#
        return key.range(of: pattern, options: .regularExpression) != nil
    }
}
