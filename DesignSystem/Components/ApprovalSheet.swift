import SwiftUI

/// Presents a recommended action with reasoning and approve/dismiss
/// controls, per docs/DESIGN_SYSTEM.md's Components table. This is the UI
/// expression of the Approve stage in README.md's Core Philosophy - nothing
/// reaches Execution without passing through a screen shaped like this one.
public struct ApprovalSheet: View {
    private let content: Content
    private let onApprove: () -> Void
    private let onDismiss: () -> Void

    public init(content: Content, onApprove: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.content = content
        self.onApprove = onApprove
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Label(content.sourceName, systemImage: content.sourceSymbolName)
                    Spacer()
                    Text(content.riskText)
                }
                .font(.LifePilot.caption.weight(.semibold))
                .foregroundStyle(Color.LifePilot.textSecondary)

                Text(content.title)
                    .font(.LifePilot.titleMedium)
                    .foregroundStyle(Color.LifePilot.textPrimary)

                Text(content.reasoning)
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
            .accessibilityElement(children: .combine)

            Label(content.executionNote, systemImage: "wand.and.stars")
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.accentEnd)
                .padding(Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.LifePilot.backgroundElevated, in: RoundedRectangle(cornerRadius: CornerRadius.sm))

            VStack(spacing: Spacing.sm) {
                Button("Approve", action: onApprove)
                    .buttonStyle(.lifePilotPrimary)
                    .accessibilityHint("Approves: \(content.title)")
                    .accessibilityIdentifier("approvalSheet.approve")

                Button("Dismiss", action: onDismiss)
                    .buttonStyle(.lifePilotSecondary)
                    .accessibilityHint("Dismisses without taking action")
                    .accessibilityIdentifier("approvalSheet.dismiss")
            }
        }
        .padding(Spacing.lg)
    }

    /// Plain view data for `ApprovalSheet`.
    public struct Content {
        public let title: String
        public let reasoning: String
        public let sourceName: String
        public let sourceSymbolName: String
        public let riskText: String
        public let executionNote: String

        public init(
            title: String,
            reasoning: String,
            sourceName: String = "Ghost Brain",
            sourceSymbolName: String = "sparkles",
            riskText: String = "Low risk",
            executionNote: String = "Approval records a simulated result for this TechFest demo."
        ) {
            self.title = title
            self.reasoning = reasoning
            self.sourceName = sourceName
            self.sourceSymbolName = sourceSymbolName
            self.riskText = riskText
            self.executionNote = executionNote
        }
    }
}
