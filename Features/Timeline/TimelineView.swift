import LifePilotDesignSystem
import PhotosUI
import SwiftUI

/// Unified, filterable timeline with inspectable and reviewable entries.
public struct TimelineView: View {
    @State private var viewModel: TimelineViewModel
    @State private var selectedEntry: TimelineEntry?
    @State private var reviewedEntryIDs: Set<UUID> = []
    @State private var selectedScreenshot: PhotosPickerItem?
    @State private var importDraft: ScheduleImportDraft?
    @State private var isReadingScreenshot = false
    @State private var importErrorMessage: String?
    @State private var importedEventTitle: String?

    public init(session: DemoSessionStore) {
        _viewModel = State(initialValue: TimelineViewModel(session: session))
    }

    public init() {
        self.init(session: DemoSessionStore())
    }

    public var body: some View {
        List {
            Section {
                ScreenHeader(
                    eyebrow: "One connected day",
                    title: "Timeline",
                    subtitle: "Events and decisions in one chronological view.",
                    symbolName: "list.bullet.rectangle.fill",
                    status: viewModel.selectedFilter.rawValue,
                    tint: Color.LifePilot.accentEnd
                )
                .listRowInsets(EdgeInsets(top: Spacing.md, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                filterBar
                    .listRowInsets(EdgeInsets(top: 0, leading: Spacing.lg, bottom: Spacing.md, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                screenshotImportCard
                    .listRowInsets(EdgeInsets(top: 0, leading: Spacing.lg, bottom: Spacing.md, trailing: Spacing.lg))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            if viewModel.entries.isEmpty {
                EmptyStateView(
                    symbolName: "line.3.horizontal.decrease.circle",
                    message: "Nothing matches this view. Choose another source or reconnect it in Settings."
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(dayGroups) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            entryButton(entry)
                                .listRowInsets(
                                    EdgeInsets(
                                        top: Spacing.xs,
                                        leading: Spacing.lg,
                                        bottom: Spacing.xs,
                                        trailing: Spacing.lg
                                    )
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text(dayTitle(group.date))
                            .font(.LifePilot.utility)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                            .textCase(nil)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(.thinMaterial, in: Capsule())
                            .overlay {
                                Capsule().stroke(Color.LifePilot.glassBorder, lineWidth: 0.8)
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background { AmbientBackground(energy: .prominent) }
        .navigationTitle("")
        .task { await viewModel.load() }
        .sheet(item: $selectedEntry) { entry in
            entrySheet(entry)
                .presentationDetents([.medium])
        }
        .sheet(item: $importDraft) { draft in
            ScheduleImportReviewView(draft: draft) { event in
                viewModel.addImportedEvent(event)
                importedEventTitle = event.title
                importErrorMessage = nil
            }
        }
        .onChange(of: selectedScreenshot) { _, item in
            guard let item else { return }
            Task { await readSchedule(from: item) }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(TimelineFilter.allCases) { filter in
                    Button {
                        withAnimation(Motion.standard) {
                            viewModel.selectedFilter = filter
                        }
                    } label: {
                        Label(filter.rawValue, systemImage: symbol(for: filter))
                            .font(.LifePilot.caption.weight(.semibold))
                            .foregroundStyle(
                                viewModel.selectedFilter == filter
                                    ? Color.LifePilot.controlPrimaryText
                                    : Color.LifePilot.textPrimary
                            )
                            .padding(.horizontal, Spacing.md)
                            .frame(minHeight: 44)
                            .background {
                                if viewModel.selectedFilter == filter {
                                    Color.LifePilot.controlPrimary
                                } else {
                                    Color.LifePilot.selectionFill
                                }
                            }
                            .clipShape(Capsule())
                            .overlay {
                                Capsule().stroke(Color.LifePilot.glassBorder, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.lifePilotPressable)
                    .accessibilityIdentifier("timeline.filter.\(filter.rawValue.lowercased())")
                }
            }
        }
    }

    private var screenshotImportCard: some View {
        PhotosPicker(selection: $selectedScreenshot, matching: .images) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.LifePilot.accentStart)
                    .frame(width: 44, height: 44)
                    .background(Color.LifePilot.accentStart.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(isReadingScreenshot ? "Reading screenshot" : "Add schedule from screenshot")
                        .font(.LifePilot.body.weight(.semibold))
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    Text(importStatusText)
                        .font(.LifePilot.caption)
                        .foregroundStyle(importErrorMessage == nil ? Color.LifePilot.textSecondary : Color.LifePilot.signalRisk)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: Spacing.xs)

                if isReadingScreenshot {
                    ProgressView()
                        .tint(Color.LifePilot.accentStart)
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
            }
            .padding(Spacing.md)
            .lifePilotGlass(cornerRadius: CornerRadius.lg, isInteractive: true)
        }
        .buttonStyle(.lifePilotPressable)
        .disabled(isReadingScreenshot)
        .accessibilityIdentifier("scheduleImport.photoPicker")
    }

    private var importStatusText: String {
        if let importErrorMessage { return importErrorMessage }
        if let importedEventTitle {
            return "Added \(importedEventTitle) to your schedule."
        }
        return "Choose a timetable, poster, or booking screenshot. You can check every field before saving."
    }

    @MainActor
    private func readSchedule(from item: PhotosPickerItem) async {
        isReadingScreenshot = true
        importErrorMessage = nil
        importedEventTitle = nil
        defer {
            isReadingScreenshot = false
            selectedScreenshot = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw ScheduleImportError.invalidImage
            }
            importDraft = try await ScheduleScreenshotParser.parse(imageData: data)
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func entryButton(_ entry: TimelineEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: symbol(for: entry.kind))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color(for: entry.kind))
                    .frame(width: 36, height: 36)
                    .background(color(for: entry.kind).opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(entry.title)
                        .font(.LifePilot.body.weight(.semibold))
                        .foregroundStyle(Color.LifePilot.textPrimary)
                        .multilineTextAlignment(.leading)
                    if let subtitle = entry.subtitle {
                        Text(subtitle)
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: Spacing.xs)

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                        .font(.system(.caption2, design: .rounded, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Color.LifePilot.textSecondary)

                    Image(systemName: reviewedEntryIDs.contains(entry.id) ? "checkmark.circle.fill" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(
                            reviewedEntryIDs.contains(entry.id)
                                ? Color.LifePilot.signalSuccess
                                : Color.LifePilot.textTertiary
                        )
                }
            }
            .frame(minHeight: 62)
            .padding(Spacing.md)
            .lifePilotSurface(cornerRadius: CornerRadius.lg, fill: Color.LifePilot.contentSurface)
            .lifePilotShadow(ShadowStyle.LifePilot.card)
            .contentShape(Rectangle())
        }
        .buttonStyle(.lifePilotPressable)
        .accessibilityHint("Opens details and review controls")
        .accessibilityIdentifier("timeline.entry.\(entry.id.uuidString)")
    }

    private var dayGroups: [TimelineDayGroup] {
        let calendar = Calendar.current
        return Dictionary(grouping: viewModel.entries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        .map { TimelineDayGroup(date: $0.key, entries: $0.value.sorted { $0.date < $1.date }) }
        .sorted { $0.date < $1.date }
    }

    private func dayTitle(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private func entrySheet(_ entry: TimelineEntry) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: symbol(for: entry.kind))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(color(for: entry.kind))
                        .frame(width: 54, height: 54)
                        .background(color(for: entry.kind).opacity(0.14), in: Circle())
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(kindName(entry.kind))
                            .font(.LifePilot.utility)
                            .foregroundStyle(color(for: entry.kind))
                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    }
                }

                Text(entry.title)
                    .font(.LifePilot.titleMedium)
                    .foregroundStyle(Color.LifePilot.textPrimary)

                if let subtitle = entry.subtitle {
                    Text(subtitle)
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }

                Spacer()

                Button(reviewedEntryIDs.contains(entry.id) ? "Mark as not reviewed" : "Mark as reviewed") {
                    if reviewedEntryIDs.contains(entry.id) {
                        reviewedEntryIDs.remove(entry.id)
                    } else {
                        reviewedEntryIDs.insert(entry.id)
                    }
                    selectedEntry = nil
                }
                .buttonStyle(.lifePilotPrimary)
                .accessibilityIdentifier("timeline.entry.review")

                Button("Show only \(kindName(entry.kind).lowercased()) items") {
                    viewModel.selectedFilter = filter(for: entry.kind)
                    selectedEntry = nil
                }
                .buttonStyle(.lifePilotSecondary)
                .accessibilityIdentifier("timeline.entry.filter")
            }
            .padding(Spacing.lg)
            .lifePilotScreenBackground(energy: .subtle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { selectedEntry = nil }
                }
            }
        }
    }

    private func color(for kind: TimelineEntry.Kind) -> Color {
        switch kind {
        case .event: Color.LifePilot.accentEnd
        case .email: Color.LifePilot.accentAI
        case .task: Color.LifePilot.signalSuccess
        case .travel: Color.LifePilot.accentStart
        case .action: Color.LifePilot.signalWarning
        }
    }

    private func symbol(for kind: TimelineEntry.Kind) -> String {
        switch kind {
        case .event: "calendar"
        case .email: "envelope.fill"
        case .task: "checklist"
        case .travel: "tram.fill"
        case .action: "checkmark.shield.fill"
        }
    }

    private func kindName(_ kind: TimelineEntry.Kind) -> String {
        switch kind {
        case .event: "Calendar"
        case .email: "Inbox"
        case .task: "Task"
        case .travel: "Travel"
        case .action: "Approved action"
        }
    }

    private func filter(for kind: TimelineEntry.Kind) -> TimelineFilter {
        switch kind {
        case .event: .calendar
        case .email: .email
        case .task: .task
        case .travel: .travel
        case .action: .action
        }
    }

    private func symbol(for filter: TimelineFilter) -> String {
        switch filter {
        case .all: "rectangle.stack.fill"
        case .calendar: "calendar"
        case .email: "envelope.fill"
        case .task: "checklist"
        case .travel: "tram.fill"
        case .action: "checkmark.shield.fill"
        }
    }
}

private struct TimelineDayGroup: Identifiable {
    var id: Date { date }
    let date: Date
    let entries: [TimelineEntry]
}

#Preview {
    NavigationStack {
        TimelineView()
    }
}
