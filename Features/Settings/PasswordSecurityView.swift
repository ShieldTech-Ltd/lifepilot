import LifePilotDesignSystem
import SwiftUI

/// A local, non-networked password-change demonstration for the preview.
/// The prototype records only the update date and never stores password text.
public struct PasswordSecurityView: View {
    @Environment(\.scenePhase) private var scenePhase
    private let session: DemoSessionStore
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?
    @State private var didUpdate = false

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public var body: some View {
        Form {
            Section {
                SecureField("Current password", text: $currentPassword)
                    .autocorrectionDisabled()
                    .privacySensitive()
                    .accessibilityIdentifier("password.current")
                SecureField("New password", text: $newPassword)
                    .autocorrectionDisabled()
                    .privacySensitive()
                    .accessibilityIdentifier("password.new")
                SecureField("Confirm new password", text: $confirmation)
                    .autocorrectionDisabled()
                    .privacySensitive()
                    .accessibilityIdentifier("password.confirmation")
            } header: {
                Text("Password")
            } footer: {
                Text(
                    "Do not enter a password you use anywhere else. Use at least eight characters "
                        + "of throwaway demo text. LifePilot never stores it."
                )
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.LifePilot.signalRisk)
                        .accessibilityIdentifier("password.error")
                }
            }

            if didUpdate {
                Section {
                    Label("Password updated for this demo account", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color.LifePilot.signalSuccess)
                        .accessibilityIdentifier("password.success")
                }
            }

            Section {
                Button("Update password") {
                    updatePassword()
                }
                .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmation.isEmpty)
                .accessibilityIdentifier("password.update")
            }

            Section("Account protection") {
                Label("Password text is never stored in this showcase", systemImage: "lock.shield.fill")
                Label("Your approval history remains on this device", systemImage: "iphone.gen3")
            }
        }
        .scrollContentBackground(.hidden)
        .background { AmbientBackground(energy: .prominent) }
        .navigationTitle("Password & Security")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onDisappear(perform: clearSensitiveFields)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                clearSensitiveFields()
            }
        }
    }

    private func updatePassword() {
        didUpdate = false
        errorMessage = nil

        guard newPassword.count >= 8 else {
            errorMessage = "The new password needs at least eight characters."
            return
        }
        guard newPassword != currentPassword else {
            errorMessage = "Choose a password different from the current one."
            return
        }
        guard newPassword == confirmation else {
            errorMessage = "The new passwords do not match."
            return
        }

        session.recordPasswordUpdate()
        currentPassword = ""
        newPassword = ""
        confirmation = ""
        didUpdate = true
    }

    private func clearSensitiveFields() {
        currentPassword = ""
        newPassword = ""
        confirmation = ""
    }
}

#Preview {
    NavigationStack {
        PasswordSecurityView(session: DemoSessionStore())
    }
}
