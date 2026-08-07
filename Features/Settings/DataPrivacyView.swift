import Foundation
import LifePilotDesignSystem
import SwiftUI

public struct DataPrivacyView: View {
    @State private var didReset = false
    @State private var isShowingResetConfirmation = false
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
                    eyebrow: "Private by default",
                    title: "Data & privacy",
                    subtitle: "See the boundaries clearly and reset every local demo preference in one place."
                )

                CardContainer {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        privacyRow(
                            symbolName: "iphone.gen3",
                            title: "Local-first",
                            text: "Process on device wherever possible.",
                            color: .LifePilot.accentStart
                        )
                        privacyRow(
                            symbolName: "eye.slash.fill",
                            title: "Least privilege",
                            text: "Read only the context each feature needs.",
                            color: .LifePilot.accentEnd
                        )
                        privacyRow(
                            symbolName: "person.fill.checkmark",
                            title: "Explicit approval",
                            text: "Never execute an action without your decision.",
                            color: .LifePilot.signalSuccess
                        )
                    }
                }

                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label("Read the LifePilot privacy policy", systemImage: "doc.text.fill")
                        .font(.LifePilot.body.weight(.semibold))
                        .foregroundStyle(Color.LifePilot.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .lifePilotGlass(cornerRadius: CornerRadius.md, isInteractive: true)
                }
                .buttonStyle(.lifePilotPressable)
                .accessibilityIdentifier("privacy.policy")

                CardContainer {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Label("Local demo controls", systemImage: "internaldrive.fill")
                            .font(.LifePilot.titleMedium)
                            .foregroundStyle(Color.LifePilot.textPrimary)
                        Text(didReset
                            ? "Local preferences were reset. Relaunch the app to see onboarding again."
                            : "Reset profile edits, approvals, source switches, appearance, "
                                + "and onboarding on this device."
                        )
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)

                        Button(role: .destructive) {
                            isShowingResetConfirmation = true
                        } label: {
                            Label("Reset local demo data", systemImage: "arrow.counterclockwise")
                                .font(.LifePilot.body.weight(.semibold))
                                .foregroundStyle(Color.LifePilot.signalRisk)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(
                                    Color.LifePilot.signalRisk.opacity(0.1),
                                    in: RoundedRectangle(cornerRadius: CornerRadius.md)
                                )
                        }
                        .buttonStyle(.lifePilotPressable)
                        .accessibilityIdentifier("privacy.reset")
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .lifePilotScreenBackground(energy: .prominent)
        .navigationTitle("Privacy")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .confirmationDialog(
            "Reset the local demo?",
            isPresented: $isShowingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Demo Data", role: .destructive) { resetLocalDemoState() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This clears the profile, approval history, source switches, appearance, "
                    + "and onboarding status on this device."
            )
        }
    }

    private func privacyRow(symbolName: String, title: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: symbolName)
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.LifePilot.body.weight(.semibold))
                    .foregroundStyle(Color.LifePilot.textPrimary)
                Text(text)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
        }
    }

    private func resetLocalDemoState() {
        session.resetLocalDemoState()
        didReset = true
    }
}

#Preview {
    NavigationStack { DataPrivacyView() }
}
