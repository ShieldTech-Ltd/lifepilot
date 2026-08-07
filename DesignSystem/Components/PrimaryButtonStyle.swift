import SwiftUI

/// Native-feeling primary action with a solid adaptive foreground.
public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.LifePilot.body.weight(.semibold))
            .foregroundStyle(Color.LifePilot.controlPrimaryText)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm + Spacing.xs)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.LifePilot.controlPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .stroke(Color.LifePilot.glassBorder, lineWidth: 0.8)
            }
            .shadow(color: Color.black.opacity(0.14), radius: 8, y: 4)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Motion.quick, value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var lifePilotPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
