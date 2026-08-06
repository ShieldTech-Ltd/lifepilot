import SwiftUI

/// A restrained photographic canvas inspired by native iOS materials.
/// The study environment supplies real-world depth while an adaptive scrim
/// keeps text and controls readable in either system appearance.
public struct AmbientBackground: View {
    private let energy: Energy

    public init(energy: Energy = .subtle) {
        self.energy = energy
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.LifePilot.backgroundPrimary

                if energy == .prominent {
                    Image("LifePilotBackdrop")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .saturation(0.84)
                        .contrast(0.96)
                        .blur(radius: 0.6)
                        .overlay(Color.LifePilot.backdropScrim)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    public enum Energy: Equatable {
        case subtle
        case prominent
    }
}

extension View {
    public func lifePilotScreenBackground(energy: AmbientBackground.Energy = .subtle) -> some View {
        background { AmbientBackground(energy: energy) }
    }
}

/// Elevated card retained for develop features that need a stronger accent edge.
public struct GlowCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.LifePilot.backgroundElevated.opacity(0.92))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .stroke(LinearGradient.LifePilot.accent.opacity(0.35), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .lifePilotShadow(ShadowStyle.LifePilot.card)
    }
}

/// Compact context tile used for weather, meeting, and leave-by summaries.
public struct ContextTile: View {
    private let symbolName: String
    private let title: String
    private let subtitle: String
    private let accent: Color

    public init(
        symbolName: String,
        title: String,
        subtitle: String,
        accent: Color = Color.LifePilot.accentEnd
    ) {
        self.symbolName = symbolName
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: symbolName)
                .font(.system(size: IconSize.sm, weight: .semibold))
                .foregroundStyle(accent)
            Text(title)
                .font(.LifePilot.titleMedium)
                .foregroundStyle(Color.LifePilot.textPrimary)
                .lineLimit(2)
            Text(subtitle)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
                .lineLimit(2)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .background(Color.LifePilot.backgroundElevated)
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(accent.opacity(0.25), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Banner for offline, denied, stale, and other recoverable states.
public struct StatusBanner: View {
    public enum Style: String, Sendable, Equatable {
        case info
        case warning
        case risk
    }

    private let message: String
    private let style: Style
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        message: String,
        style: Style = .info,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.message = message
        self.style = style
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
            Text(message)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.accentEnd)
            }
        }
        .padding(Spacing.md)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var symbolName: String {
        switch style {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .risk: "xmark.octagon.fill"
        }
    }

    private var tint: Color {
        switch style {
        case .info: Color.LifePilot.accentEnd
        case .warning: Color.LifePilot.accentStart
        case .risk: Color.LifePilot.signalRisk
        }
    }
}
