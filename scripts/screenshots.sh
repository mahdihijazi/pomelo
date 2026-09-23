#!/bin/zsh
# Regenerates the README screenshots in docs/images.
set -e
cd "$(dirname "$0")/.."
OUT=docs/images
TMP=$(mktemp -d)
mkdir -p $OUT
swiftc -parse-as-library -D SNAPSHOT macos/Sources/Model.swift macos/Sources/Views.swift scripts/snapshot-mac.swift -o $TMP/snapshot-mac
$TMP/snapshot-mac $OUT -AppleLanguages "(en-US)" -AppleLocale en_US
swiftc scripts/snapshot-web.swift -o $TMP/snapshot-web
$TMP/snapshot-web $OUT -AppleLanguages "(en-US)" -AppleLocale en_US
rm -rf $TMP
