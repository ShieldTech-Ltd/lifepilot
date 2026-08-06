import LifePilotDesignSystem
import SwiftUI

public struct PrivacyPolicyView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ScreenHeader(
                    eyebrow: "Effective 1 August 2026",
                    title: "Privacy policy",
                    subtitle: "How this LifePilot preview handles information on your device."
                )

                policySection(
                    title: "What LifePilot stores",
                    text: "Your profile details, preferences, approval history, imported events, and an optional "
                        + "profile photo are stored locally on your device. Widget and Share extension data uses "
                        + "LifePilot's private App Group."
                )
                policySection(
                    title: "Photos and screenshots",
                    text: "LifePilot can access only the photos you select. A profile photo is stored locally until "
                        + "you remove it or reset the app. Schedule screenshots are processed on device with Apple's "
                        + "text recognition, and the source image is not retained by LifePilot."
                )
                policySection(
                    title: "Collection and sharing",
                    text: "This preview does not transmit personal data to LifePilot, analytics providers, "
                        + "advertising networks, AI services, or other third parties. It does not track you across "
                        + "apps or websites. Connected sources use realistic demonstration data and do not access "
                        + "real accounts."
                )
                policySection(
                    title: "Retention and deletion",
                    text: "Local information remains until you remove it, reset local demo data in Settings, or "
                        + "uninstall LifePilot. Resetting clears profile edits, approval history, source switches, "
                        + "appearance, onboarding state, and imported events."
                )
                policySection(
                    title: "Your choices",
                    text: "You can pause any connected demo source, remove your profile photo, decline a prepared "
                        + "action, or reset all local data. LifePilot never sends, books, purchases, or acts outside "
                        + "the app without an explicit decision."
                )

                Link("tamimtarafder12@gmail.com", destination: supportEmailURL)
                    .font(.LifePilot.body.weight(.semibold))
                    .foregroundStyle(Color.LifePilot.accentStart)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .lifePilotGlass(cornerRadius: CornerRadius.md, isInteractive: true)
                    .accessibilityIdentifier("privacyPolicy.contact")
            }
            .padding(Spacing.lg)
        }
        .lifePilotScreenBackground(energy: .prominent)
        .navigationTitle("Privacy Policy")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var supportEmailURL: URL {
        URL(string: "mailto:tamimtarafder12@gmail.com?subject=LifePilot%20Privacy")!
    }

    private func policySection(title: String, text: String) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(title)
                    .font(.LifePilot.titleMedium)
                    .foregroundStyle(Color.LifePilot.textPrimary)
                Text(text)
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    NavigationStack { PrivacyPolicyView() }
}
