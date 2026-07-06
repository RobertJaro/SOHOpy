#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 OUTPUT_JSON [IDL_EXECUTABLE]" >&2
  exit 2
fi

OUTPUT_JSON="$1"
IDL_EXECUTABLE="${2:-idl}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${IDL_EXECUTABLE}" -quiet -e "run_lasco_parity, '${OUTPUT_JSON}'" \
  -IDL_PATH "+${SCRIPT_DIR}:${IDL_PATH:-<IDL_DEFAULT>}"
