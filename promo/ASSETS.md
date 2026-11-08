# Assets

- `dashboard.png` and `week.png`: real SwiftUI views rendered by `scripts/screenshots.sh` with synthetic records in a temporary SQLite database. No private activity data.
- `mac/menu-bar.png`: staged Finder menu bar rendered offscreen with AppKit system fonts and SF Symbols. The AI Usage item displays time, matching the current app; the clock and usage are illustrative.
- `mac/cursor.png`: native macOS arrow cursor. `mac/finder.png`, `safari.png`, `notes.png`, and `settings.png`: locally installed system application icons. Regenerate these assets from the repository root with `swift Design/GenerateDemoAssets.swift`. This does not open windows or access activity records.
- Wallpaper: original SVG curves in `compositions/overview.html`; not an Apple wallpaper or a capture of the user's desktop.
- Product names and icons belong to their respective owners and appear to identify the demonstrated products and macOS environment; the MIT license covers this project's original source, not third-party trademarks or artwork.
- `app-icon.png`: original application icon, retained for future edits.
- Registry searched for cursor/click/camera motion; inspected `cursor-zoom-follow` as a reference. The two-click composition is implemented locally without including the unused registry component.
- No voiceover, music, external footage or generated imagery. Silent 14-second staged interaction, labelled throughout. Native dashboard pixels are ungraded.
