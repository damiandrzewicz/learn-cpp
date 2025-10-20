cmake_minimum_required(VERSION 3.27)
project(learn_cpp LANGUAGES CXX)

# Export compile_commands.json for tooling (clangd, linters, etc.)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

## C++ standard
# Prefer per-target features (see CppHelpers.cmake uses of cxx_std_23) to avoid
# conflicting with toolchains (e.g., Conan) and suppress override warnings.

# Warnings & ccache
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
  add_compile_options(-Wall -Wextra -Wpedantic -Wconversion)
endif()

find_program(CCACHE_PROGRAM ccache)
if (CCACHE_PROGRAM)
  set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
  set(CMAKE_C_COMPILER_LAUNCHER   "${CCACHE_PROGRAM}")
endif()

option(BUILD_TESTING "Enable tests" ON)
if(BUILD_TESTING)
  enable_testing()
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(CppHelpers)

add_subdirectory(apps)

