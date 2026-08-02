import LifePilotCore
import LifePilotFeatures
import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private var hostingController: UIHostingController<LifePilotShareView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 0, height: 640)

        let model = ShareImportModel(extensionContext: extensionContext)
        let hostingController = UIHostingController(rootView: LifePilotShareView(model: model))
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController

        Task { await model.load() }
    }
}

@MainActor
private final class ShareImportModel: ObservableObject {
    private static let maximumAttachmentCount = 16
    private static let maximumImageBytes = 12 * 1_024 * 1_024
    private static let maximumTextBytes = 128 * 1_024

    @Published var draft: ScheduleImportDraft?
    @Published var isLoading = true
    @Published var errorMessage: String?

    private weak var extensionContext: NSExtensionContext?

    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
                .flatMap { $0.attachments ?? [] }
                .prefix(Self.maximumAttachmentCount) ?? []
            guard !providers.isEmpty else { throw ShareImportError.noContent }

            if let provider = providers.first(where: supportsCalendarFile),
               let text = try await loadTextOrFile(from: provider) {
                draft = CalendarInvitationParser.draft(from: text)
                return
            }

            if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) {
                let data = try await loadData(from: provider, typeIdentifier: UTType.image.identifier)
                draft = try await ScheduleScreenshotParser.parse(imageData: data)
                return
            }

            if let provider = providers.first(where: supportsTextOrURL),
               let text = try await loadTextOrFile(from: provider) {
                draft = CalendarInvitationParser.draft(from: text)
                return
            }

            throw ShareImportError.unsupportedContent
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(_ draft: ScheduleImportDraft) {
        let event = CalendarEvent(
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            location: draft.location.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            startDate: draft.startDate,
            endDate: draft.endDate
        )
        SharedImportedEventStore.add(event)

        if let current = UpcomingEventWidgetStore.load(), current.endDate > Date(), current.startDate <= event.startDate {
            // Keep the earlier event already visible in the widget.
        } else {
            UpcomingEventWidgetStore.save(event: event)
        }
        extensionContext?.completeRequest(returningItems: nil)
    }

    func cancel() {
        extensionContext?.cancelRequest(withError: ShareImportError.cancelled)
    }

    private func supportsCalendarFile(_ provider: NSItemProvider) -> Bool {
        let calendarIdentifier = UTType(filenameExtension: "ics")?.identifier ?? "public.calendar-event"
        return provider.hasItemConformingToTypeIdentifier(calendarIdentifier)
            || provider.hasItemConformingToTypeIdentifier(UTType.data.identifier)
    }

    private func supportsTextOrURL(_ provider: NSItemProvider) -> Bool {
        provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
            || provider.hasItemConformingToTypeIdentifier(UTType.url.identifier)
    }

    private func loadTextOrFile(from provider: NSItemProvider) async throws -> String? {
        let calendarIdentifier = UTType(filenameExtension: "ics")?.identifier ?? "public.calendar-event"
        let identifiers = [calendarIdentifier, UTType.plainText.identifier, UTType.url.identifier, UTType.data.identifier]

        for identifier in identifiers where provider.hasItemConformingToTypeIdentifier(identifier) {
            let item = try await loadItem(from: provider, typeIdentifier: identifier)
            if let text = item as? String { return try validated(text: text) }
            if let url = item as? URL {
                if url.isFileURL { return try loadBoundedTextFile(from: url) }
                return try validated(text: url.absoluteString)
            }
            if let data = item as? Data {
                guard data.count <= Self.maximumTextBytes else { throw ShareImportError.contentTooLarge }
                if let text = String(data: data, encoding: .utf8) { return text }
            }
        }
        return nil
    }

    private func validated(text: String) throws -> String {
        guard text.utf8.count <= Self.maximumTextBytes else { throw ShareImportError.contentTooLarge }
        return text
    }

    private func loadBoundedTextFile(from url: URL) throws -> String? {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: Self.maximumTextBytes + 1) ?? Data()
        guard data.count <= Self.maximumTextBytes else { throw ShareImportError.contentTooLarge }
        return String(data: data, encoding: .utf8)
    }

    private func loadItem(from provider: NSItemProvider, typeIdentifier: String) async throws -> NSSecureCoding? {
        return try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: item)
                }
            }
        }
    }

    private func loadData(from provider: NSItemProvider, typeIdentifier: String) async throws -> Data {
        let maximumImageBytes = Self.maximumImageBytes
        return try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    if data.count <= maximumImageBytes {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: ShareImportError.contentTooLarge)
                    }
                } else {
                    continuation.resume(throwing: ShareImportError.unsupportedContent)
                }
            }
        }
    }
}

private struct LifePilotShareView: View {
    @ObservedObject var model: ShareImportModel

    var body: some View {
        NavigationStack {
            Group {
                if model.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Reading invitation")
                            .font(.headline)
                        Text("LifePilot is extracting the event details on this device.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                } else if let errorMessage = model.errorMessage {
                    ContentUnavailableView(
                        "Invitation not recognised",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text(errorMessage)
                    )
                } else if let draft = model.draft {
                    ShareDraftForm(draft: draft, onSave: model.save)
                }
            }
            .navigationTitle("Add to LifePilot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: model.cancel)
                }
            }
        }
    }
}

private struct ShareDraftForm: View {
    @State private var draft: ScheduleImportDraft
    let onSave: (ScheduleImportDraft) -> Void

    init(draft: ScheduleImportDraft, onSave: @escaping (ScheduleImportDraft) -> Void) {
        _draft = State(initialValue: draft)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section("Event details") {
                TextField("Event title", text: $draft.title)
                TextField("Location or meeting link", text: $draft.location)
                DatePicker("Starts", selection: $draft.startDate)
                DatePicker("Ends", selection: $draft.endDate, in: draft.startDate.addingTimeInterval(60)...)
            }

            Section("Detected content") {
                Text(draft.recognizedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(6)
            }

            Button("Add event to LifePilot") {
                onSave(draft)
            }
            .disabled(!isValid)
            .accessibilityIdentifier("shareExtension.addEvent")
        }
    }

    private var isValid: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft.endDate > draft.startDate
    }
}

private enum ShareImportError: LocalizedError {
    case noContent
    case unsupportedContent
    case contentTooLarge
    case cancelled

    var errorDescription: String? {
        switch self {
        case .noContent: "No invitation content was shared."
        case .unsupportedContent: "Share invitation text, an ICS file, a link, or a screenshot."
        case .contentTooLarge: "That attachment is too large to import safely. Choose a smaller file or screenshot."
        case .cancelled: "Adding the invitation was cancelled."
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
