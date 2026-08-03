import Foundation

/// Provenance for a planning finding or recommendation.
public struct EvidenceItem: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var summary: String
    public var sourceAgent: AgentKind
    public var observedAt: Date
    public var freshness: DataFreshness
    public var relatedRecordIDs: [UUID]

    public init(
        id: UUID = UUID(),
        summary: String,
        sourceAgent: AgentKind,
        observedAt: Date,
        freshness: DataFreshness = .live,
        relatedRecordIDs: [UUID] = []
    ) {
        self.id = id
        self.summary = summary
        self.sourceAgent = sourceAgent
        self.observedAt = observedAt
        self.freshness = freshness
        self.relatedRecordIDs = relatedRecordIDs
    }
}

/// A structured planning finding before it becomes a user-facing recommendation.
public struct PlanningFinding: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var kind: Kind
    public var title: String
    public var detail: String
    public var evidence: [EvidenceItem]
    public var confidence: Double
    public var riskLevel: RiskLevel
    public var expiresAt: Date?
    public var suggestedActionSummary: String?

    public init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        detail: String,
        evidence: [EvidenceItem],
        confidence: Double,
        riskLevel: RiskLevel = .low,
        expiresAt: Date? = nil,
        suggestedActionSummary: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.evidence = evidence
        self.confidence = min(1, max(0, confidence))
        self.riskLevel = riskLevel
        self.expiresAt = expiresAt
        self.suggestedActionSummary = suggestedActionSummary
    }

    public enum Kind: String, CaseIterable, Sendable, Codable {
        case overlappingEvents
        case insufficientTravelOrPreparation
        case overdueTask
        case atRiskTask
        case impossibleWorkload
        case outsideWorkHours
        case missingBreak
        case focusWindow
        case upcomingDeadline
        case weatherImpact
        case staleData
        case disconnectedSource
    }
}
