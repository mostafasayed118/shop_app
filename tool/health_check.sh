#!/usr/bin/env bash
# One-shot health check for the e_commerce (Shoply) Flutter project.
#
# Verifies the three things CI would check:
#   1. flutter analyze             — no analyzer issues
#   2. flutter test                — full test suite green
#   3. flutter build apk --debug   — Android debug APK builds
#
# Usage:  bash tool/health_check.sh      (from anywhere; it cd's to the repo)
# Exit:   0 = all checks passed, 1 = at least one check failed.
# Logs:   each check writes a full log to /tmp/health_check_<name>.log; on
#         failure the tail is echoed so the cause is visible in one shot.

set -u # not -e: run every check and report all results

cd "$(dirname "$0")/.." || exit 1

pass=0
fail=0

run_check() {
  local name="$1"
  shift
  local log="/tmp/health_check_${name}.log"
  echo ""
  echo "==> [${name}]"
  if "$@" >"${log}" 2>&1; then
    echo "    PASS"
    pass=$((pass + 1))
  else
    echo "    FAIL — log: ${log} (tail below)"
    tail -5 "${log}"
    fail=$((fail + 1))
  fi
}

run_check "analyze" flutter analyze
run_check "test" flutter test
run_check "build-apk-debug" flutter build apk --debug

echo ""
echo "=============================="
echo "Health check: ${pass} passed, ${fail} failed"
echo "=============================="
[ "${fail}" -eq 0 ]
