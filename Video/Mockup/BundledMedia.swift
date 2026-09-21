import AppKit

enum BundledMedia {
    static func image(named fileName: String) -> NSImage? {
        let stem = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension

        if let named = NSImage(named: "bg-\(stem)") ?? NSImage(named: stem) {
            return named
        }

        let folders = [
            "Mockups/Backgrounds",
            "Mockups/Images",
            "Backgrounds",
            "Images",
            "Mockups",
        ]
        for folder in folders {
            if let url = Bundle.main.url(forResource: stem, withExtension: ext, subdirectory: folder),
               let image = NSImage(contentsOf: url) {
                return image
            }
        }

        if let url = Bundle.main.url(forResource: stem, withExtension: ext),
           let image = NSImage(contentsOf: url) {
            return image
        }

        if let match = matchInBundle(fileName), let image = NSImage(contentsOf: match) {
            return image
        }

        for relative in [
            "Mockups/Backgrounds/\(fileName)",
            "Mockups/Images/\(fileName)",
            "Mockups/\(fileName)",
        ] {
            let url = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent(relative)
            if FileManager.default.fileExists(atPath: url.path), let image = NSImage(contentsOf: url) {
                return image
            }
        }

        return nil
    }

    private static func matchInBundle(_ fileName: String) -> URL? {
        guard let root = Bundle.main.resourceURL else { return nil }
        let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        while let url = enumerator?.nextObject() as? URL {
            if url.lastPathComponent.compare(fileName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
                return url
            }
        }
        return nil
    }
}
