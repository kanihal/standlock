import SwiftUI

/// Items being rearranged, following the reference's stacked rows and movement arrows.
struct ReorganizeActionIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        var path = Path()
        for top in [3.0, 10.5, 18.0] {
            path.addRoundedRect(in: CGRect(x: 6, y: top, width: 12, height: 3.5),
                                cornerSize: CGSize(width: 1.25, height: 1.25))
        }
        path.move(to: CGPoint(x: 4, y: 13))
        path.addCurve(to: CGPoint(x: 4, y: 4), control1: CGPoint(x: 0, y: 10), control2: CGPoint(x: 0, y: 7))
        path.move(to: CGPoint(x: 1.1, y: 4.2))
        path.addLine(to: CGPoint(x: 4, y: 4))
        path.addLine(to: CGPoint(x: 3.4, y: 7.2))
        path.move(to: CGPoint(x: 20, y: 11))
        path.addCurve(to: CGPoint(x: 20, y: 20), control1: CGPoint(x: 24, y: 14), control2: CGPoint(x: 24, y: 17))
        path.move(to: CGPoint(x: 20.6, y: 16.8))
        path.addLine(to: CGPoint(x: 20, y: 20))
        path.addLine(to: CGPoint(x: 22.9, y: 19.8))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(translationX: rect.midX - 12 * scale, y: rect.midY - 12 * scale)))
    }
}
