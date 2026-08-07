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

    public let userName: String
    public let context: String

    public init(userName: String, context: String) {
        self.userName = userName
        self.context = context
    }
}
#endif
