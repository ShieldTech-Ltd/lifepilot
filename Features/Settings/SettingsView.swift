import LifePilotDesignSystem
import SwiftUI

/// Settings for the local demo identity, connected sources, approval
/// preferences, and repeatable showcase data.
public struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    public init(session: DemoSessionStore) {
        _viewModel = State(initialValue: SettingsViewModel(session: session))
    }

    public init() {
        self.init(session: DemoSessionStore())
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ScreenHeader(
                    eyebrow: "Control centre",
                    title: "Settings",
                    subtitle: "Shape how LifePilot prepares, explains, and protects your day.",
                    symbolName: "gearshape.fill",
                    status: "Local",
                    tint: Color.LifePilot.accentWarm
                )

                profileCard

                ForEach(viewModel.sections) { section in
                    let rows = section.rows.filter { $0.id != "profile" }
                    if !rows.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(section.title.uppercased())
                                .font(.LifePilot.utility)
                                .tracking(1)
                                .foregroundStyle(Color.LifePilot.textPrimary)

                            CardContainer {
                                VStack(spacing: 0) {
                                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                                        rowContent(row)
                                        if index < rows.count - 1 {
                                            Divider().overlay(Color.LifePilot.glassBorder)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .lifePilotScreenBackground(energy: .prominent)
        .navigationTitle("")
        .navigationDestination(for: SettingsDestination.self) { destination in
            destinationView(for: destination)
        }
    }

    private var profileCard: some View {
        NavigationLink(value: SettingsDestination.profile) {
            HStack(spacing: Spacing.md) {
                ProfileAvatarView(
                    imageData: viewModel.session.profileImageData,
                    displayName: viewModel.session.displayName,
                    size: 58
                )

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(viewModel.session.displayName)
                        .font(.LifePilot.titleMedium)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    Text("\(viewModel.session.course) · \(viewModel.session.university)")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.LifePilot.textTertiary)
            }
            .padding(Spacing.md)
            .lifePilotSurface(cornerRadius: CornerRadius.lg, fill: Color.LifePilot.contentSurface)
            .lifePilotShadow(ShadowStyle.LifePilot.card)
        }
        .buttonStyle(.lifePilotPressable)
        .accessibilityIdentifier("settings.profile")
    }

    @ViewBuilder
    private func rowContent(_ row: SettingsRow) -> some View {
        if let destination = row.destination {
            NavigationLink(value: destination) {
                rowLabel(row)
            }
        } else {
            rowLabel(row)
        }
    }

    private func rowLabel(_ row: SettingsRow) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: row.symbolName)
                .foregroundStyle(color(for: row.id))
                .frame(width: 36, height: 36)
                .background(color(for: row.id).opacity(0.12), in: Circle())

            Text(row.title)
                .font(.LifePilot.body)
                .foregroundStyle(Color.LifePilot.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.84)
                .layoutPriority(1)

            Spacer()

            if let detail = row.detail {
                Text(detail)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }

            if row.destination != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.LifePilot.textTertiary)
            }
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }

    private func color(for rowID: String) -> Color {
        switch rowID {
        case "connected": Color.LifePilot.accentStart
        case "appearance": Color.LifePilot.accentEnd
        case "liveExperiences": Color.LifePilot.accentStart
        case "approvals": Color.LifePilot.signalSuccess
        case "data": Color.LifePilot.signalWarning
        case "about": Color.LifePilot.accentAI
        default: Color.LifePilot.accentEnd
        }
    }

    @ViewBuilder
    private func destinationView(for destination: SettingsDestination) -> some View {
        switch destination {
        case .profile: ProfileDetailView(session: viewModel.session)
        case .connectedApps: ConnectedAppsView(session: viewModel.session)
        case .approvalPreferences: ApprovalPreferencesView(session: viewModel.session)
        case .dataPrivacy: DataPrivacyView(session: viewModel.session)
        case .appearance: AppearanceView(session: viewModel.session)
        case .liveExperiences: LiveExperiencesView(session: viewModel.session)
        case .about: AboutView()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
