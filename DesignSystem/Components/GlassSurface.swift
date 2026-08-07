import SwiftUI

/// A translucent, adaptive surface treatment for chrome that should feel
/// layered above content - headers, navigation backgrounds, floating
/// action sheets. Used sparingly, per docs/DESIGN_SYSTEM.md's "Calm by
/// default" principle: glass communicates depth for genuinely floating
/// chrome, not as a decorative default for ordinary cards (use
/// `CardContainer` for those).
public struct GlassSurface<Content: View>: View {
    private let cornerRadius: CGFloat
    private let isInteractive: Bool
    private let content: Content

    public init(
        cornerRadius: CGFloat = 0,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
        self.content = content()
    }

    public var body: some View {
        content.modifier(GlassModifier(cornerRadius: cornerRadius, isInteractive: isInteractive))
    }
}

/// The reusable glass-chrome treatment `GlassSurface` and
/// `.lifePilotGlass()` both apply - extracted per this PR's Task 3 so the
/// `.ultraThinMaterial` background is defined once.
public struct GlassModifier: ViewModifier {
    private let cornerRadius: CGFloat
    private let isInteractive: Bool
    @Environment(\.colorScheme) private var colorScheme

    public init(cornerRadius: CGFloat = 0, isInteractive: Bool = false) {
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
    }

    public func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *) {
            if cornerRadius > 0 {
                content
                    .glassEffect(
                        .regular.interactive(isInteractive),
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    )
            } else {
                content
                    .glassEffect(.regular.interactive(isInteractive), in: Rectangle())
            }
        } else {
            fallback(content: content)
        }
        #else
        fallback(content: content)
        #endif
    }

    @ViewBuilder
    private func fallback(content: Content) -> some View {
        if cornerRadius > 0 {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            content
                .background(.ultraThinMaterial, in: shape)
                .background(Color.LifePilot.glassTint, in: shape)
                .overlay {
                    shape.stroke(Color.LifePilot.glassBorder, lineWidth: colorScheme == .dark ? 0.7 : 0.9)
                }
        } else {
            content
                .background(.ultraThinMaterial)
                .background(Color.LifePilot.glassTint)
        }
    }
}

extension View {
    /// Applies the standard glass chrome background used for floating
    /// surfaces like tab bars and sheets. Pass `cornerRadius` to also clip
    /// to a rounded shape - e.g. a floating card rather than a full-bleed
    /// bar.
    public func lifePilotGlass(cornerRadius: CGFloat = 0, isInteractive: Bool = false) -> some View {
        modifier(GlassModifier(cornerRadius: cornerRadius, isInteractive: isInteractive))
    }
}
