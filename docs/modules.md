# Module pattern

This repo organizes code into small self-contained "modules" under `apps/.../<module>/`. Each module can define:
- a library (INTERFACE, STATIC, or SHARED)
- an optional console app
- optional unit tests

We use helper functions from `cmake/CppHelpers.cmake` to keep module CMake short and consistent.

## Directory layout

```
apps/
  002_moderndev_sources/
    001_adt/
      include/          # public headers (installed for consumers)
      src/              # private sources (for STATIC/SHARED)
      tests/            # unit tests
      CMakeLists.txt
```

## Minimal CMake

Header-only library + tests; optional app if `src/main.cpp` exists:

```
cpp_add_module(
  NAME AUTO
  LIB_TYPE INTERFACE
  PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include"
  APP
  TESTS
  TEST_SOURCES tests/my_test.cpp
)
```

Static library with sources + explicit app sources:

```
cpp_add_module(
  NAME my_algo
  LIB_TYPE STATIC
  LIB_SOURCES src/a.cpp src/b.cpp
  PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include"
  PRIVATE_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/src"
  APP
  APP_SOURCES src/main.cpp
  TESTS
  TEST_SOURCES tests/a_test.cpp tests/b_test.cpp
)
```

## Multiple libraries in a module

```
# base lib (header-only)
cpp_add_library(BASE_LIB NAME base_lib TYPE INTERFACE PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include")
# impl lib (compiled)
cpp_add_library(IMPL_LIB NAME impl_lib TYPE STATIC
  SOURCES src/impl.cpp
  PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include"
  PRIVATE_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/src"
  PRIVATE_DEPS ${BASE_LIB}
)
# tests
cpp_add_gtests(NAME impl_tests SOURCES tests/impl_test.cpp DEPS ${IMPL_LIB})
```

## Naming convention

- `NAME AUTO` derives a normalized base from the path and creates targets `<name>_lib`, `<name>_app`, `<name>_tests`.
- Or set `NAME` explicitly to fix target names.

## Tips

- Use per-target C++ standard via features (helpers default to `cxx_std_23`).
- `BUILD_TESTING=ON` to enable tests. The root CMake already wires this.
- For new modules, also add `add_subdirectory(<module>)` in the parent `apps/.../CMakeLists.txt`.

## Creating a new module quickly

Use the script `scripts/new-module.sh` to scaffold a module with the recommended structure and a starting `CMakeLists.txt`:

```
./scripts/new-module.sh apps/002_moderndev_sources 002_new_module --type INTERFACE --with-app --with-tests
```

Options:
- `--type INTERFACE|STATIC|SHARED`
- `--with-app` to include an example `src/main.cpp`
- `--with-tests` to include an example test file

After generation:
- `add_subdirectory(002_new_module)` to the parent `CMakeLists.txt`.
- Build with your preferred preset.
