#!/bin/zsh

set -euo pipefail

project_root="${0:A:h:h}"
source_icon="$project_root/Assets/BrowserBranchIcon.png"
iconset_directory="$project_root/.build/BrowserBranch.iconset"
output_icon="$project_root/Support/BrowserBranch.icns"

if [[ ! -f "$source_icon" ]]; then
    echo "Missing source icon: $source_icon" >&2
    exit 1
fi

rm -rf "$iconset_directory"
mkdir -p "$iconset_directory"

sips -z 16 16 "$source_icon" --out "$iconset_directory/icon_16x16.png" >/dev/null
sips -z 32 32 "$source_icon" --out "$iconset_directory/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$source_icon" --out "$iconset_directory/icon_32x32.png" >/dev/null
sips -z 64 64 "$source_icon" --out "$iconset_directory/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$source_icon" --out "$iconset_directory/icon_128x128.png" >/dev/null
sips -z 256 256 "$source_icon" --out "$iconset_directory/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$source_icon" --out "$iconset_directory/icon_256x256.png" >/dev/null
sips -z 512 512 "$source_icon" --out "$iconset_directory/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$source_icon" --out "$iconset_directory/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$source_icon" --out "$iconset_directory/icon_512x512@2x.png" >/dev/null

iconutil -c icns "$iconset_directory" -o "$output_icon"
echo "$output_icon"
