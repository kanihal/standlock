#!/bin/bash
# Requires a macOS desktop session. Compiles the real settings views into a small UI host.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
swift build --package-path StandLockKit
package_bin="$(swift build --package-path StandLockKit --show-bin-path)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/standlock-settings-ui.XXXXXX")"
trap 'rm -r "$test_dir"' EXIT

xcrun swiftc -parse-as-library -target "$(uname -m)-apple-macosx13.0" \
    -I "$package_bin" -L "$package_bin" -lStandLockCore \
    StandLockKit/Tests/SettingsUI/ScheduleRhythmEditingRegression.swift \
    StandLock/Views/Settings/Schedules/ScheduleRhythmSection.swift \
    StandLock/Views/Settings/Components/{SettingsTokens,SettingsSection,SettingsGroup,SettingsToggleRow,SettingsRow,SettingsIconChip,SettingsRowTone,SettingsDescription}.swift \
    StandLock/AppState/AppTheme.swift \
    StandLock/Views/BreakScreen/BreakPalette.swift \
    -o "$test_dir/ScheduleRhythmEditingRegression"
"$test_dir/ScheduleRhythmEditingRegression"
