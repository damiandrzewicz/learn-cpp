#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <parent-apps-dir> <module-dir-name> [--type INTERFACE|STATIC|SHARED] [--with-app] [--with-tests]" >&2
  exit 1
fi

PARENT_DIR="$1"; shift
MODULE_DIR_NAME="$1"; shift
LIB_TYPE="INTERFACE"
WITH_APP=false
WITH_TESTS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      LIB_TYPE="$2"; shift 2;;
    --with-app)
      WITH_APP=true; shift;;
    --with-tests)
      WITH_TESTS=true; shift;;
    *)
      echo "Unknown option: $1" >&2
      exit 1;;
  esac
done

DEST_DIR="${PARENT_DIR}/${MODULE_DIR_NAME}"
if [[ -e "${DEST_DIR}" ]]; then
  echo "Destination exists: ${DEST_DIR}" >&2
  exit 1
fi

mkdir -p "${DEST_DIR}"

# Copy template and substitute LIB_TYPE
install -D -m 0644 templates/module/CMakeLists.txt "${DEST_DIR}/CMakeLists.txt"
sed -i "s|\${LIB_TYPE}|${LIB_TYPE}|g" "${DEST_DIR}/CMakeLists.txt"

# Always create include dir
mkdir -p "${DEST_DIR}/include"

if ${WITH_APP}; then
  install -D -m 0644 templates/module/src/main.cpp "${DEST_DIR}/src/main.cpp"
fi
if ${WITH_TESTS}; then
  install -D -m 0644 templates/module/tests/sample_test.cpp "${DEST_DIR}/tests/sample_test.cpp"
fi

# Attempt to add add_subdirectory to parent CMakeLists.txt if present
PARENT_CMAKELISTS="${PARENT_DIR}/CMakeLists.txt"
if [[ -f "${PARENT_CMAKELISTS}" ]]; then
  if ! grep -q "add_subdirectory(${MODULE_DIR_NAME})" "${PARENT_CMAKELISTS}"; then
    echo "add_subdirectory(${MODULE_DIR_NAME})" >> "${PARENT_CMAKELISTS}"
    echo "Updated ${PARENT_CMAKELISTS} with add_subdirectory(${MODULE_DIR_NAME})."
  fi
else
  echo "Note: create ${PARENT_CMAKELISTS} and add: add_subdirectory(${MODULE_DIR_NAME})" >&2
fi

echo "Module scaffolded at ${DEST_DIR}"
