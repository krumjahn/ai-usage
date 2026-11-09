# Hosting and optional feedback

**Website launch is deferred.** GitHub Pages has been unpublished, the repository homepage link cleared, and `.github/workflows/pages.yml` disabled. The workflow has only a manual trigger, so source updates cannot automatically publish the site. Keep it disabled until the website launch is explicitly resumed.

The public source, screenshots and video remain available on GitHub. Website source is preserved in `website/`; the standalone demo is in `docs/media/ai-usage-demo.mp4`.

When website work resumes, enable Pages with GitHub Actions as the build source, enable the Website workflow, and dispatch it manually. Static asset links are relative, so `/ai-usage/` works. The site does not depend on Cloudflare, collect answers or run analytics.

## Live private feedback service

Deployed on 2026-11-09 to the existing Cloudflare **Workers Free ($0)** account. No plan upgrade was made.

- Worker: `ai-usage-feedback`
- Endpoint: `https://ai-usage-feedback.rumjahn.workers.dev/api/feedback`
- D1: `ai-usage-feedback`, binding `FEEDBACK_DB`; database ID is in `website/wrangler.jsonc` (not a credential).
- Retention cron: `17 3 * * *` (03:17 UTC daily). Responses older than 90 days are removed at the next successful run.
- This deployment has no static assets or public response-read endpoint. `/` returns 404; the marketing website remains deferred.
- Worker request logs and traces are disabled. Cloudflare still processes normal connection metadata.

Prerequisites: Node 22+, Cloudflare Workers/D1 access, and an authenticated Wrangler CLI. Use the project-pinned Wrangler. Never put account tokens in this repository.

To update the existing service:

```sh
cd website
npm ci
npx wrangler whoami
# If authentication has expired: npx wrangler login
npm test
npm run types
npm run check
npx wrangler deploy --dry-run
npx wrangler d1 migrations apply FEEDBACK_DB --remote
npm run deploy
```

For a separate deployment, create your own D1 database with `npx wrangler d1 create <your-database-name>`, use its name and ID in the config, and choose a unique Worker name. Do not point a fork at the project's response database. Database IDs are configuration, not credentials; writes still require your account's authorization. The deploy script rejects an all-zero database ID.

Use the HTTPS workers.dev URL printed by deploy. Check `/api/health`, send a clearly labelled disposable feedback submission, and verify its matching ID in D1. Retry the same ID to verify that only one row exists, then remove only those disposable test rows. Check that GET `/api/feedback` returns 405 and `/api/export` returns 404. Verify a 429 response with a small burst of invalid submissions. The limiter is approximate: more than five requests can pass before counters synchronize. Confirm the daily retention cron after deployment; it is not an exact 90-day expiry timer.

`AIUsageFeedbackEndpoint` in `project.yml` is enabled in v0.1.1-preview. After changing it, run `xcodegen generate`, the macOS tests, and a new release build. The client rejects insecure URLs and redirects and sends no cookies or activity history. Starting with v0.1.2-preview, onboarding opens the dashboard and welcome sheet automatically on first launch. The `feedback.onboarding.offered.v2` preference records this new offer once per local defaults profile, including users upgrading from the earlier dashboard-only flow. Skip sends nothing; manual feedback remains available in Settings. An existing v0.1.0-preview installation must update to receive this feature.

The native client intentionally sends no Origin header. The API does not enable cross-origin browser forms. Public privacy notes are kept in `website/public/privacy.html` and linked from the README; publishing the website is a separate task.

## Private response storage

The table stores random submission ID, timestamp, reason, use case, optional wish, app version and schema version. No email, account, install identifier or activity data. Answers are not logged. IP-derived rate-limit keys are transient and are not persisted in D1. Cloudflare processes normal connection metadata. A daily cron deletes responses older than 90 days; monitor it so retention remains effective.

Export responses only to a private, ignored local file:

```sh
npx wrangler d1 execute FEEDBACK_DB --remote --command 'SELECT created_at, reason, use_case, wish, app_version FROM feedback ORDER BY created_at DESC' --json > feedback-export.json
```

Do not commit or publish exports. Treat free text as untrusted and escape spreadsheet formulas if converting to CSV. The native app supports retries with the same random submission ID to avoid duplicates; this does not authenticate a user. The approximate per-location rate limiter helps casual spam but is not a global quota or bot-proof control. Add stronger abuse protection if needed before large promotion.

## Local development

```sh
cd website
npm ci
npx wrangler d1 migrations apply FEEDBACK_DB --local
npm run dev
```

This runs the API only. Preview the deferred static website separately from the repository root with `python3 -m http.server 8080 --directory website/public`.

Local Wrangler binds its own development database under `.wrangler/`; it never uses the app's production SQLite file. POST JSON to `/api/feedback` with `id` (UUID v4), `schemaVersion: 1`, `reason`, `useCase`, `wish` and `appVersion`. Enum values are defined in `src/index.js` and `App/FeedbackSubmission.swift`.

## Rebuild the demo

From `promo/`, use the pinned scripts in `package.json`: `npm run check`, `npm run dev`, and `npm run render -- --output ../docs/media/ai-usage-demo.mp4`. The 14-second silent film stages a macOS menu-bar click using actual native views with synthetic records. Regenerate its desktop assets from the repository root with `swift Design/GenerateDemoAssets.swift`. Regenerate screenshots first with `scripts/screenshots.sh`; copy the chosen dashboard/week images into `promo/assets/` and website assets. `promo/REVIEW.md` records visual checks.
