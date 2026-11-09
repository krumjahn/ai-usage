# Package a macOS DMG

Each release DMG and ZIP must contain the same verified universal app. Packaging does not turn an ad-hoc signature into a Developer ID signature or notarize the application. The original v0.1.0-preview assets remain available unchanged.

## Prerequisites

Run on macOS with Python 3 and Xcode command-line tools. The packaging-only dependency is pinned; it is not bundled into the app:

```sh
python3 -m venv /tmp/ai-usage-dmg-tools
/tmp/ai-usage-dmg-tools/bin/python -m pip install dmgbuild==1.6.7
```

Supply a previously validated Release app, not a running installed bundle. For a new application version, run the README's build/tests first, build with `ONLY_ACTIVE_ARCH=NO`, and verify the binary contains `arm64` and `x86_64`. For packaging-only updates, verify the published ZIP checksum and extract it into a temporary folder with `ditto -x -k`.

```sh
DMGBUILD_BIN=/tmp/ai-usage-dmg-tools/bin/dmgbuild scripts/package-dmg.sh "/path/to/AI Usage.app" release/AI-Usage-0.1.2-preview.dmg
```

The script verifies the bundle identity, signature, and both architectures; copies it into an isolated temporary directory; creates a compressed, read-only HFS+ disk image with an Applications shortcut, Finder layout, installation notes, and license; verifies the disk image; and prints its SHA-256. It refuses to overwrite an existing output. It never installs, launches or re-signs the app.

## Verify and publish

Mount the result read-only with `hdiutil attach -readonly -nobrowse`. Verify the app signature again, compare all app file hashes against the input, confirm `Applications` points to `/Applications`, and inspect the Finder layout. Copy into a temporary installation folder and verify the copy, without launching another production collector. Detach the test mount afterward.

From `release/`, regenerate the checksum manifest:

```sh
shasum -a 256 AI-Usage-0.1.2-preview.dmg AI-Usage-0.1.2-preview.zip > SHA256SUMS.txt
```

Upload the DMG and refreshed manifest to the matching release, and link the DMG in the README and release notes. Verify the remote asset size and digest after upload. Keep the ZIP, release tag and existing app unchanged for a packaging-only update. A new application version requires a new version/tag and checksums.

The preview remains explicitly unnotarized. For a future friction-free download, obtain a **Developer ID Application** certificate, sign the application with the required hardened-runtime entitlements, notarize and staple it, and validate downloaded-app behavior on a clean Mac before calling the release notarized. Apple Development, Apple Distribution and Mac App Store certificates do not substitute for Developer ID distribution.
