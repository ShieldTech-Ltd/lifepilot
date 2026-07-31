import LifePilotDesignSystem
import SwiftUI

/// The launch screen, shown briefly while the app performs its initial
/// setup. Purely presentational, with no ViewModel because it holds no state
/// beyond a timed transition the parent view controls.
public struct SplashView: View {
    @State private var isPulsing = false

    public init() {}

    public var body: some View {
        ZStack {
            Color.LifePilot.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                logoMark
                    .scaleEffect(isPulsing ? 1.04 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                        value: isPulsing
                    )

                Text("LifePilot")
                    .font(.LifePilot.titleLarge)
                    .foregroundStyle(Color.LifePilot.textPrimary)
            }
        }
        .onAppear { isPulsing = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("LifePilot is preparing your day")
    }

    private var logoMark: some View {
        Image("LifePilotLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 148, height: 148)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: Color.LifePilot.accentEnd.opacity(0.22), radius: 20, y: 10)
    }
}

#Preview {
    SplashView()
}
