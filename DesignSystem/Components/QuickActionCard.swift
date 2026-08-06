import SwiftUI

/// A small, icon-led tappable card for a single quick action - "Inbox,"
/// "Tasks," "Travel." Extracted from a private type that had been
/// duplicated inside `HomeView`. Unlike the original, this version wraps
/// its content in a real `Button` (with an `action` closure) rather than
/// only looking tappable - the private version had `.isButton` trait
/// added without ever actually being interactive.
public struct QuickActionCard: View {
    private let symbolName: String
    private let title: String
    private let tint: Color
    private let action: () -> Void

    public init(
        symbolName: String,
        title: String,
        tint: Color = Color.LifePilot.accentEnd,
        action: @escaping () -> Void = {}
    ) {
        self.symbolName = symbolName
        self.title = title
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: symbolName)
                    .font(.system(size: IconSize.sm, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.14), in: Circle())

                Text(title)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm + Spacing.xs)
            .lifePilotGlass(cornerRadius: CornerRadius.md, isInteractive: true)
        }
        .buttonStyle(.lifePilotPressable)
        .accessibilityLabel(title)
        .accessibilityIdentifier("quickAction.\(title.lowercased())")
    }
}

#Preview {
    HStack(spacing: Spacing.sm) {
        QuickActionCard(symbolName: "envelope.fill", title: "Inbox")
        QuickActionCard(symbolName: "checklist", title: "Tasks")
        QuickActionCard(symbolName: "airplane", title: "Travel")
    }
    .padding()
}
