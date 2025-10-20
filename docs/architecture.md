# learn-cpp: Architecture, Tooling, and Workflow Guide

This document is an in-depth, hands-on guide to the project structure, build and test workflow, and the tooling that makes day-to-day C++ development smooth and reproducible. It covers:

- Repository layout and what each file/folder is for
- CMake configuration (including presets) and reusable helpers
- Conan package management and toolchains
- Testing and coverage (CTest, GoogleTest, gcovr)
- Development environment (Dev Container, VS Code setup)
- Practical command examples for local use and CI readiness

> You can skip transient build artifacts. We focus on source-controlled files that define behavior.

---

## 1) Repository layout

At the root:

- `CMakeLists.txt`: Root CMake entrypoint. Declares options (testing, sanitizers, coverage), sets up include paths, and imports helper functions.
- `CMakePresets.json`: Project-owned build presets (Debug, Release, Coverage). Define consistent configure/build/test behavior for local and CI.
- `CMakeUserPresets.json`: Conan-generated presets (toolchains, cache paths). These are machine-specific and may be regenerated.
- `cmake/`: Custom CMake modules.
  - `CppHelpers.cmake`: Reusable functions/macros to create libraries, apps, tests, and apply flags (C++ standard, sanitizers, coverage).
- `apps/`: Source code organized by modules with optional app and tests.
  - `001_moderndev_sources/001_adt/`: Example module with headers in `include/`, a sample app in `src/`, and tests in `tests/`.
- `scripts/`: Developer scripts.
  - `new-module.sh`: Scaffolds a new module directory structure with boilerplate CMake, sources, and tests.
  - `coverage-report.sh`: Aggregates and renders coverage HTML using `gcovr` (or `lcov` fallback).
- `.devcontainer/`: Dev environment for VS Code Remote Containers.
  - `Dockerfile`, `devcontainer.json`, `scripts/`.
- `.vscode/`: Editor settings and tasks.
  - `settings.json`, `tasks.json`, `launch.json`, `extensions.json`.
- `conanfile.txt`: Declares dependencies (e.g., GoogleTest) for Conan.
- `docs/`: Documentation (this file and others).
- `templates/`: Scaffolding templates used by scripts.
- `build/`: Out-of-source build directory containing configure/build artifacts.
- `compile_commands.json`: Symlink or file exposing the compilation database for language servers (clangd).

Module example: `apps/001_moderndev_sources/001_adt/`

- `include/ds/`: Public headers (`IStack.hpp`, `StackArray.hpp`).
- `src/`: App sources (e.g., `main.cpp`) when `APP` is enabled.
- `tests/`: Unit tests (e.g., `tests/ds/StackArrayTest.cpp`).
- `CMakeLists.txt`: Uses helpers to create an INTERFACE lib + optional app and tests.

---

## 2) CMake configuration (root + helpers)

### Root CMakeLists.txt

Key responsibilities:

- Enable compilation database:
  - `set(CMAKE_EXPORT_COMPILE_COMMANDS ON)` → generates `compile_commands.json` in build dir.
- Testing toggle:
  - `option(BUILD_TESTING "Build tests" ON)`
  - `enable_testing()`
- Sanitizers and coverage toggles (for GCC/Clang):
  - `ENABLE_ASAN`, `ENABLE_UBSAN`, `ENABLE_TSAN`, `ENABLE_MSAN`, `ENABLE_COVERAGE` (all OFF by default).
- Include helpers:
  - `list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")`
  - `include(CppHelpers)`

The helpers apply per-target compile options (e.g., `cxx_std_23`), sanitizer flags, and coverage flags so we avoid global `CMAKE_CXX_STANDARD` conflicts with Conan.

### cmake/CppHelpers.cmake

Provides high-level convenience functions:

- `cpp_get_module_name(out_var)`: Derives a module name from the folder path.
- `cpp_add_library(NAME|AUTO ...)`: Adds a library target with modern CMake usage requirements.
- `cpp_add_app(NAME|AUTO SOURCES ...)`: Adds an executable with proper compile features/flags.
- `cpp_add_gtests(NAME|AUTO SOURCES ...)`: Adds a GoogleTest executable and registers tests with CTest.
- `cpp_add_module(...)`: One-call setup for a module:
  - Creates a library (INTERFACE by default; can be STATIC/SHARED with `LIB_SOURCES`).
  - Optionally creates an app (if `APP` and sources present), and tests (if `TESTS`).
  - Wires include paths and target linkages.

The helpers also:
- Apply `cxx_std_23` per target instead of a global standard.
- Respect sanitizer and coverage options for GCC/Clang by injecting the right compile/link flags.
- Register `gtest_discover_tests()` with CTest, assuming `BUILD_TESTING` is ON.

### Module CMakeLists

Example (`apps/001_moderndev_sources/001_adt/CMakeLists.txt`):

```cmake
cpp_add_module(
  NAME AUTO
  LIB_TYPE INTERFACE
  PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include"
  APP            # creates an app if src/main.cpp exists or if APP_SOURCES provided
  TESTS
  TEST_SOURCES tests/ds/StackArrayTest.cpp
)
```

- `NAME AUTO`: Derives the base name from the directory.
- `LIB_TYPE INTERFACE`: Header-only library.
- `PUBLIC_INCLUDE`: Exposes headers for consumers.
- `APP`: Will create an app if `src/main.cpp` exists (or supply `APP_SOURCES`).
- `TESTS` & `TEST_SOURCES`: Creates test binary and registers with CTest.

---

## 3) CMake presets

Presets encapsulate configure/build/test options in JSON. They’re consistent across machines and easy to invoke.

Common usage:

- Configure:
  - `cmake --preset Debug`
  - `cmake --preset Coverage`
- Build:
  - `cmake --build --preset Debug -j`
- Test:
  - `ctest --preset Debug --output-on-failure`

Typical project-owned presets (CMakePresets.json):

- `Debug`: Developer-focused build (no coverage); uses Conan toolchain for dependencies.
- `Release`: Optimized build.
- `Coverage`: Debug-like build with `-fprofile-arcs -ftest-coverage` (via `ENABLE_COVERAGE=ON`) and a dedicated build dir `build/Coverage`.

Why presets:
- No need to remember long cmake command lines.
- VS Code CMake Tools can read and present them in the UI.
- Great for CI and onboarding.

---

## 4) Conan (dependencies & toolchain)

- `conanfile.txt` declares dependencies, e.g.:

```ini
[requires]
gtest/1.14.0

[generators]
CMakeDeps
CMakeToolchain
```

- Install dependencies per build type (and C++ standard) so Conan generates a matching toolchain:

```bash
conan install . -s build_type=Debug -s compiler.cppstd=23 --build=missing
conan install . -s build_type=Release -s compiler.cppstd=23 --build=missing
```

This produces `build/<type>/generators/conan_toolchain.cmake` and dependency files for CMake.

- CMake configure then consumes the toolchain:

```bash
cmake --preset Debug    # Preset points to the Debug conan toolchain
cmake --build --preset Debug -j
```

- Benefits:
  - Consistent compilers/flags/paths.
  - Easy dependency upgrades.
  - Reproducible environments across machines.

---

## 5) Testing (CTest + GoogleTest)

- CTest is enabled via `BUILD_TESTING` and `enable_testing()` in the root CMake.
- GoogleTest comes from Conan and is linked to test targets in `cpp_add_gtests`.
- Tests are discovered using `gtest_discover_tests()` so you don’t have to manually enumerate cases.

Run tests:

```bash
ctest --preset Debug --output-on-failure
```

Example tests in `apps/001_moderndev_sources/001_adt/tests/ds/StackArrayTest.cpp` cover:
- Happy path push/pop
- Emplace and try_pop
- Overflow/underflow exceptions
- Lvalue and rvalue push semantics

---

## 6) Coverage (gcovr / lcov)

- Turn on instrumentation with the `Coverage` preset (`ENABLE_COVERAGE=ON`).
- Run tests to generate `.gcda` files.
- Use `scripts/coverage-report.sh` to render HTML (gcovr preferred):

```bash
# using Coverage preset
cmake --preset Coverage
cmake --build --preset Coverage -j
ctest --preset Coverage --output-on-failure

# render coverage
scripts/coverage-report.sh
```

The script:
- Sets `--root`, applies `--filter` to include project sources, and `--exclude` to ignore system/conan/test paths.
- Can be configured to exclude exception-only and unreachable branches to keep the branch metric actionable.
- Outputs HTML to `build/Coverage/coverage/index.html`.

Reading the report:
- `index.html` shows totals and a file list.
- `index.<file>.html` provides per-file line/function/branch details and which lines/branches are missing.

---

## 7) Dev Container (VS Code Remote Containers)

- `.devcontainer/Dockerfile`: Defines the base image and packages (gcc/clang, ninja, ccache, gcovr, etc.).
- `.devcontainer/devcontainer.json`: Configures extensions, mounts, and post-create hooks.
- Benefits:
  - Everyone gets the same toolchain and environment.
  - Works the same on Linux/Mac/Windows hosts.

Typical additions:
- Install `ninja-build` for faster builds.
- Create a Python venv for Conan.
- Post-create scripts to install Conan deps per build type and configure presets.

---

## 8) VS Code configuration

- `.vscode/settings.json`:
  - Prefer `clangd` as language server; configure `compileCommands` path.
  - CMake Tools: set generator, enable presets integration.
  - Format on save, consistent indentation, etc.

- `.vscode/tasks.json`:
  - Example task to run full coverage flow end-to-end.
  - Other useful tasks: configure/build/test by preset, clean builds, run clang-tidy (if used).

- `.vscode/launch.json`:
  - Debug configurations:
    - “Debug (pick app + preset)” → prompts for build preset and app binary.
    - “Debug (CMake selected target)” → uses CMake Tools’ selected target.

- `.vscode/extensions.json`:
  - Recommended extensions: CMake Tools, clangd, EditorConfig, etc.

---

## 9) Reusable scaffolding

- `scripts/new-module.sh`: Quickly create a new module following the pattern:
  - `include/` for public headers
  - `src/` for app/library sources
  - `tests/` for unit tests
  - `CMakeLists.txt` wired with `cpp_add_module`

Usage example:

```bash
scripts/new-module.sh apps/NNN_feature/001_widget --with-app --with-tests
```

This script will:
- Create directories and placeholder files.
- Append `add_subdirectory(...)` to the parent CMakeLists.
- Keep structure consistent across modules.

---

## 10) Example command sequences

Build and run tests (Debug):

```bash
conan install . -s build_type=Debug -s compiler.cppstd=23 --build=missing
cmake --preset Debug
cmake --build --preset Debug -j
ctest --preset Debug --output-on-failure
```

Coverage flow:

```bash
conan install . -s build_type=Debug -s compiler.cppstd=23 --build=missing
cmake --preset Coverage
cmake --build --preset Coverage -j
ctest --preset Coverage --output-on-failure
scripts/coverage-report.sh
$BROWSER build/Coverage/coverage/index.html
```

Debugging app/tests from VS Code:
- Choose “C++: Debug (pick app + preset)” and select the app or test and the desired preset.
- Or use “C++: Debug (CMake selected target)” and pick the target from the CMake status bar.

---

## 11) Design choices and tips

- Per-target C++ standard via `target_compile_features(... cxx_std_23)` avoids conflicts with Conan’s toolchain and is the modern CMake way.
- Presets keep config reproducible; don’t hard-code paths in scripts—use presets to guarantee consistency.
- Keep tests in module-local `tests/` so everything lives together; makes modules easy to move/copy.
- Exclude tests and exception-only/unreachable branches from coverage to keep branch coverage meaningful.
- Prefer Ninja for faster incremental builds; it’s supported by CMake Tools out of the box.

---

## 12) What to commit vs generate

- Commit: CMakeLists, presets, helpers, sources, tests, scripts, docs, VS Code settings.
- Generate (ignored): build directories, Conan caches, coverage HTML, compile_commands symlink at root.

---

## 13) Extending the setup

- Add clang-tidy with a preset and task (configure checks, header-filter, export fixes).
- Introduce sanitizers via `ENABLE_*` options for Debug presets.
- Add CI workflows that run: conan install → cmake configure (preset) → build → ctest → coverage-report.sh → upload artifact.
- Add more helpers to standardize warnings flags and treat-warnings-as-errors per target.

---

## 14) Troubleshooting

- “No tests were found!!!”: Ensure `enable_testing()` runs before adding subdirectories/tests.
- “Experimental/Nightly/Continuous targets clutter”: Don’t include `CTest`; use `BUILD_TESTING` + `enable_testing()`.
- “Generator mismatch (Unix Makefiles vs Ninja)”: Remove old build dirs and align presets and Conan toolchains.
- “Coverage shows unknown/none or too low”: Ensure tests run, verify `.gcda` files exist, tune `gcovr` filters, and optionally exclude tests/unreachable/throw branches.

---

With this guide, you should be able to recreate the structure, understand each moving part, and confidently extend the project with new modules, tests, and tooling.
