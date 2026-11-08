# Contributing

Keep AI Usage small, native and time-focused. Open an issue describing the problem and expected behavior before a large change. Pull requests should explain what changed and how it was verified.

## Boundaries

- Never collect prompts, source code, window titles, page contents or full URLs.
- Never infer terminal agents from terminal foreground time alone.
- Preserve raw observations; classifier changes must not rewrite activity history.
- Keep the foreground collector independent of website response times.
- Activity stays local. Feedback is optional and must never include activity records.
- Never commit databases, exports, access tokens, signing identities or real usage screenshots.
- Target macOS 13. Check availability of every SwiftUI API you introduce.

## Validation

Run the README's macOS test command. Classifier changes need examples for matches and near misses; analytics changes need overlap, midnight and idle cases. Use temporary databases. Backend changes need `cd website && npm ci && npm test && npm run types && npm run check`.

Run `scripts/screenshots.sh` to refresh the real SwiftUI screenshots with synthetic data. It does not start the collector or open the production database. App icons vary with applications installed on the generating Mac. Caption screenshots as illustrative data.

Please reproduce bugs without attaching personal history. Include macOS version, app version, relevant browser/app name, permission status, expected behavior and steps to reproduce.
