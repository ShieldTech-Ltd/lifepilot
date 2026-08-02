import SwiftUI

/// Instrument-style progress ring used for daily readiness and insight goals.
public struct StatusOrbit: View {
    private let progress: Double
    private let value: String
    private let label: String
    private let tint: Color
    private let size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedProgress = 0.0

    public init(
        progress: Double,
        value: String,
        label: String,
        tint: Color = Color.LifePilot.accentStart,
        size: CGFloat = 104
    ) {
        self.progress = min(max(progress, 0), 1)
        self.value = value
        self.label = label
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.LifePilot.textSecondary.opacity(0.15), lineWidth: max(8, size * 0.09))

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: max(8, size * 0.09), lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text(value)
                    .font(.system(size: size * 0.24, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.LifePilot.textPrimary)

                Text(label.uppercased())
                    .font(.system(size: max(8, size * 0.08), weight: .semibold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if reduceMotion {
                animatedProgress = progress
            } else {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.82)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(reduceMotion ? nil : Motion.spring) {
                animatedProgress = min(max(newValue, 0), 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}
