#!/usr/bin/env bash
set -euo pipefail

PROJECT="CVee-resumebuilder.xcodeproj"
SCHEME="CVee-resumebuilder"
DEVICE_ID="${IOS_SIMULATOR_ID:-$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/{print $2; exit}')}"

if [[ -z "$DEVICE_ID" ]]; then
  echo "No available iPhone Simulator found." >&2
  exit 1
fi

echo "Testing on Simulator $DEVICE_ID"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath "$PWD/.derivedData" \
  -resultBundlePath "$PWD/TestResults.xcresult" \
  -enableCodeCoverage YES \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO \
  test
