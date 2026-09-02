#!/usr/bin/env bash
set -euo pipefail

PROJECT="CVee-resumebuilder.xcodeproj"
SCHEME="CVee-resumebuilder"
DEVICE_FAMILY="${IOS_DEVICE_FAMILY:-iPhone}"
DIAGNOSTICS_DIR="${CI_DIAGNOSTICS_DIR:-$PWD/ci-diagnostics}"
RESULT_BUNDLE="$PWD/TestResults-${DEVICE_FAMILY}.xcresult"

mkdir -p "$DIAGNOSTICS_DIR"
DESTINATIONS_FILE="$DIAGNOSTICS_DIR/destinations-${DEVICE_FAMILY}.txt"
if ! xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations >"$DESTINATIONS_FILE" 2>&1; then
  cat "$DESTINATIONS_FILE" >&2
  exit 70
fi

DESTINATION="${IOS_SIMULATOR_DESTINATION:-$(awk -v family="$DEVICE_FAMILY" '$0 ~ "platform:iOS Simulator" && $0 ~ "name:" family { match($0, /id:[^,}]*/); print "platform=iOS Simulator,id=" substr($0, RSTART + 3, RLENGTH - 3); exit }' "$DESTINATIONS_FILE")}"
if [[ -z "$DESTINATION" ]]; then
  echo "No compatible $DEVICE_FAMILY Simulator destination found." >&2
  cat "$DESTINATIONS_FILE" >&2
  exit 1
fi

COMMON_ARGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -destination "$DESTINATION"
  -destination-timeout 120
  -derivedDataPath "$PWD/.derivedData"
  -only-testing:CVee-resumebuilderUITests
  -parallel-testing-enabled NO
  CODE_SIGNING_ALLOWED=NO
)

echo "Building UI tests for $DESTINATION"
xcodebuild "${COMMON_ARGS[@]}" build-for-testing

echo "Running UI tests for $DESTINATION"
xcodebuild "${COMMON_ARGS[@]}" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -enableCodeCoverage YES \
  test-without-building
