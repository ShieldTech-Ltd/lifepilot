#if os(iOS) && canImport(ActivityKit)
import ActivityKit
import Foundation

public struct LifePilotActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let nextItem: String
        public let detail: String
        public let progress: Double

        public init(nextItem: String, detail: String, progress: Double) {
            self.nextItem = nextItem
            self.detail = detail
            self.progress = progress
        }
    }

    public let studentName: String
    public let context: String

    public init(studentName: String, context: String) {
        self.studentName = studentName
        self.context = context
    }
}
#endif
