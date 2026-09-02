#!/usr/bin/env bash
set -euo pipefail

PROJECT="CVee-resumebuilder.xcodeproj"
SCHEME="CVee-resumebuilder"
IOS_RUNTIME="${IOS_RUNTIME:-iOS-26-0}"
DEVICE_ID="${IOS_SIMULATOR_ID:-$(xcrun simctl list devices available --json | jq -r --arg runtime "$IOS_RUNTIME" '.devices | to_entries[] | select(.key | contains($runtime)) | .value[] | select(.name | startswith("iPhone")) | .udid' | head -n 1)}"

if [[ -z "$DEVICE_ID" ]]; then
  echo "No available iPhone Simulator for runtime $IOS_RUNTIME found." >&2
  xcrun simctl list runtimes >&2
  xcrun simctl list devices available >&2
  exit 1
fi

echo "Testing on Simulator $DEVICE_ID"
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE_ID" -b
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -destination-timeout 120 \
  -derivedDataPath "$PWD/.derivedData" \
  -resultBundlePath "$PWD/TestResults.xcresult" \
  -enableCodeCoverage YES \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO \
  test
