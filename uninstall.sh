#!/usr/bin/env sh
set -eu

PREFIX="${PREFIX:-/usr/local}"
TARGET="$PREFIX/bin/zigfetch"

if [ -f "$TARGET" ]; then
    rm -f "$TARGET"
    echo "Removed $TARGET"
else
    echo "No installed binary at $TARGET"
fi
