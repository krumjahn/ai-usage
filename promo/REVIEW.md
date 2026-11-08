# Menu-bar demo review

14 seconds, 1920×1080, 30fps, silent. The film establishes a macOS desktop, moves the native pointer to AI Usage's time-only menu-bar item, clicks, opens the real native dashboard screenshot below it, and moves closer for reading. A second click on the empty desktop dismisses the panel and the camera returns. This demonstrates where the app lives without inventing a Dock icon or changing the product.

The desktop and interaction are staged, not a live screen recording. The dashboard is an authentic SwiftUI capture with synthetic records; all figures and the clock are illustrative. A persistent label says “Staged macOS desktop · Sample data.” No private desktop or activity history appears.

## Visual checks

- Full HyperFrames check: zero errors or warnings. The only informational finding is intentional silence; this remains a short, user-started 14-second demo.
- Reviewed settled beats, both headline transitions, the 360px phone sheet, opening-click frames, and the dismissal seam. Fixed dismissal to begin after the outside click, at 10.22 seconds.
- The camera holds while viewers read. Pointer and panel share camera coordinates so their attachment to the menu bar remains consistent.
- Inspected an encoded frame and measured the final file separately with ffprobe. This is media validation, not a new app functionality test.

The weakest view is the initial full desktop: the menu-bar time is naturally small. Pointer movement and the opening panel establish the action; the later close-up makes the total legible. Individual tool subtitles still require fullscreen on a phone. A separate vertical social cut could use a tighter crop, but this update preserves the existing landscape format. No new music, narration, website deployment or app features were added.

Editable source remains in `promo/` and the HyperFrames preview.
