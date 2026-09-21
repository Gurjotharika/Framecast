import Foundation
import UniformTypeIdentifiers

struct CaptureClip: Identifiable, Hashable {
    let url: URL
    let modified: Date

    var id: String { url.path }
    var name: String { url.deletingPathExtension().lastPathComponent }
    var pathDisplay: String { url.path }
}

enum CaptureLibrary {
    static var directory: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Stageframe/Captures", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    static var mediaDirectory: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Stageframe/Media", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    static func newCaptureURL(host: String?) -> URL {
        directory.appendingPathComponent(filename(host: host, suffix: "capture"))
    }

    static func importedURL(from source: URL) -> URL {
        directory.appendingPathComponent(filename(host: source.deletingPathExtension().lastPathComponent, suffix: "clip"))
    }

    static func keep(_ tempURL: URL, host: String?) throws -> URL {
        let destination = newCaptureURL(host: host)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }

    static func importMovie(_ source: URL) throws -> URL {
        let accessed = source.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                source.stopAccessingSecurityScopedResource()
            }
        }
        let destination = importedURL(from: source)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        do {
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            let data = try Data(contentsOf: source)
            try data.write(to: destination, options: .atomic)
        }
        return destination
    }

    static func importImage(_ source: URL, prefix: String) throws -> URL {
        let ext = source.pathExtension.isEmpty ? "png" : source.pathExtension
        let destination = mediaDirectory.appendingPathComponent(
            filename(host: prefix, suffix: "image").replacingOccurrences(of: ".mp4", with: ".\(ext)")
        )
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        do {
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            let data = try Data(contentsOf: source)
            try data.write(to: destination, options: .atomic)
        }
        return destination
    }

    static func duplicate(_ clip: CaptureClip) throws -> CaptureClip {
        let destination = directory.appendingPathComponent(
            filename(host: clip.name, suffix: "copy")
        )
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: clip.url, to: destination)
        return CaptureClip(url: destination, modified: Date())
    }

    static func delete(_ clip: CaptureClip) throws {
        try FileManager.default.removeItem(at: clip.url)
    }

    static func recents(limit: Int = 24) -> [CaptureClip] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return urls
            .filter { MovieImport.isMovie($0) }
            .map { url in
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return CaptureClip(url: url, modified: date)
            }
            .sorted { $0.modified > $1.modified }
            .prefix(limit)
            .map { $0 }
    }

    private static func filename(host: String?, suffix: String) -> String {
        let slug = (host ?? "site")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "-")
        let stamp = Int(Date().timeIntervalSince1970)
        return "\(slug)-\(suffix)-\(stamp).mp4"
    }
}
