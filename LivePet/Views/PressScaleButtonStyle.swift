import SwiftUI

/// Shared press scale for cream sheets, dock tiles, and Grow — kept after ConsolePanel removal.
struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.52), value: configuration.isPressed)
    }
}
