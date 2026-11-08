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

24 XCTest cases passed, zero failures. This includes existing collection/storage/analytics/privacy/layout/navigation tests and three new feedback tests covering one-time configured onboarding, skip/no send, payload minimization, Unicode length limit, retry IDs, changed answers, error/success state and endpoint restrictions. Release build and signature verification passed. Xcode emitted test framework warnings for its newer XCTest deployment target and benign local Intents service diagnostics.

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
