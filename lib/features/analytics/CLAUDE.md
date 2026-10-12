# CLAUDE.md — Analytics

Read this before changing what the Analytics tab reports or over which dates.
Every figure is derived on read (hard rule 3) and a missing one is `—`
(hard rule 5); what follows is only what is true of this tab.

## A period strip windows the headline, the trend and the statement

Owner's rule. All · 7D · 30D · 90D · YTD · Custom, on the shared `AppFilterStrip`,
pinned above the scroll the way Orders' strip is.

- **All time is the default**, because it is the figure Home's hero shows.
  Opening Analytics on a different number than the one that brought the
  seller there reads as a contradiction.
- **Calendar days, today included.** `AnalyticsPeriodWindow` counts midnights,
  never a `Duration`, so a sale is never in or out depending on the hour.
- **Orders by when they were placed, expenses by their own date.** Stock on
  the shelf is a snapshot and is not windowed.
- **The marketplace ranking and the drill-downs stay all-time**, as their own
  screens are. Windowing them is a separate decision.
- **Custom is a range of whole days the seller picks** — owner's rule, added
  for filtering by specific dates. Both ends are included (1–9 October
  covers all of the 9th), the chip reads back the range once picked, and a
  Custom with nothing picked reads as all time. The range lives in
  `analyticsCustomRangeProvider`; `AnalyticsPeriodWindow.endOf` is the only
  period with an end before today.

## The trend is revenue and the sales' own profit, bucketed

- **Days for 7D, weeks for 30D and 90D, months for YTD and All**, at most
  `ProfitTrend.maxBuckets` bars. Weeks start on Monday. **A Custom range
  takes its bar width from its span** (`AnalyticsPeriodConstant`) and its
  last bar is its last day, not today.
- **Empty buckets are drawn**: a week with no sale is part of the story, and
  its revenue is a real zero.
- **A bucket with any sale of unknown profit draws revenue alone.** A profit
  bar summed over the known half would pass for the whole (hard rule 5).
- **The bars are before overhead expenses**, and the caption says so, so
  they are never read as pieces of the net profit above them.
- `test/features/analytics/profit_trend_test.dart` and
  `analytics_period_test.dart` pin all of it.
