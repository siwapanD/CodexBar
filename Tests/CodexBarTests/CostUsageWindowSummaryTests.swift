import CodexBarCore
import Foundation
import Testing

struct CostUsageWindowSummaryTests {
    @Test
    func `summary with allTimeDaysMarker aggregates all loaded daily entries`() {
        let snapshot = Self.snapshot(historyDays: 30)
        let summary = snapshot.summary(forLastDays: CostUsageTokenSnapshot.allTimeDaysMarker, calendar: Self.utcCalendar)

        #expect(summary.days == CostUsageTokenSnapshot.allTimeDaysMarker)
        #expect(summary.entryCount == 3)
        #expect(summary.totalCostUSD == 10) // 1 + 4 + 5
        #expect(summary.totalTokens == 1000) // 100 + 400 + 500
        #expect(summary.totalRequests == 10) // 1 + 4 + 5
    }

    @Test
    func `summaries use calendar windows instead of the last nonempty rows`() {
        let snapshot = Self.snapshot(historyDays: 90)
        let summary = snapshot.summary(forLastDays: 7, calendar: Self.utcCalendar)

        #expect(summary.days == 7)
        #expect(summary.entryCount == 2)
        #expect(summary.totalCostUSD == 9)
        #expect(summary.totalTokens == 900)
        #expect(summary.totalRequests == 9)
    }

    @Test
    func `comparison periods are unique sorted and bounded by scanned history`() {
        let snapshot = Self.snapshot(historyDays: 90)

        // Custom periods testing bounds and sorting
        #expect(snapshot.comparisonSummaries(periods: [30, 7, 90, 7], calendar: Self.utcCalendar).map(\.days) == [
            7,
            30,
        ])
    }

    @Test
    func `comparison periods include 365 and all-time marker depending on history days`() {
        // 1. History is 30 days
        let snapshot30 = Self.snapshot(historyDays: 30)
        let summaries30 = snapshot30.comparisonSummaries(calendar: Self.utcCalendar)
        #expect(summaries30.map(\.days) == [7, CostUsageTokenSnapshot.allTimeDaysMarker])

        let allTimeSummary30 = summaries30.first(where: { $0.days == CostUsageTokenSnapshot.allTimeDaysMarker })!
        #expect(allTimeSummary30.entryCount == 3) // all entries in daily
        #expect(allTimeSummary30.totalCostUSD == 10) // 1 + 4 + 5
        #expect(allTimeSummary30.totalTokens == 1000) // 100 + 400 + 500

        // 2. History is 365 days
        let snapshot365 = Self.snapshot(historyDays: 365)
        let summaries365 = snapshot365.comparisonSummaries(calendar: Self.utcCalendar)
        #expect(summaries365.map(\.days) == [7, 30, 90, CostUsageTokenSnapshot.allTimeDaysMarker])

        // 3. History is 10 days (less than 30 days, all-time marker should be excluded to avoid noise)
        let snapshot10 = Self.snapshot(historyDays: 10)
        let summaries10 = snapshot10.comparisonSummaries(calendar: Self.utcCalendar)
        #expect(summaries10.map(\.days) == [7])
    }

    @Test
    func `summary preserves unavailable totals as nil`() {
        let snapshot = CostUsageTokenSnapshot(
            sessionTokens: nil,
            sessionCostUSD: nil,
            last30DaysTokens: nil,
            last30DaysCostUSD: nil,
            historyDays: 30,
            daily: [Self.entry(day: "2026-07-01", cost: nil, tokens: nil, requests: nil)],
            updatedAt: Self.now)

        let summary = snapshot.summary(forLastDays: 7, calendar: Self.utcCalendar)
        #expect(summary.totalCostUSD == nil)
        #expect(summary.totalTokens == nil)
        #expect(summary.totalRequests == nil)
    }

    private static func snapshot(historyDays: Int) -> CostUsageTokenSnapshot {
        CostUsageTokenSnapshot(
            sessionTokens: 500,
            sessionCostUSD: 5,
            last30DaysTokens: 1000,
            last30DaysCostUSD: 10,
            historyDays: historyDays,
            daily: [
                self.entry(day: "2026-06-01", cost: 1, tokens: 100, requests: 1),
                self.entry(day: "2026-06-25", cost: 4, tokens: 400, requests: 4),
                self.entry(day: "2026-07-01", cost: 5, tokens: 500, requests: 5),
            ],
            updatedAt: self.now)
    }

    private static func entry(day: String, cost: Double?, tokens: Int?, requests: Int?)
        -> CostUsageDailyReport.Entry
    {
        CostUsageDailyReport.Entry(
            date: day,
            inputTokens: nil,
            outputTokens: nil,
            totalTokens: tokens,
            requestCount: requests,
            costUSD: cost,
            modelsUsed: nil,
            modelBreakdowns: nil)
    }

    private static let now = Date(timeIntervalSince1970: 1_782_864_000) // 2026-07-01 00:00:00 UTC
    private static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
