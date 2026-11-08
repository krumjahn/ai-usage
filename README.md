# AI Usage

A local macOS menu-bar app for foreground attention spent in AI tools. Adapted from Brainrot's Swift collection pipeline; it runs independently with its own activity history.

- Menu-bar time (for example, **42m**) and dashboard share today's recorded AI total, refreshed every 10 seconds.
- Web and desktop attention combines into one total per AI product, and one overall daily/menu-bar total. A compact source split appears under the selected-period total and beneath every tool. Overlapping observations count once.
- One compact 320pt monochrome dashboard with a Today / 7 days selector, attention totals, share of active time, all used tools, and a seven-day activity strip. Lists longer than five tools scroll in place.
- Time-only menu bar with a pause indicator when collection is paused; native light and dark appearance. Dashboard status appears only when paused, idle, or the session is inactive.
- Original open-dial app icon. Regenerate its native sizes with `swift Design/GenerateIcon.swift`.
- Optional browser identification for recognized AI domains. Chrome time alone does not count as AI.
- Pause/resume, local JSON export, and explicit history deletion in Settings.
- No allowance or token tracking, account connections, provider API requests, or cloud uploads.

## Build and test

Requires macOS 13+, Xcode with command-line tools selected, and XcodeGen. The internal scheme and executable retain the AttentionLedger name; the user-facing app is AI Usage.

```sh
xcodegen generate
xcodebuild -scheme AttentionLedger -destination 'platform=macOS' -derivedDataPath build -parallel-testing-enabled NO test
xcodebuild -scheme AttentionLedger -configuration Release -destination 'platform=macOS' -derivedDataPath build build
open build/Build/Products/Release/AttentionLedger.app --args --dashboard
```

Local builds use ad-hoc signing (`CODE_SIGN_IDENTITY=-`). Production distribution would require Developer ID signing and notarization. Browser identification asks for macOS Automation permission per supported browser; foreground application tracking does not require an account login.

## Privacy and time semantics

SQLite history remains at `~/Library/Application Support/com.rumjahn.attentionledger/activity.sqlite`. Keep this bundle ID and support directory to preserve upgrades. Do not commit databases or exports.

Only app names, bundle IDs, recognized normalized AI domains, time intervals, and classification provenance are stored. No prompts, source code, window titles, full URLs, or page contents are recorded. Terminal foreground time does not identify an AI agent.

The existing collector confirms intervals using input activity and excludes idle and sleep gaps. The menu-bar total is not an independent stopwatch: it advances after confirmed observations are saved and analytics refresh. It may remain unchanged while no new input confirms an interval. At midnight it shows the new local day's total. It does not measure background agent execution or concurrent work across devices.

Retired allowance connections are no longer accessed. Existing credentials belonging to other apps, and any previously saved AI Usage Keychain entry, are left untouched.

## Source layout

- `Core/`: activity sampling, browser adapters, domain classification, SQLite storage, and analytics.
- `App/`: status item, dashboard, tool list, and local settings.
- `Tests/`: pipeline, privacy, storage, layout, navigation, and menu-bar time tests using temporary databases.
