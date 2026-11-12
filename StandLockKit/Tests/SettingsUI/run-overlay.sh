#!/bin/bash
# Requires a macOS desktop session. Connect multiple displays to cover secondary windows.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
swift build --package-path StandLockKit
package_bin="$(swift build --package-path StandLockKit --show-bin-path)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/standlock-overlay-ui.XXXXXX")"
trap 'rm -r "$test_dir"' EXIT
test_app="$test_dir/OverlayWindowRegression.app"
mkdir -p "$test_app/Contents/MacOS"
cat > "$test_app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>OverlayWindowRegression</string>
<key>CFBundleIdentifier</key><string>com.standlock.tests.overlay-window</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST
xcrun swiftc -parse-as-library -target "$(uname -m)-apple-macosx13.0" \
    -I "$package_bin" -L "$package_bin" -lStandLockCore -lLocking \
    StandLockKit/Tests/SettingsUI/OverlayWindowRegression.swift \
    StandLock/AppState/{OverlayWindowController,LanguageStore,ThemeStore,AppTheme,MediaController}.swift \
    StandLock/Views/LocalizedRoot.swift \
    StandLock/Views/BreakScreen/{BreakOverlayWindow,BreakScreenLook,BreakPalette,BreakTypography,BreakDismissalState,ManuscriptBreakView,RestRecallContent,ReorganizeActionIcon,TimerNumerals,HexColor+SwiftUI,EmergencyComboMonitor}.swift \
    -o "$test_app/Contents/MacOS/OverlayWindowRegression"
open -n -W "$test_app" --stdout "$test_dir/stdout" --stderr "$test_dir/stderr" --args "$test_dir/passed"
cat "$test_dir/stdout" "$test_dir/stderr"
test -f "$test_dir/passed"
