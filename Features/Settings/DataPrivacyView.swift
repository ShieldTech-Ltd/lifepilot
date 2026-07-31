import Foundation
import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Data & Privacy. States the product's real privacy commitments (see
/// docs/PRODUCT_VISION.md's "Privacy is a default, not a setting"
/// principle) and offers a genuinely functional reset of the local-only
/// state this phase has introduced — useful for demoing the app
/// repeatedly from a clean slate.
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
        List {
            Section("Our Commitment") {
                privacyRow(symbolName: "lock.fill", text: "On-device processing wherever possible.")
                privacyRow(symbolName: "eye.slash.fill", text: "Least-privilege integrations — LifePilot only reads what it needs.")
                privacyRow(symbolName: "person.fill.checkmark", text: "Nothing executes without your explicit approval.")
            }

            Section {
                Button(role: .destructive) {
                    isShowingResetConfirmation = true
                } label: {
                    Label("Reset Local Demo Data", systemImage: "arrow.counterclockwise")
                }
            } footer: {
                Text(didReset
                    ? "Local preferences were reset. Relaunch the app to see onboarding again."
                    : "Clears onboarding status, profile edits, and connected app toggles stored on this device.")
            }
        }
        .navigationTitle("Data & Privacy")
        .confirmationDialog(
            "Reset the local demo?",
            isPresented: $isShowingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Demo Data", role: .destructive) {
                resetLocalDemoState()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears the profile, approval history, source switches, and onboarding status on this device.")
        }
    }

    private func privacyRow(symbolName: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: symbolName)
                .foregroundStyle(LinearGradient.LifePilot.accent)
                .frame(width: 24)
            Text(text)
                .font(.LifePilot.body)
                .foregroundStyle(Color.LifePilot.textPrimary)
        }
    }

    private func resetLocalDemoState() {
        session.resetLocalDemoState()
        didReset = true
    }
}

#Preview {
    NavigationStack {
        DataPrivacyView()
    }
}
