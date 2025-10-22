## Scripts and automation

This repo centralizes Conan/CMake/CTest logic into small reusable scripts to avoid duplication across local dev, Dev Container hooks, and CI workflows.

### Layout

  - Detects Conan profile and installs dependencies for one or more build types (defaults to Debug and Release).
  - Generates Conan-driven CMakePresets (e.g., `conan-debug`, `conan-release`).
 `scripts/setup-conan-presets.sh`

- `scripts/build-type.sh`
  - Configures, builds, and runs tests for a given build type using presets.

- `scripts/ci-build.sh`
 `scripts/build.sh`
  - Thin wrapper for CI. Calls `setup-conan-presets.sh` for the requested build type, then `build-type.sh`.

- `scripts/ci-coverage.sh`

  - Generates HTML coverage via gcovr with tuned filters and exclusions. See inline flags for customization (tests/throw branches, etc.).
 `scripts/ci-build.sh` and `scripts/ci-coverage.sh`

### Dev Container hooks

  - Calls `setup-conan-presets.sh Debug Release` to prepare presets.
 ### CI Workflows
 `.github/workflows/build.yml`
  - Builds both Debug and Release via `build-type.sh`.
  - Symlinks `compile_commands.json` for clangd convenience.

 Single-type build:
  - `bash scripts/build.sh Debug`
  - `bash scripts/build.sh Release`
There are two Dev Container configurations:
- `.devcontainer/devcontainer.json`: for local development. May include local HOME mounts (gitconfig/ssh) for convenience.

 Coverage is enabled by default for the `debug` preset; `scripts/coverage-report.sh` defaults to `build/Debug`.
### CI Workflows
 Presets come from Conan’s CMake integration and `cmake_layout`. Build directories are `build/Debug` (coverage on) and `build/Release`.
  - Runs inside the CI Dev Container. Uses `scripts/ci-build.sh` for Debug and Release matrix builds.

- `.github/workflows/coverage.yml`
  - Runs inside the CI Dev Container. Uses `scripts/ci-coverage.sh` and uploads the HTML artifact.

### Usage

- Local full setup and build (inside Dev Container):
  - `bash scripts/setup-conan-presets.sh`  # Debug + Release
  - `bash scripts/build-type.sh Debug`
  - `bash scripts/build-type.sh Release`

- Single-type build:
  - `bash scripts/setup-conan-presets.sh Debug`
  - `bash scripts/build-type.sh Debug`

- Coverage run (locally):
  - `EXTRA_CMAKE_FLAGS=-DENABLE_COVERAGE=ON bash scripts/build-type.sh Debug`
  - `bash scripts/coverage-report.sh`

### Notes

- Presets come from Conan’s CMake integration and `cmake_layout`. Build directories are typically `build/Debug` and `build/Release`.
- To tweak coverage inclusions/exclusions (tests, throw/unreachable), adjust flags in `scripts/coverage-report.sh` or add environment toggles as needed.
