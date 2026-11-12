import SwiftUI

/// A person putting folded items on a shelf.
struct ReorganizeActionIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        var path = Path()
        // Open shelving and the neatly stacked items already put away.
        for x in [14.5, 22.0] {
            path.addRoundedRect(in: CGRect(x: x, y: 2, width: 1.2, height: 20),
                                cornerSize: CGSize(width: 0.4, height: 0.4))
        }
        for y in [2.0, 9.7, 15.1, 20.8] {
            path.addRect(CGRect(x: 14.5, y: y, width: 8.7, height: 1.1))
        }
        for y in [12.2, 13.6, 18.0, 19.4] {
            path.addRoundedRect(in: CGRect(x: 17, y: y, width: 3.9, height: 1.1),
                                cornerSize: CGSize(width: 0.5, height: 0.5))
        }

        path.addEllipse(in: CGRect(x: 2.4, y: 1.3, width: 4, height: 4))
        path.move(to: CGPoint(x: 3.3, y: 6.5))
        path.addQuadCurve(to: CGPoint(x: 6.4, y: 7.6), control: CGPoint(x: 5.7, y: 6.1))
        path.addLine(to: CGPoint(x: 6.8, y: 14.6))
        path.addLine(to: CGPoint(x: 1.7, y: 14.6))
        path.addLine(to: CGPoint(x: 2.1, y: 8.1))
        path.addQuadCurve(to: CGPoint(x: 3.3, y: 6.5), control: CGPoint(x: 2.2, y: 6.6))
        path.closeSubpath()

        var legs = Path()
        legs.move(to: CGPoint(x: 3, y: 14))
        legs.addLine(to: CGPoint(x: 2.8, y: 22))
        legs.move(to: CGPoint(x: 5.6, y: 14))
        legs.addLine(to: CGPoint(x: 7.9, y: 18.1))
        legs.addLine(to: CGPoint(x: 6.7, y: 22))
        path = Path(path.cgPath.union(legs.strokedPath(
            StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)).cgPath))

        // The bent arm supports an item as it slides into the upper shelf.
        var arm = Path()
        arm.move(to: CGPoint(x: 5.6, y: 7.5))
        arm.addLine(to: CGPoint(x: 9, y: 10))
        arm.addLine(to: CGPoint(x: 15.5, y: 9))
        path = Path(path.cgPath.union(arm.strokedPath(
            StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round)).cgPath))
        var heldItems = Path()
        heldItems.addRoundedRect(in: CGRect(x: 16.7, y: 7.2, width: 4.2, height: 1.1),
                                 cornerSize: CGSize(width: 0.5, height: 0.5))
        heldItems.addRoundedRect(in: CGRect(x: 16.7, y: 8.4, width: 4.2, height: 1.1),
                                 cornerSize: CGSize(width: 0.5, height: 0.5))
        path = Path(path.cgPath.union(heldItems.cgPath))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(translationX: rect.midX - 12 * scale, y: rect.midY - 12 * scale)))
    }
}
