import Foundation
import ImageIO
import Vision

public struct ScheduleImportDraft: Identifiable, Sendable {
    public let id = UUID()
    public var title: String
    public var location: String
    public var startDate: Date
    public var endDate: Date
    public let recognizedText: String

    public init(
        title: String,
        location: String,
        startDate: Date,
        endDate: Date,
        recognizedText: String
    ) {
        self.title = title
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.recognizedText = recognizedText
    }
}

public enum ScheduleScreenshotParser {
    public static func parse(imageData: Data, referenceDate: Date = Date()) async throws -> ScheduleImportDraft {
        guard
            let source = CGImageSourceCreateWithData(imageData as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ScheduleImportError.invalidImage
        }

        let lines = try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-GB", "en-US"]

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try handler.perform([request])

            return (request.results ?? [])
                .sorted { first, second in
                    if abs(first.boundingBox.midY - second.boundingBox.midY) > 0.02 {
                        return first.boundingBox.midY > second.boundingBox.midY
                    }
                    return first.boundingBox.minX < second.boundingBox.minX
                }
                .compactMap { $0.topCandidates(1).first?.string }
        }.value

        guard !lines.isEmpty else {
            throw ScheduleImportError.noTextFound
        }
        return draft(from: lines, referenceDate: referenceDate)
    }

    public static func draft(from recognizedLines: [String], referenceDate: Date = Date()) -> ScheduleImportDraft {
        let lines = recognizedLines
            .map(normalize)
            .filter { !$0.isEmpty }
        let timeMatch = firstTimeMatch(in: lines)
        let eventDate = firstDate(in: lines, referenceDate: referenceDate)
        let calendar = Calendar.current

        let startDate = calendar.date(
            bySettingHour: timeMatch?.startHour ?? calendar.component(.hour, from: referenceDate),
            minute: timeMatch?.startMinute ?? 0,
            second: 0,
            of: eventDate
        ) ?? referenceDate

        let proposedEnd = calendar.date(
            bySettingHour: timeMatch?.endHour ?? (calendar.component(.hour, from: startDate) + 1) % 24,
            minute: timeMatch?.endMinute ?? calendar.component(.minute, from: startDate),
            second: 0,
            of: eventDate
        ) ?? startDate.addingTimeInterval(3600)
        let endDate = proposedEnd > startDate ? proposedEnd : startDate.addingTimeInterval(3600)

        let location = lines.first(where: looksLikeLocation) ?? ""
        let title = lines.first { line in
            !looksLikeDateOrTime(line)
                && !looksLikeLocation(line)
                && !isGenericHeading(line)
                && line.count >= 3
        } ?? "Imported schedule event"

        return ScheduleImportDraft(
            title: title,
            location: location,
            startDate: startDate,
            endDate: endDate,
            recognizedText: lines.joined(separator: "\n")
        )
    }

    private static func normalize(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\u{2013}", with: "-")
            .replacingOccurrences(of: "\u{2014}", with: "-")
            .replacingOccurrences(of: "•", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstDate(in lines: [String], referenceDate: Date) -> Date {
        let locale = Locale(identifier: "en_GB")
        let formats = [
            "EEEE d MMMM yyyy", "EEEE, d MMMM yyyy", "d MMMM yyyy", "d MMM yyyy",
            "dd/MM/yyyy", "d/M/yyyy", "EEEE d MMMM", "d MMMM", "d MMM",
        ]

        for line in lines {
            let candidate = removingTimes(from: line)
                .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            for format in formats {
                let formatter = DateFormatter()
                formatter.locale = locale
                formatter.timeZone = .current
                formatter.dateFormat = format
                formatter.defaultDate = referenceDate
                if let date = formatter.date(from: candidate) {
                    return date
                }
            }
        }
        return referenceDate
    }

    private static func firstTimeMatch(in lines: [String]) -> TimeMatch? {
        let rangePattern = #"(?i)\b([01]?\d|2[0-3])[:.]([0-5]\d)\s*(am|pm)?"#
            + #"\s*(?:-|to)\s*([01]?\d|2[0-3])[:.]([0-5]\d)\s*(am|pm)?\b"#
        let singlePattern = #"(?i)\b([01]?\d|2[0-3])[:.]([0-5]\d)\s*(am|pm)?\b"#

        for line in lines {
            if let groups = captureGroups(pattern: rangePattern, in: line), groups.count == 6 {
                let startHour = adjustedHour(groups[0], marker: groups[2])
                let endMarker = groups[5].isEmpty ? groups[2] : groups[5]
                return TimeMatch(
                    startHour: startHour,
                    startMinute: Int(groups[1]) ?? 0,
                    endHour: adjustedHour(groups[3], marker: endMarker),
                    endMinute: Int(groups[4]) ?? 0
                )
            }
        }

        for line in lines {
            if let groups = captureGroups(pattern: singlePattern, in: line), groups.count == 3 {
                let startHour = adjustedHour(groups[0], marker: groups[2])
                return TimeMatch(
                    startHour: startHour,
                    startMinute: Int(groups[1]) ?? 0,
                    endHour: (startHour + 1) % 24,
                    endMinute: Int(groups[1]) ?? 0
                )
            }
        }
        return nil
    }

    private static func captureGroups(pattern: String, in value: String) -> [String]? {
        guard
            let expression = try? NSRegularExpression(pattern: pattern),
            let match = expression.firstMatch(in: value, range: NSRange(value.startIndex..., in: value))
        else { return nil }

        return (1 ..< match.numberOfRanges).map { index in
            let range = match.range(at: index)
            guard range.location != NSNotFound, let swiftRange = Range(range, in: value) else { return "" }
            return String(value[swiftRange])
        }
    }

    private static func adjustedHour(_ value: String, marker: String) -> Int {
        let hour = Int(value) ?? 0
        switch marker.lowercased() {
        case "pm" where hour < 12: return hour + 12
        case "am" where hour == 12: return 0
        default: return hour
        }
    }

    private static func removingTimes(from value: String) -> String {
        value.replacingOccurrences(
            of: #"(?i)\b([01]?\d|2[0-3])[:.]([0-5]\d)\s*(am|pm)?"#
                + #"(?:\s*(?:-|to)\s*([01]?\d|2[0-3])[:.]([0-5]\d)\s*(am|pm)?)?\b"#,
            with: "",
            options: .regularExpression
        )
    }

    private static func looksLikeDateOrTime(_ value: String) -> Bool {
        value.range(of: #"\b([01]?\d|2[0-3])[:.]([0-5]\d)\b"#, options: .regularExpression) != nil
            || value.range(
                of: #"(?i)\b(mon|tue|wed|thu|fri|sat|sun|january|february|march|april|may|june|july"#
                    + #"|august|september|october|november|december)\b"#,
                options: .regularExpression
            ) != nil
            || value.range(of: #"\b\d{1,2}/\d{1,2}/\d{2,4}\b"#, options: .regularExpression) != nil
    }

    private static func looksLikeLocation(_ value: String) -> Bool {
        value.range(
            of: #"(?i)\b(room|lab|building|campus|international house|teams|zoom|library|lecture theatre|floor)\b"#,
            options: .regularExpression
        ) != nil
    }

    private static func isGenericHeading(_ value: String) -> Bool {
        let normalized = value.lowercased()
        return normalized.contains("timetable")
            || normalized.contains("schedule")
            || normalized == "calendar"
            || normalized == "event"
    }

    private struct TimeMatch {
        let startHour: Int
        let startMinute: Int
        let endHour: Int
        let endMinute: Int
    }
}

public enum ScheduleImportError: LocalizedError {
    case invalidImage
    case noTextFound

    public var errorDescription: String? {
        switch self {
        case .invalidImage: "That screenshot could not be opened. Choose another image."
        case .noTextFound: "No schedule text was found. Try a clearer screenshot."
        }
    }
}
