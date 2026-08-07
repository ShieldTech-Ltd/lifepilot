import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Color tokens matching docs/DESIGN_SYSTEM.md's Color table exactly. Every
/// value here has an explicit light and dark definition - see that
/// document's Theming principle. No feature module should reach for a raw
/// hex value; everything composes from `Color.LifePilot`.
extension Color {
    public enum LifePilot {
        // MARK: - Background

        public static let backgroundPrimary = Color(
            light: Color(hex: 0xF2F1EE),
            dark: Color(hex: 0x101112)
        )

        public static let backgroundElevated = Color(
            light: Color(hex: 0xFFFFFF),
            dark: Color(hex: 0x242627)
        )

        public static let backgroundSecondary = Color(
            light: Color(hex: 0xE5E4E0),
            dark: Color(hex: 0x191B1C)
        )

        /// The readable content layer above the photographic canvas.
        /// Content cards stay calm and opaque enough to preserve hierarchy;
        /// Liquid Glass is reserved for navigation and floating controls.
        public static let contentSurface = Color(
            light: Color.white.opacity(0.9),
            dark: Color(hex: 0x1D2021).opacity(0.9)
        )

        public static let glassTint = Color(
            light: Color.white.opacity(0.28),
            dark: Color.black.opacity(0.12)
        )

        public static let glassBorder = Color(
            light: Color.black.opacity(0.14),
            dark: Color.white.opacity(0.16)
        )

        public static let separator = Color(
            light: Color.black.opacity(0.13),
            dark: Color.white.opacity(0.14)
        )

        public static let selectionFill = Color(
            light: Color.white.opacity(0.94),
            dark: Color.white.opacity(0.13)
        )

        public static let controlPrimary = Color(
            light: Color(hex: 0x171819),
            dark: Color(hex: 0xF5F5F2)
        )

        public static let controlPrimaryText = Color(
            light: Color.white,
            dark: Color(hex: 0x171819)
        )

        public static let backdropScrim = Color(
            light: Color.white.opacity(0.5),
            dark: Color.black.opacity(0.58)
        )

        // MARK: - Accent

        /// The logo-derived spectrum. Each colour also has a semantic role,
        /// keeping purple reserved for AI moments rather than every control.
        public static let accentStart = Color(
            light: Color(hex: 0x147D75),
            dark: Color(hex: 0x43BFB4)
        )
        public static let accentEnd = Color(
            light: Color(hex: 0x35677D),
            dark: Color(hex: 0x7AAAC0)
        )
        public static let accentAI = Color(
            light: Color(hex: 0x755F78),
            dark: Color(hex: 0xB49DB7)
        )
        public static let accentWarm = Color(
            light: Color(hex: 0x8A5A26),
            dark: Color(hex: 0xD7A66A)
        )
        public static let accentTeal = accentStart
        public static let onAccent = Color.white
        public static let borderSubtle = separator

        // MARK: - Text

        public static let textPrimary = Color(
            light: Color(hex: 0x111827),
            dark: Color(hex: 0xF4F4F1)
        )

        public static let textSecondary = Color(
            light: Color(hex: 0x5C605F),
            dark: Color(hex: 0xB7B9B7)
        )

        public static let textTertiary = Color(
            light: Color(hex: 0x666A68),
            dark: Color(hex: 0x8D918F)
        )

        // MARK: - Signal

        public static let signalRisk = Color(
            light: Color(hex: 0xC73855),
            dark: Color(hex: 0xFF6B86)
        )
        public static let signalSuccess = Color(
            light: Color(hex: 0x0F7560),
            dark: Color(hex: 0x34D3A5)
        )
        public static let signalWarning = Color(
            light: Color(hex: 0x8A5A00),
            dark: Color(hex: 0xFFC56A)
        )
        public static let signalInfo = Color(
            light: Color(hex: 0x246BCE),
            dark: Color(hex: 0x79B4FF)
        )
    }
}

extension LinearGradient {
    public enum LifePilot {
        /// The full logo spectrum, reserved for the brand mark and primary AI actions.
        public static let accent = LinearGradient(
            colors: [Color.LifePilot.accentStart, Color.LifePilot.accentEnd, Color.LifePilot.accentAI],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        public static let calm = LinearGradient(
            colors: [Color.LifePilot.accentStart, Color.LifePilot.accentEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        public static let warm = LinearGradient(
            colors: [Color.LifePilot.accentWarm, Color.LifePilot.signalRisk],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        public static let hero = LinearGradient(
            colors: [Color.LifePilot.accentStart, Color.LifePilot.accentEnd, Color.LifePilot.accentAI],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    /// Constructs a color from a packed RGB hex value, e.g. `Color(hex: 0x7C3AED)`.
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    /// Constructs a color that resolves to `light` or `dark` depending on
    /// the active `ColorScheme`, per docs/DESIGN_SYSTEM.md's Theming
    /// principle: "Light and dark themes are both first-class."
    ///
    /// Implemented via `Color(_:)`'s dynamic-provider initializer rather
    /// than `UIColor`/`NSColor` directly, so this compiles identically on
    /// iOS and macOS per the platforms declared in Package.swift.
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        self.init(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(dark)
                : NSColor(light)
        })
        #else
        self = light
        #endif
    }
}
