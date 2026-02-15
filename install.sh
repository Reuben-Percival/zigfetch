#!/usr/bin/env sh
set -eu

PREFIX="${PREFIX:-/usr/local}"
BINDIR="$PREFIX/bin"
TARGET="$BINDIR/zigfetch"

if ! command -v zig >/dev/null 2>&1; then
    echo "error: zig is required but not found in PATH" >&2
    exit 1
fi

zig build -Doptimize=ReleaseSafe

mkdir -p "$BINDIR"
install -m 0755 zig-out/bin/zigfetch "$TARGET"

echo "Installed $TARGET"
