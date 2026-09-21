import SwiftUI

enum EditorChrome {
    static let canvas = Color(red: 0.047, green: 0.047, blue: 0.051)
    static let bar = Color(red: 0.078, green: 0.078, blue: 0.082)
    static let panel = Color(red: 0.090, green: 0.090, blue: 0.094)
    static let rail = Color(red: 0.070, green: 0.070, blue: 0.074)
    static let raised = Color.white.opacity(0.07)
    static let stroke = Color.white.opacity(0.10)
    static let muted = Color.white.opacity(0.48)
    static let faint = Color.white.opacity(0.28)
    static let export = Color(red: 1.0, green: 0.48, blue: 0.14)
    static let selection = Color(red: 1.0, green: 0.52, blue: 0.18)

    static let topBarHeight: CGFloat = 52
    static let inspectorWidth: CGFloat = 328
    static let railWidth: CGFloat = 52
    static let timelineHeight: CGFloat = 168
    static let trafficLightClearance: CGFloat = 78
}

enum EditorTime {
    static func clock(_ seconds: Double) -> String {
        let clamped = max(seconds, 0)
        let minutes = Int(clamped) / 60
        let secs = Int(clamped) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    static func precise(_ seconds: Double) -> String {
        let clamped = max(seconds, 0)
        let minutes = Int(clamped) / 60
        let remainder = clamped - Double(minutes * 60)
        return String(format: "%d:%04.1f", minutes, remainder)
    }
}
