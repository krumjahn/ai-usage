# Benefit-led menu-bar demo review

14 seconds, 1920×1080, 30fps, silent. The opening asks “What’s your most-used AI tool? You might be wrong.” The pointer clicks the menu-bar timer at 3.2s; the real native dashboard appears at 3.3s, followed by an anchored camera move from 4–5.2s. The ranking and combined web/desktop time hold until the outside click at 10.2s. The close reads “See where your AI time goes. Free. Open source. Local to your Mac.”

This is a copy and timing revision of the existing Mac desktop demo. The previous output/source are preserved in Git and the workspace's `work/ai-habits-demo-before/`. No weekly recap, peer comparison, productivity claim, app change or website deployment was added.

The desktop interaction is staged. Dashboard pixels come from the actual SwiftUI app with synthetic records; the persistent “Staged macOS desktop · Sample data” label remains. No private activity history is used.

## Verification

- `npx --yes hyperframes@0.8.223 check --json`: zero errors or warnings across lint, runtime, layout, contrast and craft. Informational `audio_none` is intentional.
- `snapshot --at 0,3.3,5.5,11.8`: inspected first frame, opening, ranking and final state.
- `snapshot --review` and `snapshot --review --composition overview`: inspected beat/phone sheets and both headline transition strips. No clipped copy; no camera jump at the text transitions; dismissal follows the outside click.
- HyperFrames preview reached 00:14 with the new closing copy through its Play control. This verifies playback completion, not continuous human observation of all motion.
- `render --quality delivery --fps 30`: H.264, 420 frames, 1920×1080, 14.000 seconds, 1,071,992 bytes. Inspected an encoded 5.5s frame and extracted a new first-frame poster.
- App tests were not rerun: no Swift, database, permissions or app binary changes.

The weakest view remains the landscape demo at phone width: the hook is visible, but individual tool subtitles require fullscreen. A dedicated vertical edit could improve this; it is not part of this revision. No voiceover/music was added and nothing was auditioned. The private Fish Audio preview remains separate. The benefit-led hook is a positioning test, not a measured conversion improvement.
