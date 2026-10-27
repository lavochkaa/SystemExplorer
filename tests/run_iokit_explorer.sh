#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
binary=$(mktemp "${TMPDIR:-/tmp}/iokit-explorer-tests.XXXXXX")
trap 'rm -f "$binary"' EXIT

clang -fobjc-arc -Wall -Wextra -Werror -framework Foundation \
    "$root/SysExplorer/SysExplorer/Core/IOKitExplorer.m" \
    "$root/tests/IOKitExplorerTests.m" -o "$binary"
"$binary"
