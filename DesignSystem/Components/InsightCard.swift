import SwiftUI

/// A stat-forward card for a single measured insight, used by the live
/// demo snapshot for pending recommendations, approved actions, signals,
/// and estimated time saved.
public struct InsightCard: View {
    private let value: String
    private let label: String
    private let trend: Trend?
    private let symbolName: String?
    private let tint: Color
    private let showsDisclosure: Bool

    public init(
        value: String,
        label: String,
        trend: Trend? = nil,
        symbolName: String? = nil,
        tint: Color = Color.LifePilot.accentEnd,
        showsDisclosure: Bool = false
    ) {
        self.value = value
        self.label = label
        self.trend = trend
        self.symbolName = symbolName
        self.tint = tint
        self.showsDisclosure = showsDisclosure
    }

    public var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    if let symbolName {
                        Image(systemName: symbolName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(tint)
                            .frame(width: 32, height: 32)
                            .background(tint.opacity(0.12), in: Circle())
                    }

                    Spacer()

                    if showsDisclosure {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.LifePilot.textTertiary)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(value)
                        .font(.LifePilot.metric)
                        .foregroundStyle(Color.LifePilot.textPrimary)

                    if let trend {
                        Image(systemName: trend.symbolName)
                            .font(.system(size: IconSize.sm, weight: .semibold))
                            .foregroundStyle(trend.color)
                            .accessibilityHidden(true)
                    }
                }

                Text(label)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        guard let trend else { return "\(value), \(label)" }
        return "\(value), \(label), \(trend.accessibilityDescription)"
    }

    public enum Trend {
        case up
        case down
        case flat

        var symbolName: String {
            switch self {
            case .up: "arrow.up.right"
            case .down: "arrow.down.right"
            case .flat: "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: Color.LifePilot.signalSuccess
            case .down: Color.LifePilot.signalRisk
            case .flat: Color.LifePilot.textSecondary
            }
        }

        var accessibilityDescription: String {
            switch self {
            case .up: "trending up"
            case .down: "trending down"
            case .flat: "no change"
            }
        }
    }
}

#Preview {
    HStack(spacing: Spacing.sm) {
        InsightCard(value: "4.5 hrs", label: "Time saved this week", trend: .up)
        InsightCard(value: "94%", label: "Productivity score", trend: .flat)
    }
    .padding()
}
