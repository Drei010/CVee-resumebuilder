#!/bin/bash
# Cloud sessions run on Linux, so Xcode builds and simulator tests are not
# possible there. This hook installs the one CI check that does run on Linux:
# SwiftLint, pinned and checksum-verified, matching the iOS Tests workflow's
# `swiftlint lint --config .swiftlint.yml --strict` step.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}"

SWIFTLINT_VERSION=0.65.1
SWIFTLINT_SHA256=caeed6f4a679c35539ffaf124f6c4ab4a8416917f7d8796279dc52b74026059d
TOOLS_DIR="$PWD/.tools"

# Reinstall only when this script (and so the pinned version) has changed
hashes="$TOOLS_DIR/.session-start.sha256"
if ! sha256sum --check --status "$hashes" 2>/dev/null; then
  rm -rf "$TOOLS_DIR"
  mkdir -p "$TOOLS_DIR/bin"
  zip="$TOOLS_DIR/swiftlint.zip"
  curl -fsSL -o "$zip" \
    "https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/swiftlint_linux_amd64.zip"
  echo "${SWIFTLINT_SHA256}  ${zip}" | sha256sum --check --status
  # The static build needs no Swift runtime on the machine
  unzip -o -q -j "$zip" swiftlint-static -d "$TOOLS_DIR/bin"
  mv "$TOOLS_DIR/bin/swiftlint-static" "$TOOLS_DIR/bin/swiftlint"
  chmod +x "$TOOLS_DIR/bin/swiftlint"
  rm -f "$zip"
  sha256sum .claude/hooks/session-start.sh > "$hashes"
fi

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$TOOLS_DIR/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi
