import CoreGraphics
import QuartzCore

enum QuadHomography {
    /// Maps `from` (TL, TR, BR, BL) onto `to` (TL, TR, BR, BL).
    static func transform(from src: [CGPoint], to dst: [CGPoint]) -> CATransform3D {
        guard src.count == 4, dst.count == 4 else { return CATransform3DIdentity }

        var matrix = Array(repeating: Array(repeating: 0.0, count: 9), count: 8)
        for i in 0..<4 {
            let s = src[i]
            let d = dst[i]
            let sx = Double(s.x)
            let sy = Double(s.y)
            let dx = Double(d.x)
            let dy = Double(d.y)
            matrix[i * 2] = [sx, sy, 1, 0, 0, 0, -dx * sx, -dx * sy, dx]
            matrix[i * 2 + 1] = [0, 0, 0, sx, sy, 1, -dy * sx, -dy * sy, dy]
        }

        guard let solved = solve(matrix) else { return CATransform3DIdentity }
        var transform = CATransform3DIdentity
        transform.m11 = CGFloat(solved[0])
        transform.m12 = CGFloat(solved[3])
        transform.m13 = 0
        transform.m14 = CGFloat(solved[6])
        transform.m21 = CGFloat(solved[1])
        transform.m22 = CGFloat(solved[4])
        transform.m23 = 0
        transform.m24 = CGFloat(solved[7])
        transform.m31 = 0
        transform.m32 = 0
        transform.m33 = 1
        transform.m34 = 0
        transform.m41 = CGFloat(solved[2])
        transform.m42 = CGFloat(solved[5])
        transform.m43 = 0
        transform.m44 = 1
        return transform
    }

    static func transform(from rect: CGRect, to quad: [CGPoint]) -> CATransform3D {
        transform(
            from: [
                CGPoint(x: rect.minX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.maxY),
            ],
            to: quad
        )
    }

    private static func solve(_ input: [[Double]]) -> [Double]? {
        var a = input
        let rows = 8
        let cols = 9
        for col in 0..<rows {
            var pivot = col
            var best = abs(a[col][col])
            for row in (col + 1)..<rows {
                let value = abs(a[row][col])
                if value > best {
                    best = value
                    pivot = row
                }
            }
            if best < 1e-12 { return nil }
            if pivot != col {
                a.swapAt(pivot, col)
            }
            let diagonal = a[col][col]
            for j in col..<cols {
                a[col][j] /= diagonal
            }
            for row in 0..<rows where row != col {
                let factor = a[row][col]
                for j in col..<cols {
                    a[row][j] -= factor * a[col][j]
                }
            }
        }
        return (0..<8).map { a[$0][8] }
    }
}
