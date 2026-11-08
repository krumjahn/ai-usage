# DMG packaging validation — 8 November 2026

Added `scripts/package-dmg.sh`, `scripts/dmg-settings.py` and `docs/RELEASING.md`. Updated README and installation instructions to make the DMG the primary download. Existing app sources, installed binary and activity history are untouched. The release tag stays fixed; the DMG packages the original ZIP's identical app.

Input ZIP SHA-256: `7244c5e7c0e20f5ce3aff7b8ab5c602e6bf25742567579f245a706c1f2377c16`, matching the published release asset. Extracted only to a task-specific temporary directory. All six regular app files match after packaging and after copying out to a temporary installation directory. Bundle ID `com.rumjahn.attentionledger`, version `0.1.0` (build 1), minimum macOS `13.0`, architectures `x86_64 arm64`, feedback endpoint empty.

Verification commands:

```sh
bash -n scripts/package-dmg.sh
DMGBUILD_BIN=/path/to/venv/bin/dmgbuild scripts/package-dmg.sh "/temporary/AI Usage.app" release/AI-Usage-0.1.0-preview.dmg
hdiutil verify release/AI-Usage-0.1.0-preview.dmg
hdiutil attach -readonly -nobrowse -plist release/AI-Usage-0.1.0-preview.dmg
codesign --verify --deep --strict "/Volumes/AI Usage 0.1.0/AI Usage.app"
lipo -archs "/Volumes/AI Usage 0.1.0/AI Usage.app/Contents/MacOS/AttentionLedger"
git diff --check
```

Disk-image checksums and app signatures passed. Compared SHA-256 manifests of every regular app file against the extracted ZIP and temporary installation copy. Confirmed `Applications` links to `/Applications`, installation/license text is included, and no activity database is packaged. Opened the DMG through Finder and checked the compact layout; corrected the Read Me label spacing. No second collector was launched. Existing app tests were not rerun for this packaging-only change; prior 24 macOS and six API tests passed.

Packaging uses dmgbuild 1.6.7, ds_store 1.3.3 and mac_alias 2.2.3 in a separate virtual environment, with no new app dependencies. Xcode 27.1's hdiutil emits deprecation notices but creates and validates the HFS+/UDZO image successfully. No Developer ID Application certificate is available; the binary remains ad-hoc signed and unnotarized. Clean-machine Gatekeeper behavior, macOS 13 and Intel runtime were not tested. Published release checksums are the authoritative digest for the final DMG.

---

# Menu-bar demo revision — 8 November 2026

Changed `promo/compositions/overview.html` and its opening headline to demonstrate macOS desktop → menu-bar click → native dashboard → click away. Added `Design/GenerateDemoAssets.swift` and `promo/assets/mac/` for reproducible offscreen native desktop assets. Updated the standalone MP4, poster and media documentation. The desktop is staged and the actual dashboard screenshot uses synthetic data.

```sh
swift Design/GenerateDemoAssets.swift
npx --yes hyperframes@0.8.223 check promo --json
npx --yes hyperframes@0.8.223 snapshot promo --review --composition overview
cd promo
npx --yes hyperframes@0.8.223 render --output ../docs/media/ai-usage-demo.mp4 --fps 30 --quality looks
cd ..
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate -show_entries format=duration,size -of json docs/media/ai-usage-demo.mp4
```

Check passed with zero errors/warnings; intentional silence is informational. Visually reviewed opening-click frames, settled beats, transition seams and phone-size sheets; preview opened in Chrome. Final encoding and a representative encoded frame checked. Native application tests were not rerun because application source is unchanged. Installed binary, collector, preferences and production activity history are untouched. This is a staged demonstration, not a fresh runtime test of the menu-bar application. Website deployment remains disabled.

---

# GitHub-first launch update — 8 November 2026

Website publication is deferred at the maintainer's request. GitHub Pages is unpublished, its workflow disabled and its automatic push trigger removed, and the repository homepage cleared. Website source remains available for later work. The README now presents screenshots and a standalone demo directly on GitHub; the same MP4 remains attached to the preview release.

This update changes documentation, media copies and deployment configuration only. App code, collector, settings and activity history are untouched. Verified the copied demo matches the existing rendered video byte-for-byte and checked its format with ffprobe. Application tests were not rerun for this documentation/deployment-only update; the prior 24 macOS and six API tests passed in CI.

---

# v0.1.0-preview validation — 8 November 2026

## Changes

- `App/FeedbackSubmission.swift`, `FeedbackClient.swift`, `FeedbackModel.swift`, `FeedbackView.swift`: optional three-question sheet, explicit submission, disabled automatic onboarding until an HTTPS service endpoint exists, one-time offer, cancellation, retry IDs, no cookies, no redirects and matching receipt validation.
- `LedgerModel.start()` activates eligibility for onboarding; `MenuBarUI` presents the sheet and adds a Settings entry. Dashboard navigation and analytics are retained.
- `website/`: static landing page, privacy notes, Cloudflare Worker with strict payload validation, 4 KiB streaming cap, parameter-bound D1 writes, idempotency, rate limiting and 90-day retention. No public response read API.
- Native sample screenshots, editable HyperFrames demo, MIT/open-source documentation, contribution and issue templates, CI and Pages workflow.
- Collector, classifier, browser adapters, SQLite schema and analytics are unchanged. Existing completed history passed a read-only hash comparison and SQLite integrity check after the installed build was updated. The actively coalescing last row was excluded from the baseline.

## Commands and results

Scheme: `AttentionLedger`; destination: `platform=macOS`; target: macOS 13; signing: ad-hoc. Xcode and XcodeGen required. The app is built universally for arm64 and x86_64; runtime testing used this Apple Silicon Mac, not Intel or macOS 13 hardware.

```sh
xcodegen generate
xcodebuild -scheme AttentionLedger -destination 'platform=macOS' -derivedDataPath build -parallel-testing-enabled NO test
xcodebuild -scheme AttentionLedger -configuration Release -destination 'platform=macOS' -derivedDataPath build ONLY_ACTIVE_ARCH=NO build
codesign --verify --strict 'AI Usage.app'
lipo -info 'AI Usage.app/Contents/MacOS/AttentionLedger'
```

24 XCTest cases passed locally, zero failures. The first macOS 15 CI run exposed a preference-dependent layout assertion: a new installation adds the website opt-in row. The fixture now explicitly covers both browser settings using process-only volatile defaults, with separate compact height bounds; production code and preferences are unchanged. All 24 cases also passed on the macOS 15 GitHub runner after this correction; the Linux feedback job passed all six tests and deployment checks. This includes existing collection/storage/analytics/privacy/layout/navigation tests and three new feedback tests covering one-time configured onboarding, skip/no send, payload minimization, Unicode length limit, retry IDs, changed answers, error/success state and endpoint restrictions. Release build and signature verification passed. Xcode emitted test framework warnings for its newer XCTest deployment target and benign local Intents service diagnostics.

```sh
cd website
npm ci
npm test
npm run types
npm run check
npx wrangler d1 migrations apply FEEDBACK_DB --local
npx wrangler deploy --dry-run
```

Six API tests passed. Generated-type strict JavaScript checking and Worker dry-run bundling passed. Real local Wrangler/D1 integration: two identical submissions returned matching 201 receipts and produced one stored row; public GET returned 405. Local test data was never sent to Cloudflare production. Retention SQL is exercised with a mocked scheduled invocation, not an elapsed 90-day production run.

```sh
scripts/screenshots.sh
cd promo
npx hyperframes check --json
npx hyperframes snapshot --review --composition overview
npx hyperframes render --output ../website/public/assets/demo.mp4 --fps 30 --quality looks
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate -show_entries format=duration,size -of json ../website/public/assets/demo.mp4
```

Actual native views rendered with synthetic records in a temporary database. HyperFrames checks passed without warnings; silence is intentional. Inspected beat, phone and transition sheets and a frame from the encoded file. H.264, 1920×1080, 30fps, 14 seconds; under 1 MB. See `promo/REVIEW.md` for small-screen limitations.

## Manual checks and publication boundaries

- Launched installed updated build; current data displayed. Settings → Help shape AI Usage shows the no-endpoint explanation and GitHub link. Done closes it without submission. No automatic questionnaire is shown in this preview.
- Website rendered in Chrome on desktop and a 390px mobile viewport; no horizontal overflow, app screenshots load at their original aspect ratio. Download, source and privacy links use explicit destinations; native video controls require user playback.
- Public screenshots contain synthetic data only. Reviewed all 66 historical blobs for common credential patterns, databases, environment files and absolute home paths; no matches. Historical commits retain ordinary earlier development/validation notes, not activity records. This targeted audit is not a guarantee against every possible secret.
- Release archive contains the app only, no databases or exports; checksum is published alongside it.

Not tested: remote Cloudflare submission, production retention, fresh-user browser permission prompts, Intel/macOS 13 runtime, live sleep/wake regression or Developer ID notarization. Cloudflare authorization is deferred. Signing certificate is unavailable. The preview is ad-hoc signed and not notarized; automatic feedback stays disabled until a live endpoint is configured and verified.

## Benefit-led demo revision — 2026-11-08

Revised the 14-second demo's hook and closing benefit, with the opening click moved to 3.2s. HyperFrames 0.8.223 check passed with zero errors/warnings; beat, phone and transition frames were inspected. Final H.264 export: 1920×1080, 30fps, 420 frames, 14.000s, 1,071,992 bytes, intentionally silent. Native dashboard remains the existing synthetic-data capture. See `promo/REVIEW.md` and `promo/STYLE-APPLICATION.md`. No app code/history changed; XCTest was not rerun for this media-only update.
