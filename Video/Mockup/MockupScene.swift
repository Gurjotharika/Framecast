import Foundation

enum MockupInspectorTab: String, CaseIterable, Identifiable {
    case mockup
    case background
    case frame
    case export

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mockup: "Mockup"
        case .background: "Background"
        case .frame: "Frame"
        case .export: "Export"
        }
    }

    var symbol: String {
        switch self {
        case .mockup: "rectangle.on.rectangle"
        case .background: "photo"
        case .frame: "display"
        case .export: "arrow.down.to.line"
        }
    }
}

enum MockupImportKind: String, Identifiable {
    case mockup
    case background

    var id: String { rawValue }
}
