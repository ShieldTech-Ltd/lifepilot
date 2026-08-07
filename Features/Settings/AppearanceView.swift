import LifePilotDesignSystem
import SwiftUI

public struct AppearanceView: View {
    private let session: DemoSessionStore

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ScreenHeader(
                    eyebrow: "Your display",
                    title: "Appearance",
                    subtitle: "Choose how LifePilot looks. System follows your iPhone automatically."
                )

                HStack(spacing: Spacing.sm) {
                    ForEach(AppearancePreference.allCases) { preference in
                        Button {
                            withAnimation(Motion.standard) {
                                session.setAppearancePreference(preference)
                            }
                        } label: {
                            VStack(spacing: Spacing.sm) {
                                Image(systemName: preference.symbolName)
                                    .font(.system(size: 24, weight: .semibold))
                                Text(preference.title)
                                    .font(.LifePilot.caption)
                            }
                            .foregroundStyle(
                                session.appearancePreference == preference
                                    ? Color.LifePilot.controlPrimaryText
                                    : Color.LifePilot.textPrimary
                            )
                            .frame(maxWidth: .infinity, minHeight: 92)
                            .background {
                                if session.appearancePreference == preference {
                                    Color.LifePilot.controlPrimary
                                } else {
                                    Color.LifePilot.glassTint
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                    .stroke(Color.LifePilot.glassBorder, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.lifePilotPressable)
                        .accessibilityIdentifier("appearance.\(preference.rawValue)")
                    }
                }

                CardContainer {
                    HStack(spacing: Spacing.md) {
                        StatusOrbit(progress: 0.82, value: "82%", label: "Ready", size: 92)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Live preview")
                                .font(.LifePilot.titleMedium)
                                .foregroundStyle(Color.LifePilot.textPrimary)
                            Text("Glass surfaces, text, and accents adapt together for readable contrast.")
                                .font(.LifePilot.caption)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                        }
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .lifePilotScreenBackground(energy: .prominent)
        .navigationTitle("Appearance")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
