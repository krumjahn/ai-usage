# Hosting and optional feedback

**Website launch is deferred.** GitHub Pages has been unpublished, the repository homepage link cleared, and `.github/workflows/pages.yml` disabled. The workflow has only a manual trigger, so source updates cannot automatically publish the site. Keep it disabled until the website launch is explicitly resumed.

The public source, screenshots and video remain available on GitHub. Website source is preserved in `website/`; the standalone demo is in `docs/media/ai-usage-demo.mp4`.

When website work resumes, enable Pages with GitHub Actions as the build source, enable the Website workflow, and dispatch it manually. Static asset links are relative, so `/ai-usage/` works. The site does not depend on Cloudflare, collect answers or run analytics.

## Connect private feedback later

Prerequisites: Node 22+, Cloudflare account with Workers/D1 access, and an authenticated Wrangler CLI. Use the project-pinned Wrangler. Never put account tokens in this repository.

```sh
cd website
npm ci
npx wrangler login
npx wrangler d1 create ai-usage-feedback
```

Replace the all-zero `database_id` in `website/wrangler.jsonc` with the returned D1 ID. Database IDs are configuration, not credentials. Keep `FEEDBACK_DB` as the binding. The guarded deploy script refuses the placeholder configuration.

```sh
npm test
npm run types
npm run check
npx wrangler d1 migrations apply FEEDBACK_DB --remote
npm run deploy
```

Use the actual HTTPS workers.dev URL printed by deploy. Check `/api/health`; test a clearly labelled disposable feedback submission and verify it in D1 before enabling onboarding. Confirm rate limiting and the daily retention cron in the Cloudflare dashboard. No response read endpoint is exposed.

Set `AIUsageFeedbackEndpoint` in `project.yml` to `https://<deployed-host>/api/feedback`, then run `xcodegen generate`, the macOS tests, and a new release build. Keep it empty until a real deployment is verified. The client rejects insecure URLs and redirects; it sends no cookies or activity history. Automatic onboarding is offered only in configured builds, once per local defaults profile. Skip sends nothing; manual feedback is available in Settings.

If the static site stays on GitHub Pages, the native client can still send to the separate Worker. Its absent Origin is intentional; the API does not enable cross-origin browser forms. The Worker can also host the static site later. Update public privacy notes when the endpoint is enabled.

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

Local Wrangler binds its own development database under `.wrangler/`; it never uses the app's production SQLite file. POST JSON to `/api/feedback` with `id` (UUID v4), `schemaVersion: 1`, `reason`, `useCase`, `wish` and `appVersion`. Enum values are defined in `src/index.js` and `App/FeedbackSubmission.swift`.

## Rebuild the demo

From `promo/`, use the pinned scripts in `package.json`: `npm run check`, `npm run dev`, and `npm run render -- --output ../website/public/assets/demo.mp4`. The 14-second silent film uses actual native views with synthetic records. Regenerate screenshots first with `scripts/screenshots.sh`; copy the chosen dashboard/week images into `promo/assets/` and website assets. `promo/REVIEW.md` records visual checks.
