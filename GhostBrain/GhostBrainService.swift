import Foundation
import LifePilotCore

/// On-device context fusion for the current day. The service reads only local
/// stores and explicitly authorized Apple sources, then applies deterministic
/// planning rules. A failed optional source never prevents a partial briefing.
public struct GhostBrainService: GhostBrainServing {
    private let taskStore: any TaskStore
    private let eventStore: any EventStore
    private let preferenceStore: any PreferenceStore
    private let calendarIntegration: any CalendarIntegrating
    private let remindersIntegration: any RemindersIntegrating
    private let weatherIntegration: any WeatherIntegrating
    private let planningEngine: any PlanningEngine
    private let clock: any ClockProviding

    public init(
        taskStore: any TaskStore,
        eventStore: any EventStore,
        preferenceStore: any PreferenceStore,
        calendarIntegration: any CalendarIntegrating = UnavailableCalendarIntegration(),
        remindersIntegration: any RemindersIntegrating = UnavailableRemindersIntegration(),
        weatherIntegration: any WeatherIntegrating = UnavailableWeatherIntegration(),
        planningEngine: any PlanningEngine = DeterministicPlanningEngine(),
        clock: any ClockProviding = SystemClock()
    ) {
        self.taskStore = taskStore
        self.eventStore = eventStore
        self.preferenceStore = preferenceStore
        self.calendarIntegration = calendarIntegration
        self.remindersIntegration = remindersIntegration
        self.weatherIntegration = weatherIntegration
        self.planningEngine = planningEngine
        self.clock = clock
    }

    public func currentModel() async throws -> GhostBrainModel {
        let now = clock.now()
        async let localTasks = taskStore.allTasks()
        async let localEvents = eventStore.allEvents()
        async let preferences = preferenceStore.loadPreferences()
        async let remoteEvents = authorizedCalendarEvents(relativeTo: now)
        async let remoteReminders = authorizedReminders()
        async let weather = authorizedWeather()

        let tasks = Self.mergeTasks(local: await localTasks, remote: await remoteReminders)
        let events = Self.mergeEvents(local: await localEvents, remote: await remoteEvents)
        let userPreferences = await preferences
        let weatherSnapshot = await weather
        var findings = planningEngine.analyze(
            events: events,
            tasks: tasks,
            preferences: userPreferences,
            now: now
        )
        if let weatherSnapshot, weatherSnapshot.precipitationChance >= 0.5 {
            findings.append(Self.weatherFinding(weatherSnapshot, now: now))
        }

        return GhostBrainModel(
            generatedAt: now,
            greetingContext: Self.greetingContext(for: now),
            recommendations: Self.recommendations(from: findings, now: now),
            upcomingEvents: events
                .filter { $0.endDate > now && $0.status != .declined }
                .sorted { $0.startDate < $1.startDate },
            signals: Self.signals(
                events: events,
                tasks: tasks,
                weather: weatherSnapshot,
                relativeTo: now
            )
        )
    }

    private func authorizedCalendarEvents(relativeTo now: Date) async -> [CalendarEvent] {
        let state = await calendarIntegration.authorizationState()
        guard state == .authorized || state == .limited else { return [] }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? now.addingTimeInterval(604_800)
        return (try? await calendarIntegration.fetchEvents(from: start, to: end)) ?? []
    }

    private func authorizedReminders() async -> [TaskItem] {
        let state = await remindersIntegration.authorizationState()
        guard state == .authorized || state == .limited else { return [] }
        return (try? await remindersIntegration.fetchOpenReminders()) ?? []
    }

    private func authorizedWeather() async -> WeatherSnapshot? {
        let state = await weatherIntegration.authorizationState()
        guard state == .authorized || state == .limited else { return nil }
        return try? await weatherIntegration.currentWeather()
    }

    private static func mergeTasks(local: [TaskItem], remote: [TaskItem]) -> [TaskItem] {
        var result = local
        var externalIDs = Set(local.compactMap(\.externalIdentifier))
        for task in remote {
            if let identifier = task.externalIdentifier {
                guard externalIDs.insert(identifier).inserted else { continue }
            } else if result.contains(where: {
                $0.title.caseInsensitiveCompare(task.title) == .orderedSame && $0.dueDate == task.dueDate
            }) {
                continue
            }
            result.append(task)
        }
        return result
    }

    private static func mergeEvents(local: [CalendarEvent], remote: [CalendarEvent]) -> [CalendarEvent] {
        var result = local
        var externalIDs = Set(local.compactMap(\.externalIdentifier))
        for event in remote {
            if let identifier = event.externalIdentifier {
                guard externalIDs.insert(identifier).inserted else { continue }
            } else if result.contains(where: {
                $0.title.caseInsensitiveCompare(event.title) == .orderedSame
                    && $0.startDate == event.startDate
                    && $0.endDate == event.endDate
            }) {
                continue
            }
            result.append(event)
        }
        return result.sorted { $0.startDate < $1.startDate }
    }

    private static func recommendations(
        from findings: [PlanningFinding],
        now: Date
    ) -> [RecommendationModel] {
        var seen: Set<String> = []
        return findings
            .filter { $0.expiresAt == nil || ($0.expiresAt ?? now) > now }
            .compactMap { finding -> RecommendationModel? in
                let source = finding.evidence.first?.sourceAgent ?? .planning
                let key = "\(source.rawValue)|\(finding.title.lowercased())"
                guard seen.insert(key).inserted else { return nil }
                return RecommendationModel(
                    id: deterministicID(key),
                    title: finding.title,
                    reasoning: finding.detail,
                    sourceAgent: source,
                    riskLevel: finding.riskLevel,
                    urgency: urgency(for: finding),
                    createdAt: now,
                    evidence: finding.evidence,
                    freshness: freshness(for: finding.evidence)
                )
            }
            .sorted { left, right in
                if left.urgency != right.urgency { return left.urgency > right.urgency }
                if left.riskLevel != right.riskLevel { return riskOrder(left.riskLevel) > riskOrder(right.riskLevel) }
                return left.title.localizedCaseInsensitiveCompare(right.title) == .orderedAscending
            }
    }

    private static func signals(
        events: [CalendarEvent],
        tasks: [TaskItem],
        weather: WeatherSnapshot?,
        relativeTo now: Date
    ) -> [DaySignal] {
        var result = events
            .filter { $0.endDate > now && $0.status != .declined }
            .prefix(8)
            .map {
                DaySignal(
                    id: deterministicID("event|\($0.externalIdentifier ?? $0.id.uuidString)"),
                    kind: .event,
                    title: $0.title,
                    subtitle: $0.location,
                    timestamp: $0.startDate,
                    sourceAgent: .calendar,
                    freshness: $0.source == .local ? .cached : .live
                )
            }
        result.append(contentsOf: tasks
            .filter { !$0.isCompleted && $0.dueDate != nil }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(8)
            .map {
                DaySignal(
                    id: deterministicID("task|\($0.externalIdentifier ?? $0.id.uuidString)"),
                    kind: $0.source == .eventKitReminders ? .reminder : .task,
                    title: $0.title,
                    subtitle: $0.dueDate?.formatted(date: .abbreviated, time: .shortened),
                    timestamp: $0.dueDate ?? now,
                    sourceAgent: $0.source == .eventKitReminders ? .reminder : .task,
                    freshness: $0.source == .eventKitReminders ? .live : .cached
                )
            })
        if let weather {
            result.append(DaySignal(
                id: deterministicID("weather|\(weather.asOf.timeIntervalSince1970)"),
                kind: .weather,
                title: weather.condition.rawValue.capitalized,
                subtitle: "\(weather.temperatureFahrenheit)°F · "
                    + "\(Int(weather.precipitationChance * 100))% precipitation",
                timestamp: weather.asOf,
                sourceAgent: .weather,
                freshness: now.timeIntervalSince(weather.asOf) < 3_600 ? .live : .cached
            ))
        }
        return result.sorted { $0.timestamp < $1.timestamp }
    }

    private static func weatherFinding(_ weather: WeatherSnapshot, now: Date) -> PlanningFinding {
        PlanningFinding(
            kind: .weatherImpact,
            title: weather.condition == .storm ? "Stormy conditions may affect plans" : "Rain may affect outdoor plans",
            detail: "WeatherKit reports a \(Int(weather.precipitationChance * 100))% precipitation chance.",
            evidence: [EvidenceItem(
                summary: "Current WeatherKit forecast",
                sourceAgent: .weather,
                observedAt: weather.asOf,
                freshness: now.timeIntervalSince(weather.asOf) < 3_600 ? .live : .cached
            )],
            confidence: 0.8,
            riskLevel: weather.condition == .storm ? .medium : .low,
            expiresAt: now.addingTimeInterval(6 * 3_600),
            suggestedActionSummary: "Allow extra time and check conditions before leaving"
        )
    }

    private static func greetingContext(for date: Date) -> GhostBrainModel.GreetingContext {
        let hour = Calendar.current.component(.hour, from: date)
        let timeOfDay: GreetingTimeOfDay = switch hour {
        case 0 ..< 12: .morning
        case 12 ..< 17: .afternoon
        default: .evening
        }
        return GhostBrainModel.GreetingContext(userFirstName: "there", timeOfDay: timeOfDay)
    }

    private static func urgency(for finding: PlanningFinding) -> RecommendationModel.Urgency {
        switch finding.riskLevel {
        case .high: .high
        case .medium: .normal
        case .low: .low
        }
    }

    private static func freshness(for evidence: [EvidenceItem]) -> DataFreshness {
        if evidence.contains(where: { $0.freshness == .unavailable }) { return .unavailable }
        if evidence.contains(where: { $0.freshness == .stale }) { return .stale }
        if evidence.contains(where: { $0.freshness == .cached }) { return .cached }
        if evidence.contains(where: { $0.freshness == .unknown }) { return .unknown }
        return evidence.isEmpty ? .unknown : .live
    }

    private static func riskOrder(_ risk: RiskLevel) -> Int {
        switch risk {
        case .low: 0
        case .medium: 1
        case .high: 2
        }
    }

    private static func deterministicID(_ value: String) -> UUID {
        let first = fnv1a(value.utf8, seed: 14_695_981_039_346_656_037)
        let second = fnv1a(value.utf8.reversed(), seed: 10_995_116_282_111)
        let hex = String(format: "%016llx%016llx", first, second)
        let formatted = "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-5\(hex.dropFirst(13).prefix(3))-"
            + "a\(hex.dropFirst(17).prefix(3))-\(hex.dropFirst(20).prefix(12))"
        return UUID(uuidString: formatted) ?? UUID()
    }

    private static func fnv1a<S: Sequence>(_ bytes: S, seed: UInt64) -> UInt64 where S.Element == UInt8 {
        bytes.reduce(seed) { partial, byte in
            (partial ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }
}
