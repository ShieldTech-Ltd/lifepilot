# Accessibility and Notifications

**Issue:** [#33](https://github.com/TFT444/LifePilot/issues/33)  
**Related:** [TOKENS_AND_LAYOUT.md](TOKENS_AND_LAYOUT.md), [ENGINEERING_GUIDE.md](../ENGINEERING_GUIDE.md#accessibility), [USER_JOURNEYS.md](USER_JOURNEYS.md)

Product-wide rules for inclusive interaction and privacy-safe interruptions. Applies to SwiftUI features, DesignSystem components, and notification copy.

---

## VoiceOver

| Requirement | Detail |
|---|---|
| Labels | Every interactive control has an accessibility label that names the **action or object**, not the glyph (“Approve calendar change”, not “checkmark”). |
| Values / hints | Use values for state (Selected, Pending, Offline). Hints only when behavior is non-obvious. |
| Traits | Buttons are `.isButton`; headers use header traits; decorative images are hidden. |
| Focus order | Matches visual reading order: title → status chips → primary content → primary actions. Sheets: title, why, evidence, Approve, Reject. |
| Grouping | Combine date + greeting on Home; don’t force swipe through purely decorative dividers. |
| Live regions | After Approve/Reject, announce result once (“Approved. Waiting to sync.” / “Rejected.”). |

### Pass / fail examples

| | Example |
|---|---|
| Pass | Conflict card: label “Conflict: Design review overlaps school pickup. Double tap to review proposal.” |
| Fail | Card exposes only “sparkle” image name; Approve button labeled “Button”. |
| Pass | Timeline row includes time, title, context (Work/Personal), and “Conflict” text. |
| Fail | Red dot alone conveys conflict; VO hears “image”. |

---

## Dynamic Type

- All user-facing text uses `Font.LifePilot` / text styles — see TOKENS_AND_LAYOUT.md.
- Support through at least **accessibility3** without clipping primary actions.
- Prefer vertical stack reflow; avoid fixed-height text boxes for briefing body.
- Icon+text rows: text wraps; icons stay at `IconSize` and vertically align to first line.

| | Example |
|---|---|
| Pass | Approve / Reject remain fully visible and tappable at accessibility3 (may stack). |
| Fail | Truncated “Appro…” with no access to Reject at large sizes. |

---

## Touch targets (44pt)

- Minimum hit target **44×44 pt** for all interactive controls (Apple HIG).
- Spacing between adjacent targets ≥ 8pt (`Spacing.sm`) when possible.
- List rows: entire row tappable where the row is the action; trailing icon buttons still ≥ 44pt.

| | Example |
|---|---|
| Pass | Secondary Reject control expands tap area with padding even if visual glyph is 22pt. |
| Fail | 22×22 glyph-only hit slop with no padding next to Approve. |

---

## Color-independent status

Status must never rely on color alone. Pair **color + icon + text** (or shape).

| Status | Token | Non-color cues |
|---|---|---|
| Risk / conflict | `signal.risk` | `exclamationmark.triangle` + “Conflict” / “Overdue” |
| Success / approved | `signal.success` | `checkmark.circle` + “Approved” / “Done” |
| Info / pending | secondary text | `clock` / `arrow.triangle.2.circlepath` + “Pending sync” |
| Offline | secondary / risk as needed | `wifi.slash` + “Offline” |

| | Example |
|---|---|
| Pass | Overdue task shows circle icon + “Overdue” caption + risk color. |
| Fail | Calendar block tinted red with no label or icon. |

---

## Notifications

### Privacy defaults

| Setting | Default | Behavior |
|---|---|---|
| **Sensitive notification previews** | **Off** | Lock screen / banner use generic copy only |
| Quiet hours | On template 22:00–07:00 (user-editable) | Suppress non-critical pushes; critical/time-sensitive follow OS entitlements carefully — MVP prefers quiet over interrupt |

`UserPreferences.sensitiveNotificationPreviews` defaults to `false` in code — keep it that way.

### Generic vs sensitive copy

| | Preview off (default) | Preview on (opt-in) |
|---|---|---|
| Reminder due | “LifePilot · Reminder” | “LifePilot · Pack school bag” |
| Briefing ready | “Your briefing is ready” | May include “1 schedule conflict” — still avoid child/location specifics unless user opted in |
| Approval needed | “Action waiting for your approval” | “Approve: move Design review?” |

**Never** in any preview by default: medical/health detail (Health not MVP), financial data (out of scope), full addresses, message bodies (no Mail).

### Frequency, grouping, actions

| Rule | Detail |
|---|---|
| Frequency | Prefer digest (“Briefing ready”) over per-signal spam; batch leave-by closely spaced items |
| Grouping | Thread by day / category (`briefing`, `reminder`, `approval`) |
| Actions | Open app; optional complete / snooze when not requiring external write; external writes still need in-app Approve |
| Quiet hours | No marketing-style prompts; only user-configured briefing time may wake inside quiet hours if user set briefing inside that window — document in Settings |

| | Example |
|---|---|
| Pass | Default banner: “LifePilot · Reminder” with Open. |
| Fail | Default banner: “Pick up Maya at Lincoln Elementary 2:15 — running late”. |

---

## Cognitive load and plain language

| Rule | Detail |
|---|---|
| One job per section | Matches product design rules: one headline, one short support line |
| Reading level | Short sentences; prefer “Move this meeting?” over “Initiate temporal rescheduling heuristic” |
| Explain why | Every recommendation includes a plain-language reason |
| No fake certainty | “Might overlap” / “Buffer may be tight” when probabilistic; deterministic rules say “Overlaps” |
| Errors | Say what happened and what to do next (“Calendar unreachable. Showing last update. Retry.”) |
| Scope honesty | Never imply Mail send, Health, or banking features |

| | Example |
|---|---|
| Pass | “These two events overlap by 15 minutes. Approve moving Design review to 3:30?” |
| Fail | “Ghost Brain entropy flagged multi-agent collision vector #4”. |

---

## Component accessibility contract

Every interactive DesignSystem / feature control should document:

1. **Role** (button, toggle, link, heading).
2. **Name** (label source).
3. **State** (selected, disabled, error, pending sync).
4. **Keyboard / VO** action (activate, dismiss).
5. **Motion** (respects Reduce Motion: yes/no decorative).

Minimum for MVP components: `BriefingCard`, `TimelineRow`, `ApprovalSheet`, `SignalBadge`, `EmptyStateView`, primary/secondary buttons, Settings toggles.

---

## Pass / fail gallery (summary)

| Area | Pass | Fail |
|---|---|---|
| VO | Conflict announced with title + action | Unlabeled sparkle |
| Type | Actions reflow at accessibility3 | Clipped Approve |
| Target | 44pt Approve/Reject | 22pt hit boxes |
| Color | Icon + “Overdue” | Red-only bar |
| Notification | Generic preview default | Sensitive default on |
| Language | Plain why + next step | Jargon / fake features |

---

## Design review checklist

Use before merging UI or notification copy:

### Interaction and a11y

- [ ] Interactive elements have VO labels and correct traits
- [ ] Focus order verified for new screen / sheet
- [ ] Dynamic Type reflow checked (default + accessibility3)
- [ ] Hit targets ≥ 44×44 pt
- [ ] Status encodes icon + text, not color alone
- [ ] Reduce Motion: no required infinite animation
- [ ] Reduce Transparency: glass falls back to opaque elevated fill

### Notifications and privacy

- [ ] Sensitive previews remain **off** by default
- [ ] Default copy has no private titles/places/names
- [ ] Quiet hours behavior considered
- [ ] Notification actions do not bypass approval for external writes

### Cognitive / scope

- [ ] Plain-language why on recommendations
- [ ] Empty/error/offline states honest
- [ ] No finance, shopping, HealthKit, or Mail auto-send implications

### Tokens

- [ ] Uses DesignSystem tokens only (see TOKENS_AND_LAYOUT.md)
- [ ] Light and dark contrast acceptable (AA)

---

## Acceptance criteria checklist (#33)

- [x] Standards are documented with pass/fail examples
- [x] Notification content never exposes sensitive details by default
- [x] Every interactive component has an accessibility contract (contract defined; components must comply in implementation)
- [x] Design review checklist incorporates these standards
