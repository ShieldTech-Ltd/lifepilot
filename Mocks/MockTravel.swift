import Foundation
import LifePilotCore

/// Realistic sample travel itinerary data for previews, tests, and Phase
/// 3's mock-driven screens.
public enum MockTravel {
    public static func itineraries(relativeTo now: Date = Date()) -> [TravelItinerary] {
        [
            TravelItinerary(
                carrier: "Avanti West Coast",
                identifier: "1A23",
                origin: "Manchester Piccadilly",
                destination: "London Euston",
                departureDate: now.addingTimeInterval(2 * 24 * 3600),
                arrivalDate: now.addingTimeInterval(2 * 24 * 3600 + 2 * 3600 + 10 * 60),
                status: .delayed
            ),
            TravelItinerary(
                carrier: "LNER",
                identifier: "1D18",
                origin: "London King's Cross",
                destination: "Leeds",
                departureDate: now.addingTimeInterval(9 * 24 * 3600),
                arrivalDate: now.addingTimeInterval(9 * 24 * 3600 + 2 * 3600 + 15 * 60),
                status: .onTime
            ),
        ]
    }
}
