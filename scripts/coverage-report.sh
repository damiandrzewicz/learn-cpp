#!/usr/bin/env bash
set -euo pipefail

# Generate an HTML coverage report from a coverage-enabled build.
# Requires either gcovr or lcov/genhtml to be installed in the container.

BUILD_DIR=${1:-build/Debug}
SOURCE_DIR=${2:-$(pwd)}
REPORT_DIR=${3:-${BUILD_DIR}/coverage}
VERBOSE_FLAGS=()
# Allow callers to extend/override gcovr flags
EXTRA_GCOVR_FLAGS=()
if [[ -n "${GCOVR_FLAGS:-}" ]]; then
  # naive split on spaces; for complex quoting, pass flags directly via environment
  read -r -a EXTRA_GCOVR_FLAGS <<< "${GCOVR_FLAGS}"
fi
if [[ "${COVERAGE_VERBOSE:-0}" == "1" ]]; then
  VERBOSE_FLAGS=("-v")
fi

mkdir -p "${REPORT_DIR}"

if command -v gcovr >/dev/null 2>&1; then
  echo "[coverage] Using gcovr"
  gcovr \
    "${VERBOSE_FLAGS[@]}" \
    --root "${SOURCE_DIR}" \
    --filter "${SOURCE_DIR}/apps" \
    --filter "${SOURCE_DIR}/src" \
    --filter "${SOURCE_DIR}/include" \
    --exclude "${SOURCE_DIR}/apps/.*/tests/.*" \
    --exclude "${SOURCE_DIR}/tests/.*" \
    --exclude "/usr/include/" \
    --exclude "/home/.*/\\.conan2/" \
    --exclude "${SOURCE_DIR}/\\.vscode/" \
    --exclude "${SOURCE_DIR}/\\.devcontainer/" \
    --exclude '.tests/.' \
  --gcov-ignore-errors no_working_dir_found \
  --gcov-ignore-errors source_not_found \
    --exclude-throw-branches \
    --exclude-unreachable-branches \
    --object-directory "${BUILD_DIR}" \
    --html-title "learn-cpp Coverage" \
    --html --html-details \
    --print-summary \
    --output "${REPORT_DIR}/index.html" \
    ${EXTRA_GCOVR_FLAGS[@]:-}
  echo "[coverage] Report: ${REPORT_DIR}/index.html"
  exit 0
fi

if command -v lcov >/dev/null 2>&1 && command -v genhtml >/dev/null 2>&1; then
  echo "[coverage] Using lcov/genhtml"
  pushd "${BUILD_DIR}" >/dev/null
  lcov --directory . --capture --output-file coverage.info
  # Optionally filter out third-party or test files here with --remove
  genhtml coverage.info --output-directory "${REPORT_DIR}"
  popd >/dev/null
  echo "[coverage] Report: ${REPORT_DIR}/index.html"
  exit 0
fi

echo "[coverage] Please install gcovr or lcov/genhtml." >&2
exit 1
