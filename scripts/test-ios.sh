#!/usr/bin/env bash
set -euo pipefail

PROJECT="CVee-resumebuilder.xcodeproj"
SCHEME="CVee-resumebuilder"
DESTINATION="${IOS_SIMULATOR_DESTINATION:-$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null | awk '/platform:iOS Simulator/ && (/name:iPhone/ || /name:iPad/) { match($0, /id:[^,}]*/); print "platform=iOS Simulator,id=" substr($0, RSTART + 3, RLENGTH - 3); exit }')}"

if [[ -z "$DESTINATION" ]]; then
  echo "No available iPhone or iPad Simulator destination found." >&2
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations >&2
  exit 1
fi

echo "Testing on $DESTINATION"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -destination-timeout 120 \
  -derivedDataPath "$PWD/.derivedData" \
  -resultBundlePath "$PWD/TestResults.xcresult" \
  -enableCodeCoverage YES \
  -parallel-testing-enabled NO \
  -only-testing:CVee-resumebuilderUITests \
  CODE_SIGNING_ALLOWED=NO \
  test
