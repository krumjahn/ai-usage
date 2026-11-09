#!/bin/bash
# Package a verified app without installing, launching, signing, or changing it.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 /path/to/AI\ Usage.app /path/to/output.dmg" >&2
  exit 2
fi
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
app_path=$1
output_path=$2
DMGBUILD_BIN=${DMGBUILD_BIN:-dmgbuild}
[[ -d "$app_path/Contents" ]] || { echo "App bundle not found" >&2; exit 1; }
[[ ! -e "$output_path" ]] || { echo "Output already exists; choose a new path" >&2; exit 1; }
command -v "$DMGBUILD_BIN" >/dev/null || { echo "Install dmgbuild==1.6.7 in a virtual environment first" >&2; exit 1; }
[[ $(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app_path/Contents/Info.plist") == com.rumjahn.attentionledger ]] || {
  echo "This packager only accepts AI Usage" >&2; exit 1;
}
app_version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app_path/Contents/Info.plist")
executable=$(/usr/libexec/PlistBuddy -c 'Print CFBundleExecutable' "$app_path/Contents/Info.plist")
codesign --verify --deep --strict "$app_path"
architectures=$(lipo -archs "$app_path/Contents/MacOS/$executable")
for architecture in arm64 x86_64; do
  [[ " $architectures " == *" $architecture "* ]] || {
    echo "Universal app is missing $architecture" >&2; exit 1;
  }
done

staging=$(mktemp -d "${TMPDIR:-/tmp}/ai-usage-dmg.XXXXXX")
trap 'rm -rf "$staging"' EXIT
ditto "$app_path" "$staging/AI Usage.app"
cat > "$staging/Read Me.txt" <<'EOF'
AI Usage — macOS menu-bar app

INSTALL
1. Quit any running AI Usage instance before replacing it.
2. Drag AI Usage.app to the Applications folder beside it.
3. Eject this disk image, then open AI Usage from Applications.
4. Click the elapsed time in your menu bar to open the dashboard.
   If it is hidden by a crowded menu bar, open AI Usage again.

macOS 13 or later. One universal app for Apple Silicon and Intel.
This developer preview is ad-hoc signed, not Developer ID signed or
notarized. macOS may block it. Only proceed if you trust this project.
For Apple's per-app approval instructions, see:
https://support.apple.com/en-us/102445
Do not disable Gatekeeper system-wide. Building from source is an option.

Browser identification is opt-in under Settings. Allow the macOS
Automation prompt for your browser when you enable it. Only active
foreground time counts; open background tabs and idle time do not.

Your activity stays local. Replacing the app preserves its history.
This disk image contains no activity data or account credentials.
The optional questionnaire sends only answers you explicitly submit and app
version to a private Cloudflare database. Skip sends nothing. Responses are
kept for 90 days. Activity history is never included.

Source, installation details, and issue reports:
https://github.com/krumjahn/ai-usage

LICENSE
EOF
cat "$repo_dir/LICENSE" >> "$staging/Read Me.txt"
mkdir -p "$(dirname "$output_path")"
"$DMGBUILD_BIN" -s "$repo_dir/scripts/dmg-settings.py" -D "staging=$staging" \
  "AI Usage $app_version" "$output_path"
hdiutil verify "$output_path"
shasum -a 256 "$output_path"
