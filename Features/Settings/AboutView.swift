import Foundation
import LifePilotDesignSystem
import SwiftUI

public struct AboutView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                Image("LifePilotLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: Color.LifePilot.accentEnd.opacity(0.3), radius: 24, y: 12)
                    .accessibilityLabel("LifePilot logo")

                VStack(spacing: Spacing.sm) {
                    Text("LifePilot")
                        .font(.LifePilot.titleLarge)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    Text("Student-first. Built to grow with everyone.")
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                        .multilineTextAlignment(.center)
                    Text(versionLabel)
                        .font(.LifePilot.utility)
                        .foregroundStyle(Color.LifePilot.accentStart)
                }

                CardContainer {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        aboutRow(
                            symbol: "brain.head.profile",
                            title: "Context, not clutter",
                            detail: "One briefing across timetable, inbox, travel, and spending."
                        )
                        aboutRow(
                            symbol: "checkmark.shield.fill",
                            title: "You approve every action",
                            detail: "LifePilot prepares the next step and waits for your decision."
                        )
                        aboutRow(
                            symbol: "lock.fill",
                            title: "Private by design",
                            detail: "The showcase uses local demo data and does not connect to real accounts."
                        )
                    }
                }

                Link("tamimtarafder12@gmail.com", destination: supportEmailURL)
                    .font(.LifePilot.body.weight(.semibold))
                    .foregroundStyle(Color.LifePilot.accentStart)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .lifePilotGlass(cornerRadius: CornerRadius.md, isInteractive: true)
                    .accessibilityLabel("Email LifePilot support at tamimtarafder12@gmail.com")
            }
            .padding(Spacing.lg)
        }
        .lifePilotScreenBackground(energy: .prominent)
        .navigationTitle("About")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var versionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "TechFest build \(version) (\(build))"
    }

    private var supportEmailURL: URL {
        URL(string: "mailto:tamimtarafder12@gmail.com?subject=LifePilot%20Privacy")!
    }

    private func aboutRow(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: symbol)
                .foregroundStyle(Color.LifePilot.accentStart)
                .frame(width: 36, height: 36)
                .background(Color.LifePilot.accentStart.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.LifePilot.body.weight(.semibold))
                    .foregroundStyle(Color.LifePilot.textPrimary)
                Text(detail)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
        }
    }
}
