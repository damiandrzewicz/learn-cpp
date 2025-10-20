# Template CMakeLists for a new module
# Variables substituted by script:
#   MODULE_NAME_BASE  - directory name used in add_subdirectory
#   LIB_TYPE          - INTERFACE|STATIC|SHARED

cpp_add_module(
  NAME AUTO
  LIB_TYPE ${LIB_TYPE}
  PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include"
  APP
  TESTS
  TEST_SOURCES tests/sample_test.cpp
)
