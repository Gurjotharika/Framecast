import Foundation

enum WebsiteURL {
    static func resolve(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), isAllowed(url) {
            return url
        }

        guard !trimmed.contains("://") else { return nil }
        return URL(string: "https://\(trimmed)").flatMap { isAllowed($0) ? $0 : nil }
    }

    private static func isAllowed(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        guard scheme == "http" || scheme == "https" else { return false }
        return url.host != nil
    }
}
