import Foundation
import LifePilotDesignSystem
import PhotosUI
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// A complete local demo identity that personalizes the Morning Briefing.
public struct ProfileDetailView: View {
    private let session: DemoSessionStore
    @State private var displayName: String
    @State private var email: String
    @State private var course: String
    @State private var university: String
    @State private var location: String
    @State private var briefingTime: String
    @State private var profileImageData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    @State private var photoErrorMessage: String?
    @State private var didSave = false

    private let briefingTimes = ["07:00", "08:00", "09:00"]

    public init(session: DemoSessionStore) {
        self.session = session
        _displayName = State(initialValue: session.displayName)
        _email = State(initialValue: session.email)
        _course = State(initialValue: session.course)
        _university = State(initialValue: session.university)
        _location = State(initialValue: session.location)
        _briefingTime = State(initialValue: session.briefingTime)
        _profileImageData = State(initialValue: session.profileImageData)
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
                    Label("Profile saved. Home now uses this identity.", systemImage: "checkmark.circle.fill")
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
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task { await loadPhoto(from: item) }
        }
    }

    private var identityCard: some View {
        CardContainer {
            VStack(spacing: Spacing.md) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        ProfileAvatarView(
                            imageData: profileImageData,
                            displayName: displayName,
                            size: 96
                        )

                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.LifePilot.accentEnd, in: Circle())
                            .overlay {
                                Circle().stroke(Color.LifePilot.backgroundElevated, lineWidth: 3)
                            }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLoadingPhoto)
                .accessibilityLabel(profileImageData == nil ? "Choose profile photo" : "Change profile photo")
                .accessibilityIdentifier("profile.photoPicker")

                if isLoadingPhoto {
                    ProgressView("Preparing photo")
                        .font(.LifePilot.caption)
                } else if profileImageData == nil {
                    Text("Choose a photo from this device")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                } else {
                    Button("Remove photo", role: .destructive) {
                        profileImageData = nil
                        selectedPhoto = nil
                        didSave = false
                    }
                    .font(.LifePilot.caption.weight(.semibold))
                    .accessibilityIdentifier("profile.removePhoto")
                }

                if let photoErrorMessage {
                    Text(photoErrorMessage)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.signalRisk)
                }

                VStack(spacing: Spacing.xs) {
                    Text(displayName.isEmpty ? "Your name" : displayName)
                        .font(.LifePilot.titleMedium)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    Text(course.isEmpty ? "Computing student" : course)
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }

                Label("UK student demo identity", systemImage: "graduationcap.fill")
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

    private func save() {
        session.updateProfile(
            displayName: displayName,
            email: email,
            course: course,
            university: university,
            location: location,
            briefingTime: briefingTime
        )
        session.updateProfileImage(profileImageData)
        didSave = true
    }

    @MainActor
    private func loadPhoto(from item: PhotosPickerItem) async {
        isLoadingPhoto = true
        photoErrorMessage = nil
        defer { isLoadingPhoto = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                photoErrorMessage = "That photo could not be read. Choose another image."
                return
            }
            profileImageData = preparedPhotoData(from: data)
            didSave = false
        } catch {
            photoErrorMessage = "That photo could not be loaded. Choose another image."
        }
    }

    private func preparedPhotoData(from data: Data) -> Data {
        #if canImport(UIKit)
        guard let image = UIImage(data: data),
              let thumbnail = image.preparingThumbnail(of: CGSize(width: 640, height: 640))
        else {
            return data
        }
        return thumbnail.jpegData(compressionQuality: 0.82) ?? data
        #else
        return data
        #endif
    }
}

#Preview {
    NavigationStack {
        ProfileDetailView()
    }
}
