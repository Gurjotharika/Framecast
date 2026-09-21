#!/bin/zsh
set -euo pipefail

# Framecast release: archive, Developer ID export, DMG, Sparkle appcast, GitHub Release.
# Next release: bump MARKETING_VERSION and CURRENT_PROJECT_VERSION, then run this again.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="Video"
APP_NAME="Framecast"
TEAM_ID="U253D92J7M"
GITHUB_OWNER="Gurjotharika"
GITHUB_REPO="Framecast"
SPARKLE_VERSION="2.10.0"
TOOLS_DIR="$ROOT/Tools/Sparkle"
DIST="$ROOT/dist"
RELEASES="$DIST/releases"
BUILD="$DIST/build"
ARCHIVE="$BUILD/$APP_NAME.xcarchive"
EXPORT="$BUILD/export"
EXPORT_OPTS="$ROOT/scripts/ExportOptions.plist"
FEED_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest/download/appcast.xml"

MARKETING_VERSION="$(grep -m1 'MARKETING_VERSION' "$ROOT/Video.xcodeproj/project.pbxproj" | sed 's/.*= //;s/;//' | tr -d '[:space:]')"
BUILD_NUMBER="$(grep -m1 'CURRENT_PROJECT_VERSION' "$ROOT/Video.xcodeproj/project.pbxproj" | sed 's/.*= //;s/;//' | tr -d '[:space:]')"
DMG_NAME="${APP_NAME}-${MARKETING_VERSION}.dmg"
TAG="v${MARKETING_VERSION}"
DOWNLOAD_PREFIX="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/${TAG}/"

echo "==> Framecast ${MARKETING_VERSION} (${BUILD_NUMBER})"

mkdir -p "$TOOLS_DIR" "$RELEASES" "$BUILD"

if [[ ! -x "$TOOLS_DIR/bin/generate_keys" ]]; then
  echo "==> Downloading Sparkle ${SPARKLE_VERSION} tools"
  curl -L "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz" \
    -o "$BUILD/Sparkle.tar.xz"
  tar -xJf "$BUILD/Sparkle.tar.xz" -C "$BUILD"
  KEYGEN="$(find "$BUILD" -name generate_keys -type f | head -n1)"
  if [[ -n "$KEYGEN" ]]; then
    SPARKLE_ROOT="$(cd "$(dirname "$KEYGEN")/.." && pwd)"
    rm -rf "$TOOLS_DIR"
    mkdir -p "$TOOLS_DIR"
    cp -R "$SPARKLE_ROOT/bin" "$TOOLS_DIR/"
  fi
fi

if [[ ! -x "$TOOLS_DIR/bin/generate_keys" ]]; then
  echo "Could not find Sparkle generate_keys. Put Sparkle's bin/ in Tools/Sparkle/bin/" >&2
  exit 1
fi

echo "==> Sparkle signing key"
EXISTING_KEY="$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$ROOT/Video/Info.plist" 2>/dev/null || true)"
if [[ -n "$EXISTING_KEY" && "$EXISTING_KEY" != REPLACE* ]]; then
  echo "    Using existing SUPublicEDKey"
else
  echo "    Run Tools/Sparkle/bin/generate_keys in Terminal.app, then paste the public key into Video/Info.plist as SUPublicEDKey."
  exit 1
fi

echo "==> Archive"
rm -rf "$ARCHIVE" "$EXPORT"
xcodebuild archive \
  -project "$ROOT/Video.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE" \
  -destination 'generic/platform=macOS' \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "==> Export Developer ID"
if ! xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT" \
  -exportOptionsPlist "$EXPORT_OPTS"; then
  echo "Developer ID export failed. Need a Developer ID Application certificate for team ${TEAM_ID}." >&2
  echo "Falling back to the archived app (not notarized)." >&2
  APP_PATH="$ARCHIVE/Products/Applications/${APP_NAME}.app"
else
  APP_PATH="$EXPORT/${APP_NAME}.app"
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "Missing ${APP_NAME}.app at $APP_PATH" >&2
  exit 1
fi

STAGE="$BUILD/dmg"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP_PATH" "$STAGE/${APP_NAME}.app"
ln -s /Applications "$STAGE/Applications"

DMG_PATH="$RELEASES/$DMG_NAME"
echo "==> Create DMG $DMG_NAME"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

if command -v xcrun >/dev/null && xcrun notarytool history --keychain-profile "notarytool" >/dev/null 2>&1; then
  echo "==> Notarize DMG"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "notarytool" --wait
  xcrun stapler staple "$DMG_PATH"
else
  echo "==> Skipping notarization (store credentials with:"
  echo "    xcrun notarytool store-credentials notarytool --apple-id YOU@email --team-id ${TEAM_ID})"
fi

NOTES="$RELEASES/${APP_NAME}-${MARKETING_VERSION}.md"
cat > "$NOTES" <<EOF
# Framecast ${MARKETING_VERSION}

- Record a website, drop it into a device mockup, and export MP4, MOV, or GIF.
EOF

echo "==> Sparkle appcast"
set +e
perl -e 'alarm shift; exec @ARGV' 60 \
  "$TOOLS_DIR/bin/generate_appcast" \
  --download-url-prefix "$DOWNLOAD_PREFIX" \
  "$RELEASES"
APPCAST_STATUS=$?
set -e

python3 - "$RELEASES/appcast.xml" "$GITHUB_OWNER" "$GITHUB_REPO" "$APP_NAME" <<'PY' || true
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
owner, repo, app = sys.argv[2], sys.argv[3], sys.argv[4]
if not path.exists():
    raise SystemExit(0)
text = path.read_text()

def version_from(filename, suffix):
    prefix = f"{app}-"
    if filename.startswith(prefix) and filename.endswith(suffix):
        return filename[len(prefix) : -len(suffix)]
    return None

def enclosure(match):
    filename = match.group(1)
    version = version_from(filename, ".dmg") or "1.0"
    url = f"https://github.com/{owner}/{repo}/releases/download/v{version}/{filename}"
    return f'url="{url}"'

def notes(match):
    filename = match.group(1)
    version = version_from(filename, ".md") or "1.0"
    url = f"https://github.com/{owner}/{repo}/releases/download/v{version}/{filename}"
    return f"<sparkle:releaseNotesLink>{url}</sparkle:releaseNotesLink>"

text = re.sub(r'url="[^"]*/(Framecast-[^"]+\.dmg)"', enclosure, text)
text = re.sub(
    r"<sparkle:releaseNotesLink>[^<]*(Framecast-[^<]+\.md)</sparkle:releaseNotesLink>",
    notes,
    text,
)
path.write_text(text)
PY

if [[ "$APPCAST_STATUS" -ne 0 || ! -f "$RELEASES/appcast.xml" ]]; then
  echo "Appcast signing needs Keychain access (Allow the Sparkle private key)."
  echo "Run this in Terminal.app, then click Allow:"
  echo "  $TOOLS_DIR/bin/generate_appcast --download-url-prefix '$DOWNLOAD_PREFIX' '$RELEASES'"
fi

if command -v gh >/dev/null && git remote get-url origin >/dev/null 2>&1; then
  echo "==> GitHub Release ${TAG}"
  if gh release view "$TAG" >/dev/null 2>&1; then
    gh release upload "$TAG" "$DMG_PATH" "$NOTES" "$RELEASES/appcast.xml" --clobber
  else
    gh release create "$TAG" "$DMG_PATH" "$NOTES" "$RELEASES/appcast.xml" \
      --title "Framecast ${MARKETING_VERSION}" \
      --notes-file "$NOTES"
  fi
else
  echo "==> Skipping GitHub Release (no origin remote). Create the repo, then re-run or:"
  echo "    gh release create ${TAG} \"$DMG_PATH\" \"$NOTES\" \"$RELEASES/appcast.xml\" --title \"Framecast ${MARKETING_VERSION}\" --notes-file \"$NOTES\""
fi

echo
echo "Done."
echo "  DMG:     $DMG_PATH"
echo "  Appcast: $RELEASES/appcast.xml"
echo "  Feed:    ${FEED_URL}"
echo
echo "Next update: bump MARKETING_VERSION and CURRENT_PROJECT_VERSION, commit, then run this script again."
