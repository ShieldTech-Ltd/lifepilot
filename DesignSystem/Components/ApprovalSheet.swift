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
        ZStack {
            AmbientBackground(energy: .subtle)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: content.sourceSymbolName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.LifePilot.accentStart)
                            .frame(width: 48, height: 48)
                            .background(Color.LifePilot.accentStart.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Prepared by")
                                .font(.LifePilot.caption)
                                .foregroundStyle(Color.LifePilot.textTertiary)
                            Text(content.sourceName)
                                .font(.LifePilot.body.weight(.semibold))
                                .foregroundStyle(Color.LifePilot.textPrimary)
                        }

                        Spacer()

                        Label(content.riskText, systemImage: "shield.checkered")
                            .font(.LifePilot.utility)
                            .foregroundStyle(Color.LifePilot.signalSuccess)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.LifePilot.signalSuccess.opacity(0.12), in: Capsule())
                    }

                    CardContainer {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(content.title)
                                .font(.LifePilot.titleMedium)
                                .foregroundStyle(Color.LifePilot.textPrimary)

                            Text(content.reasoning)
                                .font(.LifePilot.body)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                    }

                    Label(content.executionNote, systemImage: "wand.and.stars")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.accentEnd)
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lifePilotGlass(cornerRadius: CornerRadius.md, isInteractive: true)

                    VStack(spacing: Spacing.sm) {
                        Button("Approve prepared action", action: onApprove)
                            .buttonStyle(.lifePilotPrimary)
                            .accessibilityHint("Approves: \(content.title)")
                            .accessibilityIdentifier("approvalSheet.approve")

                        Button("Not now", action: onDismiss)
                            .buttonStyle(.lifePilotSecondary)
                            .accessibilityHint("Dismisses without taking action")
                            .accessibilityIdentifier("approvalSheet.dismiss")
                    }
                }
                .padding(Spacing.lg)
            }
        }
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
            executionNote: String = "Approval records a simulated result in this local preview."
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
