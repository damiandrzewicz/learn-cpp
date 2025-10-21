## Scripts and automation

This repo centralizes Conan/CMake/CTest logic into small reusable scripts to avoid duplication across local dev, Dev Container hooks, and CI workflows.

### Layout

- `scripts/setup-conan-presets.sh`
  - Detects Conan profile and installs dependencies for one or more build types (defaults to Debug and Release).
  - Generates Conan-driven CMakePresets (e.g., `conan-debug`, `conan-release`).

- `scripts/build-type.sh`
  - Configures, builds, and runs tests for a given build type using presets.
  - Honors optional `EXTRA_CMAKE_FLAGS` (e.g., `-DENABLE_COVERAGE=ON`).

- `scripts/ci-build.sh`
  - Thin wrapper for CI. Calls `setup-conan-presets.sh` for the requested build type, then `build-type.sh`.

- `scripts/ci-coverage.sh`
  - Thin wrapper for CI coverage. Prepares Debug presets, builds with `EXTRA_CMAKE_FLAGS=-DENABLE_COVERAGE=ON`, runs tests, and calls `scripts/coverage-report.sh`.

- `scripts/coverage-report.sh`
  - Generates HTML coverage via gcovr with tuned filters and exclusions. See inline flags for customization (tests/throw branches, etc.).

### Dev Container hooks

- `.devcontainer/scripts/post-create.sh`
  - Calls `setup-conan-presets.sh Debug Release` to prepare presets.
  - Builds both Debug and Release via `build-type.sh`.
  - Symlinks `compile_commands.json` for clangd convenience.

- `.devcontainer/scripts/post-start.sh`
  - Maintains ownership of the ccache volume.

There are two Dev Container configurations:

- `.devcontainer/devcontainer.json`: for local development. May include local HOME mounts (gitconfig/ssh) for convenience.
- `.devcontainer/ci/devcontainer.json`: for CI. No HOME mounts; otherwise identical tooling.

### CI Workflows

- `.github/workflows/ci.yml`
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
