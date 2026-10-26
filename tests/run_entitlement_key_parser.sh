#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/entitlement-keys.XXXXXX")
trap 'rm -rf "$temp_dir"' EXIT
swiftc -module-cache-path "$temp_dir/cache" SysExplorer/SysExplorer/EntitlementKeyParser.swift tests/EntitlementKeyParserTests.swift -o "$temp_dir/test"
"$temp_dir/test"
