import Foundation

public enum CalendarInvitationParser {
    public static func draft(from content: String, referenceDate: Date = Date()) -> ScheduleImportDraft {
        let normalizedContent = content
            .replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")
            .replacingOccurrences(of: "\r", with: "\n")

        if normalizedContent.uppercased().contains("BEGIN:VEVENT") {
            return calendarDraft(from: normalizedContent, referenceDate: referenceDate)
        }

        let text = normalizedContent.replacingOccurrences(
            of: #"<[^>]+>"#,
            with: " ",
            options: .regularExpression
        )
        return ScheduleScreenshotParser.draft(
            from: text.components(separatedBy: .newlines),
            referenceDate: referenceDate
        )
    }

    private static func calendarDraft(from content: String, referenceDate: Date) -> ScheduleImportDraft {
        let lines = content.components(separatedBy: .newlines)
        let title = value(for: "SUMMARY", in: lines) ?? "Calendar invitation"
        let location = value(for: "LOCATION", in: lines) ?? ""
        let startDate = value(for: "DTSTART", in: lines).flatMap(parseCalendarDate) ?? referenceDate
        let parsedEndDate = value(for: "DTEND", in: lines).flatMap(parseCalendarDate)
        let endDate = parsedEndDate.map { $0 > startDate ? $0 : startDate.addingTimeInterval(3600) }
            ?? startDate.addingTimeInterval(3600)

        return ScheduleImportDraft(
            title: unescape(title),
            location: unescape(location),
            startDate: startDate,
            endDate: endDate,
            recognizedText: content
        )
    }

    private static func value(for key: String, in lines: [String]) -> String? {
        for line in lines {
            let uppercased = line.uppercased()
            guard uppercased.hasPrefix(key), let separator = line.firstIndex(of: ":") else { continue }
            return String(line[line.index(after: separator)...])
        }
        return nil
    }

    private static func parseCalendarDate(_ value: String) -> Date? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.hasSuffix("Z") {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            return formatter.date(from: trimmedValue)
        }

        let digits = trimmedValue.replacingOccurrences(of: "T", with: "")
        guard digits.count == 8 || digits.count == 14 else { return nil }
        let values = digits.map(String.init)
        func integer(_ range: Range<Int>) -> Int? {
            guard range.upperBound <= values.count else { return nil }
            return Int(values[range].joined())
        }

        var components = DateComponents()
        components.year = integer(0 ..< 4)
        components.month = integer(4 ..< 6)
        components.day = integer(6 ..< 8)
        if digits.count == 14 {
            components.hour = integer(8 ..< 10)
            components.minute = integer(10 ..< 12)
            components.second = integer(12 ..< 14)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar.date(from: components)
    }

    private static func unescape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
