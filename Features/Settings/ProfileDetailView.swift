import Foundation
import LifePilotDesignSystem
import SwiftUI

/// A complete local demo identity that personalizes the Morning Briefing.
public struct ProfileDetailView: View {
    private let session: DemoSessionStore
    @State private var displayName: String
    @State private var email: String
    @State private var course: String
    @State private var university: String
    @State private var location: String
    @State private var briefingTime: String
    @State private var didSave = false

    private let briefingTimes = ["7:00 AM", "8:00 AM", "9:00 AM"]

    public init(session: DemoSessionStore) {
        self.session = session
        _displayName = State(initialValue: session.displayName)
        _email = State(initialValue: session.email)
        _course = State(initialValue: session.course)
        _university = State(initialValue: session.university)
        _location = State(initialValue: session.location)
        _briefingTime = State(initialValue: session.briefingTime)
    }

    public init() {
        self.init(session: DemoSessionStore())
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                identityCard
                profileSection
                contextSection
                briefingSection

                Button("Save changes") {
                    save()
                }
                .buttonStyle(.lifePilotPrimary)
                .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("profile.save")

                if didSave {
                    Label("Profile saved — Home now uses this identity.", systemImage: "checkmark.circle.fill")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.signalSuccess)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.LifePilot.backgroundPrimary)
        .navigationTitle("Profile")
    }

    private var identityCard: some View {
        CardContainer {
            VStack(spacing: Spacing.md) {
                Circle()
                    .fill(LinearGradient.LifePilot.accent)
                    .frame(width: 84, height: 84)
                    .overlay {
                        Text(initials)
                            .font(.LifePilot.titleLarge)
                            .foregroundStyle(.white)
                    }

                VStack(spacing: Spacing.xs) {
                    Text(displayName.isEmpty ? "Your name" : displayName)
                        .font(.LifePilot.titleMedium)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    Text(course.isEmpty ? "Computing student" : course)
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }

                Label("TechFest demo identity", systemImage: "sparkles")
                    .font(.LifePilot.caption.weight(.semibold))
                    .foregroundStyle(Color.LifePilot.accentEnd)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Identity", symbolName: "person.text.rectangle")
            CardContainer {
                VStack(spacing: Spacing.md) {
                    field("Display name", text: $displayName, identifier: "profile.name")
                    field("Email", text: $email, identifier: "profile.email")
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                }
            }
        }
    }

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Study & context", symbolName: "graduationcap.fill")
            CardContainer {
                VStack(spacing: Spacing.md) {
                    field("Course", text: $course, identifier: "profile.course")
                    field("University", text: $university, identifier: "profile.university")
                    field("Location", text: $location, identifier: "profile.location")
                }
            }
        }
    }

    private var briefingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Morning briefing", symbolName: "sunrise.fill")
            CardContainer {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Prepare my day at")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                    Picker("Briefing time", selection: $briefingTime) {
                        ForEach(briefingTimes, id: \.self) { time in
                            Text(time).tag(time)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("profile.briefingTime")
                }
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                #endif
                .accessibilityIdentifier(identifier)
        }
    }

    private var initials: String {
        let letters = displayName.split(separator: " ").compactMap(\.first)
        return letters.isEmpty ? "?" : String(letters.prefix(2)).uppercased()
    }

    private func save() {
        session.updateProfile(
            displayName: displayName,
            email: email,
            course: course,
            university: university,
            location: location,
            briefingTime: briefingTime
        )
        didSave = true
    }
}

#Preview {
    NavigationStack {
        ProfileDetailView()
    }
}
