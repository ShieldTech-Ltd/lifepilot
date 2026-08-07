import Foundation
import LifePilotCore
import LifePilotGhostBrain

/// Derives visible memory from the shared session and its enabled sources.
@Observable
@MainActor
public final class MemoryViewModel {
    public let session: DemoSessionStore
    public private(set) var memoryItems: [MemoryItem] = []
    public private(set) var selectedKind: MemoryItem.Kind?
    private let preferenceStore: (any PreferenceStore)?

    public init(session: DemoSessionStore) {
        self.session = session
        preferenceStore = nil
    }

    public convenience init() {
        self.init(session: DemoSessionStore(ghostBrain: MockRecommendationProvider()))
    }

    public init(preferenceStore: any PreferenceStore) {
        session = DemoSessionStore(ghostBrain: MockRecommendationProvider())
        self.preferenceStore = preferenceStore
    }

    public var filteredItems: [MemoryItem] {
        guard let selectedKind else { return memoryItems }
        return memoryItems.filter { $0.kind == selectedKind }
    }

    public var pinnedItems: [MemoryItem] {
        filteredItems.filter(\.isPinned)
    }

    public func setKind(_ kind: MemoryItem.Kind?) {
        selectedKind = kind
    }

    public var sections: [MemorySection] {
        if !memoryItems.isEmpty {
            return MemoryItem.Kind.allCases.compactMap { kind in
                let items = memoryItems.filter { $0.kind == kind }
                guard !items.isEmpty else { return nil }
                return MemorySection(
                    id: kind.rawValue,
                    title: kind.rawValue.titleCased,
                    symbolName: symbolName(for: kind),
                    facts: items.map {
                        MemoryFact(
                            id: $0.id.uuidString,
                            symbolName: symbolName(for: $0.kind),
                            title: $0.title,
                            detail: $0.detail ?? "Saved from \($0.provenance)."
                        )
                    }
                )
            }
        }
        var result: [MemorySection] = []

        if session.emailEnabled {
            let people = session.emailMessages.compactMap { message -> MemoryFact? in
                if message.sender.contains("Sarah") {
                    return MemoryFact(
                        id: "person-sarah",
                        symbolName: "person.fill",
                        title: message.sender,
                        detail: "A contact connected to important plans and follow-ups."
                    )
                }
                if message.sender.contains("Maya") {
                    return MemoryFact(
                        id: "person-maya",
                        symbolName: "person.fill",
                        title: message.sender,
                        detail: "LifePilot teammate and regular project collaborator."
                    )
                }
                return nil
            }
            if !people.isEmpty {
                result.append(MemorySection(id: "people", title: "People", symbolName: "person.2.fill", facts: people))
            }
        }

        if session.calendarEnabled {
            var routines: [MemoryFact] = []
            if let projectLab = session.visibleEvents.first(where: { $0.title == "Work shift" }) {
                routines.append(MemoryFact(
                    id: "routine-project-lab",
                    symbolName: "repeat",
                    title: projectLab.title,
                    detail: "Usually scheduled around "
                        + projectLab.startDate.formatted(date: .omitted, time: .shortened)
                        + "."
                ))
            }
            if let standup = session.visibleEvents.first(where: { $0.title.contains("Stand-up") }) {
                routines.append(MemoryFact(
                    id: "routine-standup",
                    symbolName: "repeat",
                    title: standup.title,
                    detail: "Recurring every weekday morning."
                ))
            }
            if !routines.isEmpty {
                result.append(MemorySection(id: "routines", title: "Routines", symbolName: "repeat", facts: routines))
            }
        }

        if session.travelEnabled, let preferredCarrier = session.travelItineraries.first?.carrier {
            var travelFacts = [
                MemoryFact(
                    id: "travel-carrier",
                    symbolName: "airplane",
                    title: "Usually travels with \(preferredCarrier)",
                    detail: "Most frequent travel provider in the available context."
                ),
            ]
            if session.travelItineraries.contains(where: { $0.status == .delayed }) {
                travelFacts.append(MemoryFact(
                    id: "travel-buffer",
                    symbolName: "clock.badge.exclamationmark",
                    title: "Buffer around travel",
                    detail: "Flags extra station time when rail disruption is likely."
                ))
            }
            result.append(MemorySection(id: "travel", title: "Travel", symbolName: "airplane", facts: travelFacts))
        }

        return result
    }

    public func load() async {
        if let preferenceStore {
            memoryItems = await preferenceStore.allMemory()
        } else {
            await session.prepare()
            memoryItems = session.memoryItems
        }
    }

    private func symbolName(for kind: MemoryItem.Kind) -> String {
        switch kind {
        case .preference: "slider.horizontal.3"
        case .routine: "repeat"
        case .place: "mappin.and.ellipse"
        case .person: "person.fill"
        case .workPattern: "briefcase.fill"
        case .travelBuffer: "clock.badge.exclamationmark"
        case .quietHours: "moon.fill"
        case .correction: "checkmark.bubble.fill"
        }
    }
}

private extension String {
    var titleCased: String {
        replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
    }
}

public struct MemorySection: Identifiable {
    public let id: String
    public let title: String
    public let symbolName: String
    public let facts: [MemoryFact]
}

public struct MemoryFact: Identifiable {
    public let id: String
    public let symbolName: String
    public let title: String
    public let detail: String
}
