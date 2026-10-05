import SwiftUI

/// Tiny original pixel heart for Feeling meters. Not an SF Symbol.
public struct PixelHeartView: View {
    public var filled: Bool
    public var size: CGFloat

    public init(filled: Bool, size: CGFloat = 14) {
        self.filled = filled
        self.size = size
    }

    private let fill = Color(red: 1.0, green: 0.30, blue: 0.43)
    private let empty = Color(red: 1.0, green: 0.70, blue: 0.76)
    private let outline = Color(red: 0.55, green: 0.18, blue: 0.28)

    var body: some View {
        Canvas { ctx, canvasSize in
            let u = canvasSize.width / 7
            let color = filled ? fill : empty
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
                ctx.fill(
                    Path(CGRect(x: x * u, y: y * u, width: w * u, height: h * u)),
                    with: .color(color)
                )
            }
            func edge(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
                ctx.fill(
                    Path(CGRect(x: x * u, y: y * u, width: w * u, height: h * u)),
                    with: .color(outline.opacity(filled ? 0.85 : 0.45))
                )
            }
            // 7×6 heart silhouette
            rect(1, 1, 2, 1)
            rect(4, 1, 2, 1)
            rect(0, 2, 7, 2)
            rect(1, 4, 5, 1)
            rect(2, 5, 3, 1)
            edge(1, 0, 2, 1)
            edge(4, 0, 2, 1)
            edge(0, 1, 1, 3)
            edge(6, 1, 1, 3)
            edge(1, 5, 1, 1)
            edge(5, 5, 1, 1)
            edge(2, 6, 3, 1)
        }
        .frame(width: size, height: size * (6.0 / 7.0))
        .accessibilityHidden(true)
    }
}
