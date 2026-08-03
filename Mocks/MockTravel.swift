import Foundation
import LifePilotCore

/// Realistic sample travel itinerary data for previews, tests, and Phase
/// 3's mock-driven screens.
public enum MockTravel {
    public static func itineraries(relativeTo now: Date = Date()) -> [TravelItinerary] {
        let day: TimeInterval = 24 * 60 * 60
        let firstDeparture = now.addingTimeInterval(2 * day)
        let firstArrival = firstDeparture.addingTimeInterval(2 * 3600 + 10 * 60)
        let secondDeparture = now.addingTimeInterval(9 * day)
        let secondArrival = secondDeparture.addingTimeInterval(2 * 3600 + 15 * 60)

        return [
            TravelItinerary(
                carrier: "Avanti West Coast",
                identifier: "1A23",
                origin: "Manchester Piccadilly",
                destination: "London Euston",
                departureDate: firstDeparture,
                arrivalDate: firstArrival,
                status: .delayed
            ),
            TravelItinerary(
                carrier: "LNER",
                identifier: "1D18",
                origin: "London King's Cross",
                destination: "Leeds",
                departureDate: secondDeparture,
                arrivalDate: secondArrival,
                status: .onTime
            ),
        ]
    }
}
