# One dashboard, all tools — 8 November 2026

- `App/MenuBarUI.swift`: removed the separate All tools route and top-three limit. One Today / 7 days selector now controls the hero, share of active time, total source split, and all tool rows. Every row shows its web/desktop split beneath the tool name; lists over five tools scroll within 190pt. Settings stays behind the gear and preserves the selected period on return. A fresh presentation still defaults to Today; the menu bar continues to show today's total.
- `App/CollectionNotice.swift`: hides routine collection status, retaining Paused, Idle and Session inactive. Error messages remain visible separately.
- Tests updated for the simplified navigation, both periods, and compact bounded layout with empty/sparse/multiweek histories in light and dark mode. Added exceptional-status coverage. Core analytics, classifier, collector and storage code are unchanged.

All **21 tests passed**, Release build succeeded, and strict signature verification passed. Used the same Xcode test/build commands below, with logs in `work/unified-tests.log` and `work/unified-build.log`. Live checks confirmed Gemini visible directly on Today, per-tool source subtitles, correct seven-day totals, Settings back-navigation preserving the period, and Paused appearing only while paused. Collection was resumed and the dashboard returned to Today.

All 713 baseline completed history rows are unchanged; SQLite integrity passed. The scrolling layout was covered by isolated multi-tool fixtures; current live data has four tools today and five over seven days. No sleep/wake or permission changes were exercised in this UI-only update.

---

# Minimal web / desktop split — 8 November 2026

- `Core/AttentionSplit.swift` and `Core/UsageAnalytics.swift`: derive per-tool web/desktop seconds from the existing deduplicated foreground intervals. Combined totals now derive from the two sources, so the split and total cannot drift. Browser classification and stored observations are unchanged.
- `App/AttentionSplitSummary.swift` and `App/MenuBarUI.swift`: one compact line under the total (for example, “Web 15s · Desktop 47m”), preserving the 320pt panel and time-only menu bar. The active-time percentage remains beside the hero metric. All tools shows the selected day's or week's split; per-tool splits are available through native hover help and accessibility labels.
- `Tests/AttentionSplitTests.swift` and the existing combined-source regression test: cover empty/web-only/desktop-only activity, mixed-source products, overlap exclusion, midnight boundaries, weekly aggregation, and preserved stored rows.

Uses the same Xcode test/build commands below, with logs in `work/split-tests.log` and `work/split-build.log`. All 20 tests, release build and signature verification passed. Live dashboard, daily/weekly navigation, per-tool accessibility names and native help values verified. All 704 baseline completed history rows unchanged; SQLite integrity passed. Source durations use the same compact rounding as other metrics; rounded labels can differ slightly from the displayed combined total. Only recorded recognized AI website time is included; unsupported or previously discarded browser domains cannot be reconstructed.

---

# Combined web and desktop presentation — 8 November 2026

The analytics already group observations by canonical tool identity. Updated `App/MenuBarUI.swift` to explicitly label the daily metric “Web + desktop” and explain per-tool grouping in All tools. `App/AttentionMenuBarPresentation.swift` includes the same scope in the menu-bar tooltip. Kept the time-only menu-bar label and compact 320pt layout.

Added `testWebAndDesktopCombineByToolWithoutDoubleCounting` in `Tests/PipelineTests.swift`: ChatGPT (both desktop identifiers), Claude and MiniMax each combine desktop/browser observations; overlapping intervals count once; ordinary browsing and idle periods do not count as AI; Codex remains a separate product. No collector, classifier, analytics or database changes.

Verification: same Xcode test/build commands below, with logs in `work/combined-tests.log` and `work/combined-build.log`. All 18 tests, release build and signature verification passed. Verified live dashboard (45m, Web + desktop) and tool-list explanation. All 692 baseline completed history rows were unchanged; SQLite integrity passed.

---

# MiniMax classification fix — 8 November 2026

Added `com.minimax.agent` (verified from the installed MiniMax Code app) and `agent.minimax.io` to classifier version 6, both as **MiniMax Code**. Existing raw desktop observations now contribute to AI analytics without rewriting historical classification evidence. Domains for the company website, developer platform, generated websites, and lookalikes remain unrecognized; terminal foreground time is not inferred to be MiniMax.

Verification uses the same Xcode commands below, with logs in `work/minimax-tests.log` and `work/minimax-build.log`. Added tests for desktop/browser recognition, privacy-safe domain normalization, false positives, and retrospective classification with original evidence preserved. No collector or database-schema changes. All 17 tests, release build and signature verification passed. The restarted live dashboard shows MiniMax Code (5m rounded down from about 5m 40s). A read-only hash check confirms all 670 completed baseline history rows are unchanged; SQLite integrity check passed.

---

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
