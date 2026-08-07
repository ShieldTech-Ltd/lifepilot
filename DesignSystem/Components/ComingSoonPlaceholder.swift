import SwiftUI

/// A shared full-screen placeholder retained for future, intentionally
/// unavailable surfaces. Core preview tabs use real local content.
public struct ComingSoonPlaceholder: View {
    private let symbolName: String
    private let title: String
    private let message: String

    public init(symbolName: String, title: String, message: String) {
        self.symbolName = symbolName
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: symbolName)
                .font(.system(size: IconSize.lg, weight: .medium))
                .foregroundStyle(LinearGradient.LifePilot.accent)
                .accessibilityHidden(true)

            Text(title)
                .font(.LifePilot.titleMedium)
                .foregroundStyle(Color.LifePilot.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(message)
                .font(.LifePilot.body)
                .foregroundStyle(Color.LifePilot.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.LifePilot.backgroundPrimary)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ComingSoonPlaceholder(
        symbolName: "brain.head.profile",
        title: "Memory",
        message: "LifePilot will remember your preferences, routines, and relationships here."
    )
}
