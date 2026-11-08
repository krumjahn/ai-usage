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
