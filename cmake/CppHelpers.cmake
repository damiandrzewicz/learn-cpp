###################################################################################################
# CppHelpers.cmake — Reusable helpers for libraries, apps, and tests
#
# How to use
# - In your top-level CMakeLists.txt add:
#     list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
#     include(CppHelpers)
# - In a module directory (e.g. apps/002_moderndev_sources/001_adt), call the helpers below.
#
# Quick start examples
# 1) Header-only library with tests, optional console app if src/main.cpp exists
#     cpp_add_module(
#       NAME AUTO
#       LIB_TYPE INTERFACE
#       PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include"
#       APP
#       TESTS
#       TEST_SOURCES tests/foo_test.cpp
#     )
#
# 2) Static library with sources, explicit app sources
#     cpp_add_module(
#       NAME my_algo
#       LIB_TYPE STATIC
#       LIB_SOURCES src/a.cpp src/b.cpp
#       PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include"
#       PRIVATE_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/src"
#       APP
#       APP_SOURCES src/main.cpp
#       TESTS
#       TEST_SOURCES tests/a_test.cpp tests/b_test.cpp
#     )
#
# 3) Multiple libraries in one module directory
#     # base lib (header-only)
#     cpp_add_library(BASE_LIB NAME base_lib TYPE INTERFACE PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include")
#     # impl lib (links private to base, provides compiled sources)
#     cpp_add_library(IMPL_LIB NAME impl_lib TYPE STATIC
#       SOURCES src/impl.cpp
#       PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include"
#       PRIVATE_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/src"
#       PRIVATE_DEPS ${BASE_LIB}
#     )
#     # optional tests
#     cpp_add_gtests(NAME impl_tests SOURCES tests/impl_test.cpp DEPS ${IMPL_LIB})
#
# Naming convention
# - NAME AUTO derives a normalized base name from the relative path of the directory and appends
#   suffixes: _lib, _app, _tests. You can override with NAME <custom>.
#
# Requirements & notes
# - Tests: include(CTest) must be called in the root CMake before add_subdirectory() so BUILD_TESTING
#   is defined when subprojects are processed. This repo’s root CMake does that already.
# - GoogleTest: cpp_add_gtests/find_package(GTest CONFIG REQUIRED) assumes GTest is provided by your
#   package manager or via a superbuild/FetchContent in your project.
# - C++ standard: helpers request cxx_std_23. Adjust as needed in your project if you want a lower
#   standard (change target_compile_features calls or pass COMPILE_FEATURES explicitly to libs).
# - Flexibility: compose multiple calls — you can mix INTERFACE/STATIC/SHARED libraries, wire deps via
#   PUBLIC_DEPS/PRIVATE_DEPS, and create multiple test targets per module if desired.
#
# Reference: Functions provided by this module
# - cpp_get_module_name(out_var)
# - cpp_add_library(out_target_var NAME <name|AUTO> TYPE <INTERFACE|STATIC|SHARED>
#       [SOURCES ...] [PUBLIC_INCLUDE dir] [PRIVATE_INCLUDE dir]
#       [PUBLIC_DEPS ...] [PRIVATE_DEPS ...] [COMPILE_FEATURES ...])
# - cpp_add_app(out_target_var [NAME <name|AUTO>] [SOURCES ...] [DEPS ...])
# - cpp_add_gtests([NAME <name>] SOURCES ... [DEPS ...])
# - cpp_add_module(NAME <name|AUTO> LIB_TYPE <INTERFACE|STATIC|SHARED>
#       [LIB_SOURCES ...] [PUBLIC_INCLUDE dir] [PRIVATE_INCLUDE dir]
#       [PUBLIC_DEPS ...] [PRIVATE_DEPS ...]
#       [APP [APP_SOURCES ...]]
#       [TESTS [TEST_SOURCES ...]])
#
# Troubleshooting
# - "No tests were found": ensure include(CTest) runs before add_subdirectory() of your modules and
#   BUILD_TESTING is ON (default). Then ensure cpp_add_gtests/TESTS is used.
# - Link errors with GTest: verify find_package(GTest CONFIG REQUIRED) can locate the package.
# - INTERFACE libraries have no sources; if you need compiled code, switch to STATIC/SHARED and add
#   LIB_SOURCES or use cpp_add_library with TYPE STATIC/SHARED.
###################################################################################################

# Derive a normalized module name from the current source dir relative to the source tree
function(cpp_get_module_name out_var)
  file(RELATIVE_PATH _rel "${CMAKE_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}")
  string(REGEX REPLACE "[^A-Za-z0-9_]" "_" _name "${_rel}")
  set(${out_var} "${_name}" PARENT_SCOPE)
endfunction()

# Create a library with flexible type and include dirs
# cpp_add_library(<out_target_var> NAME <name>|AUTO TYPE <INTERFACE|STATIC|SHARED> SOURCES <...> PUBLIC_INCLUDE <dir> [PRIVATE_INCLUDE <dir>...])
function(cpp_add_library out_target_var)
  #
  # Create a CMake library target with flexible type and wiring.
  #
  # Arguments
  # - NAME <name|AUTO>        Target name; AUTO => "<dir-derived>_lib"
  # - TYPE <INTERFACE|STATIC|SHARED>
  # - SOURCES <...>           .cpp/.c files for STATIC/SHARED. Ignored for INTERFACE.
  # - PUBLIC_INCLUDE <dir>    Public include directory for consumers (uses generator expressions
  #                           for build/install interfaces)
  # - PRIVATE_INCLUDE <dir>   Private include directory (only for STATIC/SHARED)
  # - PUBLIC_DEPS <...>       Link libraries propagated to consumers
  # - PRIVATE_DEPS <...>      Link libraries used privately by this target
  # - COMPILE_FEATURES <...>  e.g., cxx_std_23
  #
  # Output
  # - Sets <out_target_var> to the target name created
  #
  set(options)
  set(oneValueArgs NAME TYPE PUBLIC_INCLUDE)
  set(multiValueArgs SOURCES PRIVATE_INCLUDE PUBLIC_DEPS PRIVATE_DEPS COMPILE_FEATURES)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT ARG_NAME)
    cpp_get_module_name(_mod)
    set(ARG_NAME "${_mod}_lib")
  elseif(ARG_NAME STREQUAL "AUTO")
    cpp_get_module_name(_mod)
    set(ARG_NAME "${_mod}_lib")
  endif()

  if(NOT ARG_TYPE)
    set(ARG_TYPE INTERFACE)
  endif()

  if(ARG_TYPE STREQUAL INTERFACE)
    add_library(${ARG_NAME} INTERFACE)
  elseif(ARG_TYPE STREQUAL STATIC)
    add_library(${ARG_NAME} STATIC ${ARG_SOURCES})
  elseif(ARG_TYPE STREQUAL SHARED)
    add_library(${ARG_NAME} SHARED ${ARG_SOURCES})
  else()
    message(FATAL_ERROR "Unknown library TYPE: ${ARG_TYPE}")
  endif()

  # includes
  if(ARG_PUBLIC_INCLUDE)
    target_include_directories(${ARG_NAME}
      INTERFACE $<BUILD_INTERFACE:${ARG_PUBLIC_INCLUDE}>
                $<INSTALL_INTERFACE:include>
    )
  endif()
  if(ARG_PRIVATE_INCLUDE AND NOT ARG_TYPE STREQUAL INTERFACE)
    target_include_directories(${ARG_NAME}
      PRIVATE ${ARG_PRIVATE_INCLUDE}
    )
  endif()

  # dependencies
  if(ARG_PUBLIC_DEPS)
    target_link_libraries(${ARG_NAME} INTERFACE ${ARG_PUBLIC_DEPS})
  endif()
  if(ARG_PRIVATE_DEPS AND NOT ARG_TYPE STREQUAL INTERFACE)
    target_link_libraries(${ARG_NAME} PRIVATE ${ARG_PRIVATE_DEPS})
  endif()

  # features
  if(ARG_COMPILE_FEATURES)
    if(ARG_TYPE STREQUAL INTERFACE)
      target_compile_features(${ARG_NAME} INTERFACE ${ARG_COMPILE_FEATURES})
    else()
      target_compile_features(${ARG_NAME} PRIVATE ${ARG_COMPILE_FEATURES})
    endif()
  endif()

  set(${out_target_var} ${ARG_NAME} PARENT_SCOPE)
endfunction()

# Add a simple console app if main.cpp exists or a list is given
# cpp_add_app(<out_target_var> [NAME <name>|AUTO] [SOURCES <...>])
function(cpp_add_app out_target_var)
  #
  # Create a simple console application.
  #
  # Arguments
  # - NAME <name|AUTO>        Target name; AUTO => "<dir-derived>_app"
  # - SOURCES <...>           Sources for the app; if omitted and src/main.cpp exists, it is used.
  # - DEPS <...>              Libraries to link to (e.g., your module’s _lib)
  #
  # Output
  # - Sets <out_target_var> to the target name, or an empty string if no sources resolved
  #
  set(options)
  set(oneValueArgs NAME)
  set(multiValueArgs SOURCES DEPS)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT ARG_NAME OR ARG_NAME STREQUAL "AUTO")
    cpp_get_module_name(_mod)
    set(ARG_NAME "${_mod}_app")
  endif()

  set(_sources ${ARG_SOURCES})
  if(NOT _sources)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp")
      list(APPEND _sources src/main.cpp)
    endif()
  endif()

  if(_sources)
    add_executable(${ARG_NAME} ${_sources})
    target_compile_features(${ARG_NAME} PRIVATE cxx_std_23)
    # Apply sanitizers/coverage if requested (gcc/clang)
    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
      set(_san_flags "")
      if(ENABLE_ASAN)
        list(APPEND _san_flags "-fsanitize=address")
      endif()
      if(ENABLE_UBSAN)
        list(APPEND _san_flags "-fsanitize=undefined")
      endif()
      if(ENABLE_TSAN)
        list(APPEND _san_flags "-fsanitize=thread")
      endif()
      if(ENABLE_MSAN AND CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        list(APPEND _san_flags "-fsanitize=memory")
      endif()
      if(_san_flags)
        target_compile_options(${ARG_NAME} PRIVATE ${_san_flags})
        target_link_options(${ARG_NAME} PRIVATE ${_san_flags})
      endif()
      if(ENABLE_COVERAGE)
        target_compile_options(${ARG_NAME} PRIVATE --coverage)
        target_link_options(${ARG_NAME} PRIVATE --coverage)
      endif()
    endif()
    if(ARG_DEPS)
      target_link_libraries(${ARG_NAME} PRIVATE ${ARG_DEPS})
    endif()
    set(${out_target_var} ${ARG_NAME} PARENT_SCOPE)
  else()
    set(${out_target_var} "" PARENT_SCOPE)
  endif()
endfunction()

# Register Google Tests for a target; discovers tests
# cpp_add_gtests(TARGET <test_exe_name> SOURCES <...> DEPS <...>)
function(cpp_add_gtests)
  #
  # Create a GoogleTest executable and register tests with CTest via discovery.
  #
  # Arguments
  # - NAME <name>             Test target name; default => "<dir-derived>_tests"
  # - SOURCES <...>           Test source files containing TEST()/TEST_F() cases
  # - DEPS <...>              Libraries to link to (your module libs, other deps)
  #
  # Notes
  # - Requires: include(CTest) at root and GTest available (find_package(GTest CONFIG REQUIRED)).
  # - Uses gtest_discover_tests with PRE_TEST discovery mode.
  #
  set(options)
  set(oneValueArgs TARGET NAME)
  set(multiValueArgs SOURCES DEPS)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT BUILD_TESTING)
    return()
  endif()

  find_package(GTest CONFIG REQUIRED)

  if(NOT ARG_NAME)
    cpp_get_module_name(_mod)
    set(ARG_NAME "${_mod}_tests")
  endif()

  add_executable(${ARG_NAME} ${ARG_SOURCES})
  target_link_libraries(${ARG_NAME} PRIVATE ${ARG_DEPS} GTest::gtest GTest::gtest_main)
  # Apply sanitizers/coverage to tests as well
  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    set(_san_flags "")
    if(ENABLE_ASAN)
      list(APPEND _san_flags "-fsanitize=address")
    endif()
    if(ENABLE_UBSAN)
      list(APPEND _san_flags "-fsanitize=undefined")
    endif()
    if(ENABLE_TSAN)
      list(APPEND _san_flags "-fsanitize=thread")
    endif()
    if(ENABLE_MSAN AND CMAKE_CXX_COMPILER_ID MATCHES "Clang")
      list(APPEND _san_flags "-fsanitize=memory")
    endif()
    if(_san_flags)
      target_compile_options(${ARG_NAME} PRIVATE ${_san_flags})
      target_link_options(${ARG_NAME} PRIVATE ${_san_flags})
    endif()
    if(ENABLE_COVERAGE)
      target_compile_options(${ARG_NAME} PRIVATE --coverage)
      target_link_options(${ARG_NAME} PRIVATE --coverage)
    endif()
  endif()

  include(GoogleTest)
  gtest_discover_tests(${ARG_NAME}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    DISCOVERY_MODE PRE_TEST
  )
endfunction()

# Convenience: add module with library (+optional app + tests)
# cpp_add_module(NAME AUTO|<name> LIB_TYPE <INTERFACE|STATIC|SHARED> LIB_SOURCES <...>
#                PUBLIC_INCLUDE <dir> [PRIVATE_INCLUDE <dir>]
#                APP [APP_SOURCES <...>]
#                TESTS [TEST_SOURCES <...>])
function(cpp_add_module)
  #
  # Convenience wrapper to create a module consisting of a library and optional app/tests.
  #
  # Arguments
  # - NAME <name|AUTO>        Base name for targets: <name>_lib, <name>_app, <name>_tests
  # - LIB_TYPE <INTERFACE|STATIC|SHARED>
  # - LIB_SOURCES <...>       Sources for non-INTERFACE libs
  # - PUBLIC_INCLUDE <dir>    Public include dir (typically <module>/include)
  # - PRIVATE_INCLUDE <dir>   Private include dir (e.g., <module>/src)
  # - PUBLIC_DEPS <...>       Public link deps
  # - PRIVATE_DEPS <...>      Private link deps
  # - APP [APP_SOURCES ...]   Create an app target; if APP_SOURCES omitted, uses src/main.cpp if present
  # - TESTS [TEST_SOURCES ...]Create test target and discover tests
  #
  # Examples
  #   cpp_add_module(NAME AUTO LIB_TYPE INTERFACE PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include" APP TESTS TEST_SOURCES tests/x.cpp)
  #   cpp_add_module(NAME my_mod LIB_TYPE STATIC LIB_SOURCES src/a.cpp PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include" PRIVATE_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/src" TESTS TEST_SOURCES tests/a_test.cpp)
  #
  set(options APP TESTS)
  set(oneValueArgs NAME LIB_TYPE PUBLIC_INCLUDE PRIVATE_INCLUDE)
  set(multiValueArgs LIB_SOURCES APP_SOURCES TEST_SOURCES PUBLIC_DEPS PRIVATE_DEPS)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT ARG_NAME OR ARG_NAME STREQUAL "AUTO")
    cpp_get_module_name(_mod)
    set(ARG_NAME "${_mod}")
  endif()

  # Library
  cpp_add_library(_lib
    NAME "${ARG_NAME}_lib"
    TYPE ${ARG_LIB_TYPE}
    SOURCES ${ARG_LIB_SOURCES}
    PUBLIC_INCLUDE ${ARG_PUBLIC_INCLUDE}
    PRIVATE_INCLUDE ${ARG_PRIVATE_INCLUDE}
    PUBLIC_DEPS ${ARG_PUBLIC_DEPS}
    PRIVATE_DEPS ${ARG_PRIVATE_DEPS}
    COMPILE_FEATURES cxx_std_23
  )

  # App (optional)
  if(ARG_APP)
    cpp_add_app(_app NAME "${ARG_NAME}_app" SOURCES ${ARG_APP_SOURCES} DEPS ${_lib})
  endif()

  # Tests (optional)
  if(ARG_TESTS)
    cpp_add_gtests(NAME "${ARG_NAME}_tests" SOURCES ${ARG_TEST_SOURCES} DEPS ${_lib})
  endif()
endfunction()
