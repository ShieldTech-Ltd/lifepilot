import SwiftUI

/// A stat-forward card for a single measured insight, used by the live
/// demo snapshot for pending recommendations, approved actions, signals,
/// and estimated time saved.
public struct InsightCard: View {
    private let value: String
    private let label: String
    private let trend: Trend?

    public init(value: String, label: String, trend: Trend? = nil) {
        self.value = value
        self.label = label
        self.trend = trend
    }

    public var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(value)
                        .font(.LifePilot.titleLarge)
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
