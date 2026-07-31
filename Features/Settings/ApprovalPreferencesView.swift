import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Approval Preferences. The core guarantee — every action passes through
/// approval before it executes — isn't a setting a user can turn off; see
/// docs/ARCHITECTURE.md's Dependency Rule 4, "Execution is gated by
/// construction." The locked toggle below makes that guarantee visible
/// rather than configurable; the notification toggle beneath it is the one
/// real preference this screen owns.
public struct ApprovalPreferencesView: View {
    private let session: DemoSessionStore

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public init() {
        self.init(session: DemoSessionStore())
    }

    public var body: some View {
        List {
            Section {
                Toggle("Require approval before any action executes", isOn: .constant(true))
                    .disabled(true)
            } footer: {
                Text("This is a guarantee, not a setting — LifePilot never executes without your approval.")
            }

            Section("Risk Levels") {
                ForEach(RiskLevel.allCases, id: \.self) { level in
                    HStack(spacing: Spacing.md) {
                        SignalBadge(style: level == .low ? .success : .risk, text: level.rawValue.capitalized)
                        Text(description(for: level))
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }

            Section("Notifications") {
                Toggle(
                    "Notify me immediately for high-risk actions",
                    isOn: Binding(
                        get: { session.notifyOnHighRisk },
                        set: { session.setNotifyOnHighRisk($0) }
                    )
                )
            }
        }
        .navigationTitle("Approval Preferences")
    }

    private func description(for level: RiskLevel) -> String {
        switch level {
        case .low: "Reversible or informational — safe to approve quickly."
        case .medium: "Worth a second look before approving."
        case .high: "Review carefully — harder to undo."
        }
    }
}

#Preview {
    NavigationStack {
        ApprovalPreferencesView()
    }
}
