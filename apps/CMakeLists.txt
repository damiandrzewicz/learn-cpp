# Helper function to define an app + (optional) test
function(add_mini_app OUT_VAR NAME)
  if("${NAME}" STREQUAL "AUTO")
    file(RELATIVE_PATH _rel "${CMAKE_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}")
    string(REGEX REPLACE "[^A-Za-z0-9_]" "_" NAME "${_rel}")
  endif()

  add_executable(${NAME} ${ARGN})
  target_compile_features(${NAME} PRIVATE cxx_std_23)
  add_test(NAME run_${NAME} COMMAND ${NAME})

  # hand the name back to caller
  set(${OUT_VAR} "${NAME}" PARENT_SCOPE)
endfunction()

# Register each app directory explicitly (clear & scalable)
add_subdirectory(001_hello)
add_subdirectory(002_moderndev_sources)