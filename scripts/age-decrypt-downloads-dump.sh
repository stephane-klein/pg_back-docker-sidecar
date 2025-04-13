#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

find tmp-downloads-dump/ -type f -name "*.age" -exec bash -c 'output="${0%.age}" && [ -f "$output" ] && rm "$output"; echo "AGE-SECRET-KEY-13MRMM74CQ2JA000HGZ86Y4SVLYS468W0YR4KPXHG7KSX5K5YSLESRCD37L" | age -d -i - -o "$output" "$0"' {} \;
