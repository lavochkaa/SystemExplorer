#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
binary=$(mktemp "${TMPDIR:-/tmp}/process-manager-tests.XXXXXX")
trap 'rm -f "$binary"' EXIT

clang -fobjc-arc -Wall -Wextra -Werror -framework Foundation \
    "$root/SysExplorer/SysExplorer/Core/ProcessManager.m" \
    "$root/tests/ProcessManagerTests.m" -o "$binary"
"$binary"
