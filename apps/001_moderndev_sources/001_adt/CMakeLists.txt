cpp_add_module(
  NAME AUTO
  LIB_TYPE INTERFACE
  PUBLIC_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include"
  # When switching to STATIC/SHARED, add sources here:
  # LIB_SOURCES src/foo.cpp src/bar.cpp
  APP            # creates an app if src/main.cpp exists or if APP_SOURCES provided
  # APP_SOURCES src/main.cpp   # optional explicit list
  TESTS
  TEST_SOURCES tests/ds/StackArrayTest.cpp
)
