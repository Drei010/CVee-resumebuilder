#!/usr/bin/env bash
set -euo pipefail

PROJECT="CVee-resumebuilder.xcodeproj"
SCHEME="CVee-resumebuilder"
DEVICE_FAMILY="${IOS_DEVICE_FAMILY:-iPhone}"
SHARD="${IOS_TEST_SHARD:-}"
WORKERS="${IOS_PARALLEL_WORKERS:-1}"
DIAGNOSTICS_DIR="${CI_DIAGNOSTICS_DIR:-$PWD/ci-diagnostics}"
RESULT_BUNDLE="$PWD/TestResults-${DEVICE_FAMILY}${SHARD:+-shard$SHARD}.xcresult"

# Shard 1 runs these UI test classes. Shard 2 runs everything else, unit tests included,
# so a new test class always runs somewhere.
SHARD_ONE_CLASSES=(TaskCaptureUITests TaskLibraryUITests TaskAIUITests SavedJobsUITests)

TEST_SELECTION=(-only-testing:CVee-resumebuilderUITests -only-testing:CVee-resumebuilderTests)
case "$SHARD" in
  "") ;;
  1)
    TEST_SELECTION=()
    for class in "${SHARD_ONE_CLASSES[@]}"; do TEST_SELECTION+=("-only-testing:CVee-resumebuilderUITests/$class"); done
    ;;
  2)
    for class in "${SHARD_ONE_CLASSES[@]}"; do TEST_SELECTION+=("-skip-testing:CVee-resumebuilderUITests/$class"); done
    ;;
  *)
    echo "IOS_TEST_SHARD must be 1, 2, or unset (all tests)." >&2
    exit 2
    ;;
esac

if [[ ! "$WORKERS" =~ ^[1-9][0-9]*$ ]]; then
  echo "IOS_PARALLEL_WORKERS must be a positive whole number." >&2
  exit 2
fi
if (( WORKERS > 1 )); then
  # xcodebuild runs test classes side by side on clones of the destination simulator.
  PARALLEL_ARGS=(-parallel-testing-enabled YES -parallel-testing-worker-count "$WORKERS")
else
  PARALLEL_ARGS=(-parallel-testing-enabled NO)
fi

mkdir -p "$DIAGNOSTICS_DIR"
DESTINATIONS_FILE="$DIAGNOSTICS_DIR/destinations-${DEVICE_FAMILY}.txt"
# On a fresh CI runner, CoreSimulator finds its simulator runtimes only once something asks for
# them, and until then xcodebuild lists just placeholder destinations. Ask simctl first, then give
# xcodebuild up to six tries, 15 seconds apart, to list a simulator of the requested family.
xcrun simctl list runtimes >"$DIAGNOSTICS_DIR/runtimes-${DEVICE_FAMILY}.txt" 2>&1 || true
for attempt in 1 2 3 4 5 6; do
  if ! xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations >"$DESTINATIONS_FILE" 2>&1; then
    cat "$DESTINATIONS_FILE" >&2
    exit 70
  fi
  if [[ -n "${IOS_SIMULATOR_DESTINATION:-}" ]] || grep -q "platform:iOS Simulator.*name:$DEVICE_FAMILY" "$DESTINATIONS_FILE"; then
    break
  fi
  if (( attempt < 6 )); then
    echo "No $DEVICE_FAMILY Simulator is listed yet (try $attempt of 6); waiting for CoreSimulator." >&2
    sleep 15
  fi
done

DESTINATION="${IOS_SIMULATOR_DESTINATION:-$(awk -v family="$DEVICE_FAMILY" '
  $0 ~ "platform:iOS Simulator" && $0 ~ "name:" family {
    match($0, /id:[^,}]*/)
    id = "platform=iOS Simulator,id=" substr($0, RSTART + 3, RLENGTH - 3)
    if (!fallback) fallback = id
    if ((family == "iPad" && $0 ~ /name:iPad \(A16\)/) || (family == "iPhone" && $0 ~ /name:iPhone 17 \}/)) preferred = id
  }
  END { print preferred ? preferred : fallback }
' "$DESTINATIONS_FILE")}"
if [[ -z "$DESTINATION" ]]; then
  echo "No compatible $DEVICE_FAMILY Simulator destination found." >&2
  cat "$DESTINATIONS_FILE" >&2
  # Show what CoreSimulator has, so the log tells a missing runtime from a missing device.
  xcrun simctl list runtimes >&2 || true
  xcrun simctl list devices available >&2 || true
  exit 1
fi

# A serial run uses the simulator itself, so boot it first. A parallel run uses clones that
# xcodebuild boots, so the original stays shut down and leaves its memory to them.
SIMULATOR_ID="${DESTINATION##*id=}"
if [[ "$SIMULATOR_ID" != "$DESTINATION" ]] && (( WORKERS == 1 )); then
  xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
  xcrun simctl bootstatus "$SIMULATOR_ID" -b
fi

COMMON_ARGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -destination "$DESTINATION"
  -destination-timeout 120
  -derivedDataPath "$PWD/.derivedData"
  CODE_SIGNING_ALLOWED=NO
)

echo "Building tests for $DESTINATION"
xcodebuild "${COMMON_ARGS[@]}" build-for-testing 2>&1 | tee "$DIAGNOSTICS_DIR/build.log"

echo "Running tests for $DESTINATION (shard: ${SHARD:-all}, workers: $WORKERS)"
rm -rf "$RESULT_BUNDLE"
# Keep going when tests fail, so the summary is still written and the log ends with each
# failure's message: in CI, the log is often the only place a failure can be read.
set +e
xcodebuild "${COMMON_ARGS[@]}" \
  "${TEST_SELECTION[@]}" \
  "${PARALLEL_ARGS[@]}" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -enableCodeCoverage YES \
  test-without-building 2>&1 | tee "$DIAGNOSTICS_DIR/test.log"
TEST_STATUS=${PIPESTATUS[0]}
set -e

if [[ -d "$RESULT_BUNDLE" ]]; then
  xcrun xcresulttool get test-results summary --path "$RESULT_BUNDLE" > "$DIAGNOSTICS_DIR/test-summary.json" || true
  python3 -I - "$DIAGNOSTICS_DIR/test-summary.json" <<'PY' || true
import json
import sys

try:
    summary = json.load(open(sys.argv[1]))
except (OSError, ValueError):
    sys.exit(0)
for failure in summary.get("testFailures", []):
    name = failure.get("testIdentifierString") or failure.get("testName") or "unknown test"
    print(f"Failure in {name}: {failure.get('failureText', '').strip()}")
PY
fi
exit "$TEST_STATUS"
