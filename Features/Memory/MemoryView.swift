import LifePilotDesignSystem
import SwiftUI

/// The Memory tab — what Ghost Brain has learned about people, routines,
/// and travel from today's signals, per README.md's Memory feature
/// description. Backed by `MemoryViewModel`, which derives its content
/// from the same `LifePilotMocks` data Home and Timeline use, so this
/// screen tells the same story rather than a disconnected one.
public struct MemoryView: View {
    @State private var viewModel: MemoryViewModel

    public init(session: DemoSessionStore) {
        _viewModel = State(initialValue: MemoryViewModel(session: session))
    }

    public init() {
        self.init(session: DemoSessionStore())
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("What Ghost Brain Remembers")
                        .font(.LifePilot.titleLarge)
                        .foregroundStyle(Color.LifePilot.textPrimary)

                    Text("Built from patterns across your calendar, inbox, and trips — never shared, always visible.")
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }

                if viewModel.sections.isEmpty {
                    EmptyStateView(
                        symbolName: "brain.head.profile",
                        message: "Ghost Brain hasn't learned anything yet today."
                    )
                } else {
                    ForEach(viewModel.sections) { section in
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            SectionHeader(title: section.title, symbolName: section.symbolName)

                            CardContainer {
                                VStack(spacing: 0) {
                                    ForEach(section.facts) { fact in
                                        factRow(fact)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.LifePilot.backgroundPrimary)
        .navigationTitle("Memory")
        .task { await viewModel.load() }
    }

    private func factRow(_ fact: MemoryFact) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: fact.symbolName)
                .foregroundStyle(LinearGradient.LifePilot.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(fact.title)
                    .font(.LifePilot.body.weight(.semibold))
                    .foregroundStyle(Color.LifePilot.textPrimary)

                Text(fact.detail)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        MemoryView()
    }
}
