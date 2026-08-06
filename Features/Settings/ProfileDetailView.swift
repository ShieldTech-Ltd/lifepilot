import Foundation
import LifePilotDesignSystem
import PhotosUI
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// A complete local demo identity that personalizes the Morning Briefing.
public struct ProfileDetailView: View { // swiftlint:disable:this type_body_length
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
    @State private var isSaving = false

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
                ScreenHeader(
                    eyebrow: "Make it yours",
                    title: "Your profile",
                    subtitle: "Personalise the briefing with your identity, study context, and preferred start time."
                )
                identityCard
                profileSection
                contextSection
                briefingSection
                securitySection

                Button {
                    Task { await save() }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                                .tint(Color.LifePilot.controlPrimaryText)
                        } else {
                            Image(systemName: didSave && !hasUnsavedChanges
                                ? "checkmark.circle.fill"
                                : "tray.and.arrow.down.fill")
                        }

                        Text(saveButtonTitle)
                    }
                }
                .buttonStyle(.lifePilotPrimary)
                .disabled(
                    displayName.trimmingCharacters(in: .whitespaces).isEmpty
                        || isSaving
                        || !hasUnsavedChanges
                )
                .accessibilityIdentifier("profile.save")

                if didSave, !hasUnsavedChanges {
                    Label("Profile saved. Home now uses this identity.", systemImage: "checkmark.circle.fill")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.signalSuccess)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .lifePilotScreenBackground(energy: .prominent)
        .navigationTitle("Profile")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
                    Text(course.isEmpty ? "Your daily routine" : course)
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }

                Label("Personal profile stored on this device", systemImage: "person.crop.circle.fill")
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
            SectionHeader(title: "Daily context", symbolName: "calendar.badge.clock")
            CardContainer {
                VStack(spacing: Spacing.md) {
                    field("Routine", text: $course, identifier: "profile.course")
                    field("Profile type", text: $university, identifier: "profile.university")
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

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Security", symbolName: "lock.shield.fill")
            NavigationLink {
                PasswordSecurityView(session: session)
            } label: {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.LifePilot.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(Color.LifePilot.selectionFill, in: Circle())

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Change password")
                            .font(.LifePilot.body.weight(.semibold))
                            .foregroundStyle(Color.LifePilot.textPrimary)
                        Text(passwordDetail)
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.LifePilot.textTertiary)
                }
                .padding(Spacing.md)
                .lifePilotGlass(cornerRadius: CornerRadius.lg, isInteractive: true)
            }
            .buttonStyle(.lifePilotPressable)
            .accessibilityIdentifier("profile.changePassword")
        }
    }

    private var passwordDetail: String {
        guard let date = session.passwordUpdatedAt else { return "Protect your LifePilot account" }
        return "Updated \(date.formatted(date: .abbreviated, time: .omitted))"
    }

    private var hasUnsavedChanges: Bool {
        displayName != session.displayName
            || email != session.email
            || course != session.course
            || university != session.university
            || location != session.location
            || briefingTime != session.briefingTime
            || profileImageData != session.profileImageData
    }

    private var saveButtonTitle: String {
        if isSaving {
            return "Saving profile"
        }
        if didSave, !hasUnsavedChanges {
            return "Profile saved"
        }
        return "Save changes"
    }

    private func field(_ label: String, text: Binding<String>, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
            TextField(label, text: text)
                .textFieldStyle(.plain)
                .padding(.horizontal, Spacing.md)
                .frame(minHeight: 48)
                .background(Color.LifePilot.glassTint, in: RoundedRectangle(cornerRadius: CornerRadius.sm))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color.LifePilot.glassBorder, lineWidth: 1)
                }
                #if os(iOS)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                #endif
                .accessibilityIdentifier(identifier)
        }
    }

    @MainActor
    private func save() async {
        guard hasUnsavedChanges, !isSaving else { return }
        withAnimation(Motion.quick) {
            isSaving = true
            didSave = false
        }

        session.updateProfile(
            displayName: displayName,
            email: email,
            course: course,
            university: university,
            location: location,
            briefingTime: briefingTime
        )
        session.updateProfileImage(profileImageData)
        try? await Task.sleep(for: .milliseconds(450))

        withAnimation(Motion.standard) {
            isSaving = false
            didSave = true
        }
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
