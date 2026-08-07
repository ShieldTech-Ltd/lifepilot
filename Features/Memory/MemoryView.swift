import LifePilotDesignSystem
import SwiftUI

/// Transparent, user-correctable view of the context LifePilot remembers.
public struct MemoryView: View {
    @State private var viewModel: MemoryViewModel
    @State private var selectedMemory: MemorySelection?
    @State private var hiddenFactIDs: Set<String> = []
    @State private var confirmedFactIDs: Set<String> = []

    public init(session: DemoSessionStore) {
        _viewModel = State(initialValue: MemoryViewModel(session: session))
    }

    public init() {
        self.init(session: DemoSessionStore())
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ScreenHeader(
                    eyebrow: "Visible and correctable",
                    title: "Memory",
                    subtitle: "Review what LifePilot has learned. Keep useful context "
                        + "or forget anything that is wrong.",
                    symbolName: "brain.head.profile",
                    status: "\(visibleFactCount) facts",
                    tint: Color.LifePilot.accentAI
                )

                memoryStatus

                if visibleSections.isEmpty {
                    EmptyStateView(
                        symbolName: "brain.head.profile",
                        message: hiddenFactIDs.isEmpty
                            ? "LifePilot hasn't learned anything yet today."
                            : "You forgot every memory in this session. Restore them to review again."
                    )
                } else {
                    ForEach(visibleSections) { section in
                        memorySection(section)
                    }
                }

                if !hiddenFactIDs.isEmpty {
                    Button("Restore forgotten memories") {
                        withAnimation(Motion.standard) {
                            hiddenFactIDs.removeAll()
                        }
                    }
                    .buttonStyle(.lifePilotSecondary)
                    .accessibilityIdentifier("memory.restore")
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .lifePilotScreenBackground(energy: .prominent)
        .navigationTitle("")
        .task { await viewModel.load() }
        .sheet(item: $selectedMemory) { selection in
            memorySheet(selection)
                .presentationDetents([.medium])
        }
    }

    private var visibleSections: [MemorySection] {
        viewModel.sections.compactMap { section in
            let facts = section.facts.filter { !hiddenFactIDs.contains($0.id) }
            guard !facts.isEmpty else { return nil }
            return MemorySection(id: section.id, title: section.title, symbolName: section.symbolName, facts: facts)
        }
    }

    private var memoryStatus: some View {
        CardContainer {
            HStack(spacing: Spacing.lg) {
                StatusOrbit(
                    progress: memoryConfidence,
                    value: "\(Int(memoryConfidence * 100))%",
                    label: "Confidence",
                    tint: Color.LifePilot.accentAI,
                    size: 104
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Private demo memory", systemImage: "lock.fill")
                        .font(.LifePilot.utility)
                        .foregroundStyle(Color.LifePilot.signalSuccess)
                    Text("\(visibleFactCount) visible facts across \(visibleSections.count) context groups")
                        .font(.LifePilot.body.weight(.semibold))
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    Text("Tap any fact to verify or forget it.")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var visibleFactCount: Int {
        visibleSections.reduce(0) { $0 + $1.facts.count }
    }

    private var memoryConfidence: Double {
        guard visibleFactCount > 0 else { return 0 }
        return min(1, 0.72 + Double(confirmedFactIDs.count) * 0.06)
    }

    private func memorySection(_ section: MemorySection) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: section.title, symbolName: section.symbolName)

            CardContainer {
                VStack(spacing: 0) {
                    ForEach(Array(section.facts.enumerated()), id: \.element.id) { index, fact in
                        Button {
                            selectedMemory = MemorySelection(sectionTitle: section.title, fact: fact)
                        } label: {
                            factRow(fact)
                        }
                        .buttonStyle(.lifePilotPressable)
                        .accessibilityHint("Opens memory controls")
                        .accessibilityIdentifier("memory.fact.\(fact.id)")

                        if index < section.facts.count - 1 {
                            Divider().overlay(Color.LifePilot.glassBorder)
                        }
                    }
                }
            }
        }
    }

    private func factRow(_ fact: MemoryFact) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: fact.symbolName)
                .foregroundStyle(Color.LifePilot.accentAI)
                .frame(width: 38, height: 38)
                .background(Color.LifePilot.accentAI.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(fact.title)
                    .font(.LifePilot.body.weight(.semibold))
                    .foregroundStyle(Color.LifePilot.textPrimary)

                Text(fact.detail)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: Spacing.xs)

            Image(systemName: confirmedFactIDs.contains(fact.id) ? "checkmark.circle.fill" : "chevron.right")
                .foregroundStyle(
                    confirmedFactIDs.contains(fact.id)
                        ? Color.LifePilot.signalSuccess
                        : Color.LifePilot.textTertiary
                )
        }
        .frame(minHeight: 68)
        .contentShape(Rectangle())
    }

    private func memorySheet(_ selection: MemorySelection) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: selection.fact.symbolName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.LifePilot.accentAI)
                        .frame(width: 54, height: 54)
                        .background(Color.LifePilot.accentAI.opacity(0.14), in: Circle())
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(selection.sectionTitle.uppercased())
                            .font(.LifePilot.utility)
                            .foregroundStyle(Color.LifePilot.accentAI)
                        Text("Learned from connected demo sources")
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    }
                }

                Text(selection.fact.title)
                    .font(.LifePilot.titleMedium)
                    .foregroundStyle(Color.LifePilot.textPrimary)
                Text(selection.fact.detail)
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textSecondary)

                Spacer()

                Button("This is correct") {
                    confirmedFactIDs.insert(selection.fact.id)
                    selectedMemory = nil
                }
                .buttonStyle(.lifePilotPrimary)
                .accessibilityIdentifier("memory.confirm")

                Button("Forget for this session", role: .destructive) {
                    hiddenFactIDs.insert(selection.fact.id)
                    confirmedFactIDs.remove(selection.fact.id)
                    selectedMemory = nil
                }
                .buttonStyle(.lifePilotSecondary)
                .accessibilityIdentifier("memory.forget")
            }
            .padding(Spacing.lg)
            .lifePilotScreenBackground(energy: .subtle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { selectedMemory = nil }
                }
            }
        }
    }
}

private struct MemorySelection: Identifiable {
    var id: String { fact.id }
    let sectionTitle: String
    let fact: MemoryFact
}

#Preview {
    NavigationStack {
        MemoryView()
    }
}
