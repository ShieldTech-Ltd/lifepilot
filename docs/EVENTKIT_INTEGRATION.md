# EventKit Integration — Handoff Notes

This branch (`feature/eventkit-integration`) adds the first real, non-mock
data source to LifePilot: a live Calendar integration via EventKit, feeding
a rule-based Ghost Brain reasoning engine. It was written without access to
Xcode/a Mac/a simulator, so **it has never been compiled or run**. This
document is the manual verification checklist for whoever builds it first.

## What changed, by layer

- **`Core/Protocols/CalendarReading.swift`** — new protocol: `func events(on date: Date) async throws -> [CalendarEvent]`. Framework-agnostic, lives in `LifePilotCore`.
- **`Services/EventKitCalendarReader.swift`** — new `CalendarReading` implementation backed by `EKEventStore`. Handles authorization (`requestFullAccessToEvents()`, the iOS 17+ API), maps `EKEvent` → `CalendarEvent`.
- **`GhostBrain/CalendarRecommendationEngine.swift`** — new pure rule-based reasoning: detects overlapping events (conflict), tight back-to-back gaps (<10 min), and imminent upcoming events (<2h), each with an explained `reasoning` string.
- **`GhostBrain/GhostBrainService.swift`** — rewritten. No longer throws `DomainError.unavailable`; now takes an injected `CalendarReading` and orchestrates it through `CalendarRecommendationEngine`.
- **`AppShell/Composition/AppDependencies.swift`** — `.live` now wires the real `GhostBrainService(calendarReader: EventKitCalendarReader())`. Added `.preview`, which keeps the old `MockRecommendationProvider` behavior for SwiftUI Previews / anywhere you don't want a Calendar permission prompt.
- **`App/LifePilot.xcodeproj/project.pbxproj`** — added `INFOPLIST_KEY_NSCalendarsUsageDescription` to both Debug and Release build configs. **Without this, the app will crash immediately on first calendar access** (missing usage description is a hard crash on iOS, not a soft failure).
- **`Package.swift`** — added `LifePilotServicesTests` test target (didn't exist before); added `LifePilotServices` to `LifePilotAppShell`'s dependencies (needed since `AppDependencies` now constructs `EventKitCalendarReader` directly).
- Tests: new `CalendarRecommendationEngineTests`, `GhostBrainServiceTests` (both pure-logic, use a `FakeCalendarReader`, no EventKit), `EventKitCalendarReaderTests` (minimal — see below). Fixed `AppDependenciesTests` and `MockRecommendationProviderTests`, which asserted the *old* throwing behavior.

## Step 1 — First build

```
cd LifePilot
open App/LifePilot.xcodeproj
```

Expect possible first-build friction:
- If Xcode complains about the `LifePilotServices` module not being found in `AppShell`, double check `Package.swift`'s `LifePilotAppShell` target dependency array includes `"LifePilotServices"` (it should, but Xcode's SPM cache can be stale — try Product → Clean Build Folder).
- `EventKit` is a system framework, no SPM dependency needed, just `import EventKit` — if that import fails to resolve, the target's platform minimum might be wrong (`Package.swift` targets `.iOS(.v17)`, `EKEventStore.requestFullAccessToEvents()` requires iOS 17+, this should be consistent but worth a first check).

## Step 2 — Run the automated test suite

```
swift test
```
or Xcode's Test navigator (⌘U). Everything added on this branch is designed to run **without needing calendar permission** — `CalendarRecommendationEngineTests` and `GhostBrainServiceTests` use `FakeCalendarReader`, a hardcoded fake, not the real thing. If any of those fail, that's a real bug in the reasoning logic — the fakes are deterministic.

`EventKitCalendarReaderTests` is intentionally thin (one test, checks the protocol conformance) — see Step 3 for the part that needs a human.

## Step 3 — Manual, on-device verification (the part I can't do)

Run on a simulator or device and walk through:

1. **First launch, permission prompt**: Home screen should trigger a Calendar permission dialog. Confirm the prompt text matches what's in `NSCalendarsUsageDescription` and reads naturally.
2. **Deny access**: deny the prompt, confirm the app doesn't crash — `HomeViewModel.load()` currently does `try? await ghostBrain.currentModel()` and silently swallows the error (pre-existing pattern, not new), so on denial you should just see an empty/loading Home screen, not a crash. Worth deciding if that's the UX you want, or if it should show an explicit "Calendar access needed" state instead.
3. **Grant access, empty calendar**: confirm zero recommendations, zero events, no crash — `GhostBrainServiceTests.testEmptyCalendarProducesNoRecommendationsButStillSucceeds` covers the logic, but the real EventKit path (empty predicate results) hasn't been exercised.
4. **Grant access, real events**: add 2-3 events to the Simulator's Calendar app (or a real device's calendar) — including at least one pair that overlaps, and one starting within the next 2 hours — and confirm the Home screen shows real recommendations with real reasoning text, not the old hardcoded "Alex" sample data.
5. **Settings → revoke access after granting**: confirm the app handles `authorizationStatus` flipping to `.denied` gracefully on a subsequent load, not just on first launch.

## Known gaps / things I did not attempt

- **No caching/offline handling** — every `currentModel()` call re-queries EventKit live. Fine for a demo, worth revisiting for real use (EventKit access itself is fast/local, so this is likely a non-issue, but not verified on-device).
- **`HomeViewModel.load()`'s silent `try?`** — pre-existing before this branch, but now more consequential since real errors (permission denied, EventKit failure) are more likely than the old mock ever throwing. Consider surfacing this to the UI rather than silently showing nothing.
- **Only today's events are read** (`calendarReader.events(on: now)` — see `GhostBrainService.currentModel()`). No multi-day lookahead. That's a deliberate scope cut for the 2-day window, not an oversight — Phase 7/8 would presumably want more.
- **`CalendarRecommendationEngine`'s rules are intentionally simple** (3 rules: conflict, tight gap, imminent event) — a real "AI" pass (LLM-backed reasoning per the original Phase 5 vision) would replace or augment this, but this establishes the seam (`GhostBrainService` takes any `CalendarReading`; swapping the reasoning engine inside it is a contained change).
- I did not update `MASTER_ROADMAP.md`'s phase-completion tracking or `CHANGELOG.md` — the existing changelog doesn't appear to track Phase 3/4 work either, so I matched that pattern rather than being the first to diverge from it on a rushed branch. Worth a deliberate decision on whether to start logging entries going forward.
