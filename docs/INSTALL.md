# Install the preview

AI Usage supports macOS 13+. The release archive states its supported processor architectures. The app is a menu-bar utility; it does not need to stay in the Dock.

## Source build (recommended for this preview)

Use the build commands in the README. XcodeGen generates the project, Xcode builds it with an ad-hoc signature. There are no third-party Swift packages. Quit the previous instance before launching a different build. Copy your built app to Applications if desired.

## Downloaded preview

1. Download `AI-Usage-0.1.0-preview.zip` and `SHA256SUMS.txt` from the same GitHub release.
2. Compare `shasum -a 256 AI-Usage-0.1.0-preview.zip` with the published checksum, then unzip it.
3. Quit any running AI Usage instance before replacing it. Move `AI Usage.app` to Applications and open it.
4. This preview is not Developer ID signed or notarized. macOS may refuse it. Review the source or build locally; don't disable Gatekeeper system-wide. A properly signed release is planned when a Developer ID certificate is available.

Click the time in the menu bar to see the dashboard. Open the app again to show a window if its menu item is hidden by a crowded menu bar or a notch.

## Website identification

In the gear menu, enable **Identify AI websites**. Focus a recognized AI site in Safari, Chrome, Arc, Edge or Brave and grant Automation access when macOS asks. Permissions are managed in System Settings → Privacy & Security → Automation. App foreground tracking does not require Accessibility, Screen Recording or Input Monitoring permission.

It only records the foreground app and recognized site. Having an AI app or tab open in the background does not count. Idle time, sleeping, and time in unrecognized websites do not add AI minutes.

## Upgrades and removal

Keep bundle identifier `com.rumjahn.attentionledger` and its application support directory to preserve existing history. Quit before replacing a build. Removing the app bundle does not remove your local activity database. Use Settings → Export JSON for a copy, or Delete history for explicit removal. Device backups and exported copies are separate.

The optional feedback questionnaire is inactive in v0.1.0-preview until a service endpoint is configured. No provider credentials or subscription connections are used.
