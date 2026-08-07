import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

public struct ScheduleImportReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ScheduleImportDraft
    private let onSave: (CalendarEvent) -> Void

    public init(draft: ScheduleImportDraft, onSave: @escaping (CalendarEvent) -> Void) {
        _draft = State(initialValue: draft)
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Event details") {
                    TextField("Event title", text: $draft.title)
                    TextField("Location or meeting link", text: $draft.location)
                    DatePicker("Starts", selection: $draft.startDate)
                    DatePicker(
                        "Ends",
                        selection: $draft.endDate,
                        in: draft.startDate.addingTimeInterval(60)...
                    )
                }

                Section {
                    Text(draft.recognizedText)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                        .textSelection(.enabled)
                } header: {
                    Text("Recognised from screenshot")
                } footer: {
                    Text("Check the details before adding this event to your LifePilot schedule.")
                }
            }
            .navigationTitle("Check schedule event")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add event") {
                        onSave(
                            CalendarEvent(
                                title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                                location: draft.location.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                                startDate: draft.startDate,
                                endDate: draft.endDate
                            )
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                    .accessibilityIdentifier("scheduleImport.save")
                }
            }
        }
    }

    private var isValid: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft.endDate > draft.startDate
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
