#!/usr/bin/env bash
set -euo pipefail

# Coverage build uses Debug + ENABLE_COVERAGE=ON
BUILD_TYPE="Debug"
CPPSTD="23"

conan --version || true
conan profile detect --force || conan profile detect || true
conan install . -s build_type="${BUILD_TYPE}" -s compiler.cppstd="${CPPSTD}" --build=missing

PRESET="conan-$(echo "${BUILD_TYPE}" | tr '[:upper:]' '[:lower:]')"

echo "[ci-coverage] Configure with preset: ${PRESET} (+ENABLE_COVERAGE=ON)"
cmake -DENABLE_COVERAGE=ON --preset "${PRESET}"

echo "[ci-coverage] Build with preset: ${PRESET}"
cmake --build --preset "${PRESET}" -j

echo "[ci-coverage] Run tests"
ctest --test-dir "build/${BUILD_TYPE}" --output-on-failure

# Generate coverage report
if [ -x scripts/coverage-report.sh ]; then
  scripts/coverage-report.sh
else
  bash scripts/coverage-report.sh
fi
