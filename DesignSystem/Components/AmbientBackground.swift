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
