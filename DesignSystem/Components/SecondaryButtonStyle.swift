import SwiftUI

/// A lower-emphasis button style for secondary actions - dismiss, cancel,
/// "not now." Uses a flat elevated background rather than the brand
/// gradient, keeping the gradient reserved for primary actions.
public struct SecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.LifePilot.body.weight(.medium))
            .foregroundStyle(Color.LifePilot.textPrimary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm + Spacing.xs)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(.ultraThinMaterial)
            .background(Color.LifePilot.glassTint)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .stroke(Color.LifePilot.glassBorder, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Motion.quick, value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    public static var lifePilotSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
