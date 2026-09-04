#!/bin/zsh

set -euo pipefail

project_root="${0:A:h:h}"
configuration="${1:-release}"

cd "$project_root"

if [[ ! -f "$project_root/Support/BrowserBranch.icns" \
    || "$project_root/Assets/BrowserBranchIcon.png" -nt "$project_root/Support/BrowserBranch.icns" ]]; then
    "$project_root/scripts/generate-icon.sh" >/dev/null
fi

swift build --configuration "$configuration"

binary_directory="$(swift build --configuration "$configuration" --show-bin-path)"
application_directory="$project_root/.build/BrowserBranch.app"

rm -rf "$application_directory"
mkdir -p "$application_directory/Contents/MacOS" "$application_directory/Contents/Resources"
cp "$binary_directory/BrowserBranch" "$application_directory/Contents/MacOS/BrowserBranch"
cp "$project_root/Support/Info.plist" "$application_directory/Contents/Info.plist"
cp "$project_root/Support/BrowserBranch.icns" "$application_directory/Contents/Resources/BrowserBranch.icns"
printf 'APPL????' > "$application_directory/Contents/PkgInfo"

codesign --force --deep --sign - "$application_directory"

echo "$application_directory"
