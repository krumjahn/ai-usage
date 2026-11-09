# AI Usage demo videos

The current README video is [ai-usage-laptop-demo.mp4](ai-usage-laptop-demo.mp4): 8 seconds, 1920×1080, 30fps, H.264 with stereo AAC audio. It shows a staged MacBook and the real native dashboard populated with synthetic records. No private activity history appears.

The earlier [ai-usage-demo.mp4](ai-usage-demo.mp4) is preserved; its editable source is in [promo](../../promo).

## Screenshots and embedding

[Native app screenshots](../images) include the light/dark dashboard, seven-day view, Settings, and optional feedback form. The screenshot generator is `scripts/screenshots.sh`; it uses synthetic records in a temporary database. The feedback form remains inactive until its service is connected.

The repository README uses GitHub’s `user-attachments` video URL for native playback controls. To replace the video, upload the approved MP4 through GitHub’s Markdown attachment control and update that URL. A relative repository-file link only navigates to the file. Keep the versioned MP4 and release download as portable copies.

## Credits

- MacBook model and planar screen mapping adapted from HeyGen’s [HyperFrames macOS Tahoe block](https://github.com/heygen-com/hyperframes/tree/main/registry/blocks/macos-tahoe-liquid-glass), distributed in its Apache-2.0 repository. See [upstream license](HYPERFRAMES-LICENSE.txt). The camera choreography, lighting, wallpaper, typography, and native dashboard presentation were changed for AI Usage. The original template’s desktop, wallpaper, and app-window content are not used.
- Native dashboard: AI Usage, rendered with synthetic sample records. Product and system icons belong to their respective owners; no endorsement is implied.
- Click: [Light Taps by Squirrel_404](https://freesound.org/people/Squirrel_404/sounds/716245/), CC0, trimmed and mixed.
- Camera cue: [UI Hover Micro Swish by Qvantor](https://freesound.org/people/Qvantor/sounds/878248/), CC0, trimmed and mixed.
- Rendered with HyperFrames, Three.js and GSAP. This video contains no Fish Audio narration or music.

The application’s MIT license does not relicense third-party marks, sounds, or upstream assets.
