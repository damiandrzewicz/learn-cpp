## Scripts and automation

This repo centralizes Conan/CMake/CTest logic into a few reusable scripts and runs everything inside a Dev Container for local and CI consistency.

### Layout

- `scripts/setup-conan-presets.sh`
  - Detects Conan profile and installs dependencies for one or more build types (defaults to Debug and Release).
  - Generates Conan toolchains in `build/<type>/generators/` consumed by top-level CMake presets.

- `scripts/build.sh`
  - Shared entrypoint for local and CI usage. Accepts `Debug` (default) or `Release`.
  - Cleans the target build dir on CI to avoid CMake generator cache conflicts, ensures Conan toolchains are present, configures via top-level CMake presets (`debug`/`release`), builds, tests, and for `Debug` generates an HTML coverage report.

- `scripts/lint.sh`
  - Runs code quality checks:
    - clang-format (check mode by default; use `--fix` to format)
    - clang-tidy (uses compile_commands.json from `build/Debug` or root)
    - cppcheck (via compile_commands.json)
    - cmake-format (if installed)
    - codespell (if installed)
  - Skips tools that aren’t available; fails if any enabled tool reports issues.

- `scripts/coverage-report.sh`
  - Generates HTML coverage via gcovr with tuned filters. Defaults to `build/Debug` object directory.

### Dev Container hooks

- `.devcontainer/scripts/post-create.sh`
  - May prepare presets and build types; can be adapted as needed.

- `.devcontainer/scripts/post-start.sh`
  - Maintains ownership of the ccache volume.

There are two Dev Container configurations:

- `.devcontainer/devcontainer.json`: for local development.
- `.devcontainer/ci/devcontainer.json`: for CI, minimal mounts.

### CI Workflows

- `.github/workflows/build.yml`
  - Runs both Debug (with coverage) and Release using `scripts/build.sh` inside the Dev Container.

- `.github/workflows/lint.yml`
  - Runs linters inside the Dev Container and fails on findings.

### Usage

- Single-type build:
  - `bash scripts/build.sh Debug`
  - `bash scripts/build.sh Release`

- Lint locally:
  - `bash scripts/lint.sh`        # check only
  - `bash scripts/lint.sh --fix`  # apply clang-format and re-run checks

### Notes

- Presets come from Conan’s CMake integration and `cmake_layout`. Build directories are `build/Debug` (coverage on) and `build/Release`.
- Conan is configured to generate Ninja toolchains for consistency with presets.
