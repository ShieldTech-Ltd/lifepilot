import SwiftUI

/// A floating navigation-layer header for LifePilot's primary destinations.
/// The module lens and live status make each tab recognisable at a glance.
public struct ScreenHeader: View {
    private let eyebrow: String
    private let title: String
    private let subtitle: String?
    private let symbolName: String?
    private let imageName: String?
    private let status: String?
    private let tint: Color

    public init(
        eyebrow: String,
        title: String,
        subtitle: String? = nil,
        symbolName: String? = nil,
        imageName: String? = nil,
        status: String? = nil,
        tint: Color = Color.LifePilot.accentStart
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.imageName = imageName
        self.status = status
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .center, spacing: Spacing.md) {
                if let imageName {
                    brandMark(imageName)
                } else if let symbolName {
                    moduleLens(symbolName)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(eyebrow.uppercased())
                        .font(.LifePilot.utility)
                        .tracking(1.1)
                        .foregroundStyle(tint)

                    Text(title)
                        .font(.LifePilot.titleLarge)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: Spacing.xs)

                if let status {
                    statusPill(status)
                }
            }

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .lifePilotGlass(cornerRadius: CornerRadius.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func moduleLens(_ symbolName: String) -> some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.12))

            Circle()
                .trim(from: 0.08, to: 0.78)
                .stroke(tint.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .rotationEffect(.degrees(-30))
                .padding(4)

            Image(systemName: symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 48, height: 48)
        .accessibilityHidden(true)
    }

    private func brandMark(_ imageName: String) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Color.LifePilot.glassBorder.opacity(0.75), lineWidth: 0.8)
            }
            .accessibilityHidden(true)
    }

    private func statusPill(_ status: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
            Text(status)
                .lineLimit(1)
        }
        .font(.LifePilot.utility)
        .foregroundStyle(Color.LifePilot.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.LifePilot.selectionFill, in: Capsule())
        .overlay {
            Capsule().stroke(Color.LifePilot.glassBorder.opacity(0.65), lineWidth: 0.7)
        }
    }
}
