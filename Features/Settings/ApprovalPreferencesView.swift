import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

public struct ApprovalPreferencesView: View {
    private let session: DemoSessionStore

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public init() {
        self.init(session: DemoSessionStore())
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ScreenHeader(
                    eyebrow: "Human in control",
                    title: "Approvals",
                    subtitle: "Understand the risk, review the reasoning, and decide what happens next."
                )

                CardContainer {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Color.LifePilot.signalSuccess)
                            .frame(width: 52, height: 52)
                            .background(Color.LifePilot.signalSuccess.opacity(0.13), in: Circle())
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Approval is always required")
                                .font(.LifePilot.body.weight(.semibold))
                                .foregroundStyle(Color.LifePilot.textPrimary)
                            Text("This safety guarantee cannot be switched off.")
                                .font(.LifePilot.caption)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                        }
                        Spacer()
                        Text("LOCKED")
                            .font(.LifePilot.utility)
                            .foregroundStyle(Color.LifePilot.signalSuccess)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    SectionHeader(title: "Risk guide", symbolName: "exclamationmark.shield.fill")
                    CardContainer {
                        VStack(spacing: Spacing.md) {
                            ForEach(RiskLevel.allCases, id: \.self) { level in
                                HStack(spacing: Spacing.md) {
                                    SignalBadge(style: level == .low ? .success : .risk, text: level.rawValue.capitalized)
                                    Text(description(for: level))
                                        .font(.LifePilot.caption)
                                        .foregroundStyle(Color.LifePilot.textSecondary)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    SectionHeader(title: "Notifications", symbolName: "bell.badge.fill")
                    CardContainer {
                        Toggle(
                            isOn: Binding(
                                get: { session.notifyOnHighRisk },
                                set: { session.setNotifyOnHighRisk($0) }
                            )
                        ) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("High-risk alerts")
                                    .font(.LifePilot.body.weight(.semibold))
                                    .foregroundStyle(Color.LifePilot.textPrimary)
                                Text("Notify me immediately when careful review is needed.")
                                    .font(.LifePilot.caption)
                                    .foregroundStyle(Color.LifePilot.textSecondary)
                            }
                        }
                        .tint(Color.LifePilot.signalSuccess)
                        .accessibilityIdentifier("approvals.highRiskNotifications")
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .lifePilotScreenBackground(energy: .prominent)
        .navigationTitle("Approvals")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func description(for level: RiskLevel) -> String {
        switch level {
        case .low: "Reversible or informational."
        case .medium: "Worth a second look before approving."
        case .high: "Review carefully because it is harder to undo."
        }
    }
}

#Preview {
    NavigationStack { ApprovalPreferencesView() }
}
