import Foundation
import LifePilotCore

/// Realistic sample transaction data for previews, tests, and Phase 3's
/// mock-driven screens.
public enum MockFinance {
    public static func transactions(relativeTo now: Date = Date()) -> [FinanceTransaction] {
        [
            FinanceTransaction(
                merchant: "Pret A Manger",
                amountCents: 685,
                category: .dining,
                date: now.addingTimeInterval(-18 * 3600)
            ),
            FinanceTransaction(
                merchant: "Transport for London",
                amountCents: 850,
                category: .transport,
                date: now.addingTimeInterval(-3 * 24 * 3600)
            ),
            FinanceTransaction(
                merchant: "Unfamiliar Merchant #4471",
                amountCents: 3400,
                category: .other,
                date: now.addingTimeInterval(-2 * 3600),
                isAnomalous: true
            ),
            FinanceTransaction(
                merchant: "Cloud Storage",
                amountCents: 299,
                category: .subscriptions,
                date: now.addingTimeInterval(-5 * 24 * 3600)
            ),
        ]
    }
}
