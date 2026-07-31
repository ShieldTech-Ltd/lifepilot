import Foundation
import LifePilotGhostBrain

/// Derives visible memory from the shared session and its enabled sources.
@Observable
@MainActor
public final class MemoryViewModel {
    public let session: DemoSessionStore

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public convenience init() {
        self.init(session: DemoSessionStore(ghostBrain: MockRecommendationProvider()))
    }

    public var sections: [MemorySection] {
        var result: [MemorySection] = []

        if session.emailEnabled {
            let people = session.emailMessages.compactMap { message -> MemoryFact? in
                if message.sender.contains("Priya") {
                    return MemoryFact(
                        id: "person-priya",
                        symbolName: "person.fill",
                        title: message.sender,
                        detail: "Frequent collaborator — usually about the Q3 roadmap."
                    )
                }
                if message.sender.contains("Sam") {
                    return MemoryFact(
                        id: "person-sam",
                        symbolName: "person.fill",
                        title: message.sender,
                        detail: "Regular lunch plans, usually at Tatte Bakery."
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
            if let pickup = session.visibleEvents.first(where: { $0.title == "School Pickup" }) {
                routines.append(MemoryFact(
                    id: "routine-pickup",
                    symbolName: "repeat",
                    title: pickup.title,
                    detail: "Recurring on weekdays around \(pickup.startDate.formatted(date: .omitted, time: .shortened))."
                ))
            }
            if let standup = session.visibleEvents.first(where: { $0.title.contains("Standup") }) {
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
                    title: "Prefers \(preferredCarrier)",
                    detail: "Most frequently booked carrier."
                ),
            ]
            if session.travelItineraries.contains(where: { $0.status == .delayed }) {
                travelFacts.append(MemoryFact(
                    id: "travel-buffer",
                    symbolName: "clock.badge.exclamationmark",
                    title: "Buffer around travel",
                    detail: "Learned to flag tight connections after past delays."
                ))
            }
            result.append(MemorySection(id: "travel", title: "Travel", symbolName: "airplane", facts: travelFacts))
        }

        return result
    }

    public func load() async {
        await session.prepare()
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
