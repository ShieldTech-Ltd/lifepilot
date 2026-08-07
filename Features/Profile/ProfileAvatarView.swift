import Foundation
import LifePilotDesignSystem
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A local profile image with an initials fallback, shared by Home and Settings.
struct ProfileAvatarView: View {
    let imageData: Data?
    let displayName: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient.LifePilot.accent)

            avatarContent
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Color.white.opacity(0.7), lineWidth: 2)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var avatarContent: some View {
        #if canImport(UIKit)
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            initialsView
        }
        #elseif canImport(AppKit)
        if let imageData, let image = NSImage(data: imageData) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            initialsView
        }
        #else
        initialsView
        #endif
    }

    private var initialsView: some View {
        Text(initials)
            .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
    }

    private var initials: String {
        let letters = displayName.split(separator: " ").compactMap(\.first)
        return letters.isEmpty ? "?" : String(letters.prefix(2)).uppercased()
    }
}
