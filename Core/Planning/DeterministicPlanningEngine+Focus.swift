import Foundation

extension DeterministicPlanningEngine {
    static func missingBreaks(
        _ events: [CalendarEvent],
        preferences _: UserPreferences,
        now: Date
    ) -> [PlanningFinding] {
        let calendar = Calendar.current
        let workBlocks = events
            .filter {
                ($0.context == .work || $0.eventKind == .meeting)
                    && $0.status != .declined
                    && !$0.isAllDay
                    && calendar.isDate($0.startDate, inSameDayAs: now)
            }
            .sorted { $0.startDate < $1.startDate }
        guard workBlocks.count >= 3 else { return [] }
        let longestStreakMinutes = longestMeetingStreakMinutes(workBlocks)
        guard longestStreakMinutes >= 150 else { return [] }
        return [
            PlanningFinding(
                kind: .missingBreak,
                title: "Long stretch without a break",
                detail: "About \(longestStreakMinutes) consecutive meeting minutes today.",
                evidence: [
                    EvidenceItem(
                        summary: "Work blocks with ≤15m gaps totaling \(longestStreakMinutes)m",
                        sourceAgent: .planning,
                        observedAt: now,
                        relatedRecordIDs: workBlocks.map(\.id)
                    ),
                ],
                confidence: 0.7,
                riskLevel: .low,
                expiresAt: calendar.date(byAdding: .day, value: 1, to: now),
                suggestedActionSummary: "Protect a short break between meetings"
            ),
        ]
    }

    static func focusWindows(
        _ events: [CalendarEvent],
        preferences: UserPreferences,
        now: Date
    ) -> [PlanningFinding] {
        let calendar = Calendar.current
        guard let bounds = workDayBounds(preferences: preferences, now: now, calendar: calendar) else {
            return []
        }
        guard let gap = largestFocusGap(in: events, bounds: bounds, now: now) else {
            return []
        }
        return [
            PlanningFinding(
                kind: .focusWindow,
                title: "Focus window available",
                detail: "Roughly \(gap.minutes) minutes free starting "
                    + "\(gap.start.formatted(date: .omitted, time: .shortened)).",
                evidence: [
                    EvidenceItem(
                        summary: "Largest gap between events in work hours",
                        sourceAgent: .planning,
                        observedAt: now
                    ),
                ],
                confidence: 0.65,
                riskLevel: .low,
                suggestedActionSummary: "Schedule deep work or clear an overdue task"
            ),
        ]
    }

    private static func longestMeetingStreakMinutes(_ workBlocks: [CalendarEvent]) -> Int {
        var longestStreakMinutes = 0
        var streakStart = workBlocks[0].startDate
        var previousEnd = workBlocks[0].endDate
        for event in workBlocks.dropFirst() {
            let gap = event.startDate.timeIntervalSince(previousEnd)
            if gap <= 15 * 60 {
                previousEnd = max(previousEnd, event.endDate)
                longestStreakMinutes = max(
                    longestStreakMinutes,
                    Int(previousEnd.timeIntervalSince(streakStart) / 60)
                )
            } else {
                streakStart = event.startDate
                previousEnd = event.endDate
            }
        }
        return longestStreakMinutes
    }

    private static func workDayBounds(
        preferences: UserPreferences,
        now: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date)? {
        guard let windowStart = calendar.date(
            bySettingHour: preferences.workDayStartHour,
            minute: 0,
            second: 0,
            of: now
        ),
            let windowEnd = calendar.date(
                bySettingHour: preferences.workDayEndHour,
                minute: 0,
                second: 0,
                of: now
            )
        else {
            return nil
        }
        return (windowStart, windowEnd)
    }

    private static func largestFocusGap(
        in events: [CalendarEvent],
        bounds: (start: Date, end: Date),
        now: Date
    ) -> (start: Date, minutes: Int)? {
        let busy = events
            .filter {
                $0.status != .declined
                    && !$0.isAllDay
                    && $0.endDate > max(now, bounds.start)
                    && $0.startDate < bounds.end
            }
            .sorted { $0.startDate < $1.startDate }

        var cursor = max(now, bounds.start)
        var bestGap: (start: Date, minutes: Int)?
        for event in busy {
            if event.startDate > cursor {
                let minutes = Int(event.startDate.timeIntervalSince(cursor) / 60)
                if minutes >= 45, bestGap == nil || minutes > (bestGap?.minutes ?? 0) {
                    bestGap = (cursor, minutes)
                }
            }
            cursor = max(cursor, event.endDate)
        }
        if bounds.end > cursor {
            let minutes = Int(bounds.end.timeIntervalSince(cursor) / 60)
            if minutes >= 45, bestGap == nil || minutes > (bestGap?.minutes ?? 0) {
                bestGap = (cursor, minutes)
            }
        }
        return bestGap
    }
}
