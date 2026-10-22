#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
binary=$(mktemp "${TMPDIR:-/tmp}/macho-parser-tests.XXXXXX")
trap 'rm -f "$binary"' EXIT

clang++ -std=c++17 -fobjc-arc -Wall -Wextra -Werror -framework Foundation \
    "$root/SysExplorer/SysExplorer/Core/MachOParser.mm" \
    "$root/tests/MachOParserTests.mm" -o "$binary"
"$binary"
