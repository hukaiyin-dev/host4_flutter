#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$EXAMPLES_DIR/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d%H%M)"
OUTPUT="$EXAMPLES_DIR/host4_gmacro_demo_${TIMESTAMP}.zip"

INCLUDES=(
  "examples/host4_gmacro_demo"
  "packages/host4_flutter_gmacro_demo_ui"
  "packages/host4_flutter_ble"
  "packages/host4_flutter_mfi"
  "packages/host4_flutter_usb"
  "packages/host4_flutter_gmacro"
  "packages/host4_flutter_protocol"
  "packages/host4_flutter_transport"
  "packages/host4_flutter_device_native"
  "packages/host4_flutter_log"
  "packages/host4_flutter_core"
)

EXCLUDES=(
  "*/.dart_tool/*"
  "*/.symlinks/*"
  "*/build/*"
  "*/.git/*"
  "*/Pods/*"
  "*/.idea/*"
  "*/.DS_Store"
)

cd "$REPO_ROOT"

for path in "${INCLUDES[@]}"; do
  if [[ ! -e "$path" ]]; then
    echo "Missing required path: $path" >&2
    exit 1
  fi
done

rm -f "$OUTPUT"
zip -qr "$OUTPUT" "${INCLUDES[@]}" -x "${EXCLUDES[@]}"

echo "$OUTPUT"
