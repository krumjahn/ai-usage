# Compact monochrome redesign — 8 November 2026

- `App/MenuBarUI.swift`: 320pt panel, smaller typography and spacing, plain time metric, compact icon-and-duration rows, shallow weekly chart, and contextual browser setup. Removed teal cards, gradients, decorative logo, badges, and ranking bars. All tools remains accessible even when today has no data. Settings stays behind the gear; enabled browser identification no longer initially reads “Off”.
- `App/AttentionMenuBarPresentation.swift` and `App/Entry.swift`: menu bar displays only time, with a small pause symbol when paused. Accessibility labels and the explanatory tooltip remain.
- `App/Assets.xcassets` and `Design/GenerateIcon.swift`: original monochrome open-dial icon, with a reproducible vector generator for all macOS icon sizes. `project.yml` selects the icon asset.
- Core collection, classification, database, and analytics files are byte-for-byte unchanged.

Verification used the same scheme, destination, signing, and commands recorded below. All **15 tests passed** after the final change. Layout checks cover empty, one-day and multiweek fixtures in light/dark mode at 320pt; dashboard height stays below 410pt. Menu-bar tests cover time-only labels, pause-only icon, saved-data updates, idle exclusion, and midnight reset. Release build and signature verification passed.

Native illustrative prototypes measured 320 × 370pt with three tools and the browser setup link. The real-data dashboard is shorter when browser tracking is already enabled. Inspected the actual popover, Today/Last 7 days navigation, Settings and pause/resume. Confirmed the live menu bar showed `32m`, matching the dashboard; collection was resumed after the test.

Read-only history check preserved all 647 completed baseline rows exactly; SQLite `quick_check` returned `ok`. The currently coalescing last row was excluded from the baseline. No history, browser opt-in preference, or credentials were deleted. No provider integration was reintroduced.

Limitations: runtime testing was on the current Mac, not macOS 13 hardware. Dark mode and empty/multiweek data were rendered/tested using isolated fixtures; the live smoke test used the user's current appearance and real data. Live sleep/wake was not retested. macOS can cache an older app icon until Finder refreshes it.

---

# Time-only release — 8 November 2026

## Changes

- `App/Entry.swift`: variable-width menu-bar item subscribes to the same published daily analytics as the dashboard. Uses monospaced digits, an accessible description, pause icon, and a reporting-error state.
- `App/AttentionMenuBarPresentation.swift`: shared duration formatting and menu-bar presentation.
- `App/MenuBarUI.swift`: removed Plan Limits navigation and dashboard summary.
- `App/LedgerModel.swift`: removed quota model and polling startup. Existing ten-second analytics refresh remains.
- Removed quota clients, OAuth/Keychain integration, quota UI, and their obsolete tests from the app target. No credential deletion performed.
- Collector, domain classification, SQLite schema, support directory, and history are unchanged.

## Automated verification

Scheme: `AttentionLedger`; destination: `platform=macOS`; signing: ad-hoc (`-`). Xcode and XcodeGen are required.

Commands run from the source directory:

```sh
xcodegen generate
xcodebuild -scheme AttentionLedger -destination 'platform=macOS' -derivedDataPath ../../work/ai-ui-build -parallel-testing-enabled NO test
xcodebuild -scheme AttentionLedger -configuration Release -destination 'platform=macOS' -derivedDataPath ../../work/ai-ui-build build
codesign --verify --strict '../AI Usage.app'
```

All **15 tests passed**: 12 existing pipeline/classification/storage/navigation/layout tests and 3 menu-bar time tests. Release build and code-signature verification passed. New coverage includes duration boundaries, pause/idle/error display, published updates after saved AI activity, exclusion of ordinary browser and idle time, midnight reset, and preservation of stored rows.

Xcode emitted test-framework deployment warnings because the installed XCTest libraries target macOS 14 while the app targets macOS 13. Tests ran on the current Mac; runtime on macOS 13 was not tested.

## Manual and data checks

- Replaced and launched the delivered AI Usage app; menu bar showed `AI 21m`, matching the real dashboard.
- Dashboard has no allowance section. All AI Tools switched between Today and Last 7 days successfully.
- Settings Pause changed to Resume, then collection was resumed.
- Read-only verification: all 569 baseline completed history rows retained their exact contents after the update; SQLite `quick_check` returned `ok`. The last actively coalescing row was excluded from the baseline because normal collection can extend it.
- Browser permissions were left unchanged. Browser identification was off during this smoke test; no new permission prompts were exercised.

The menu bar refreshes confirmed database totals every ten seconds. It does not extrapolate a running timer through idle time. Minute rounding can keep the displayed text unchanged between refreshes. Midnight behavior is covered by tests, not an overnight manual run. Live sleep/wake was not retested in this UI-focused change.
