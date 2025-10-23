#!/usr/bin/env bash
set -euo pipefail

# lint.sh [--fix]
# Runs format and static analysis checks. By default, only checks without modifying files.
# Use --fix to apply clang-format changes.

FIX=0
if [[ "${1:-}" == "--fix" ]]; then
  FIX=1
fi

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

# Collect source files
mapfile -t CXX_FILES < <(git ls-files -- '*.cpp' '*.cc' '*.cxx' '*.c' '*.hpp' '*.hxx' '*.hh' '*.h' | sort)
mapfile -t CMAKE_FILES < <(git ls-files -- '*CMakeLists.txt' '*.cmake' | sort)

fail=0

has() { command -v "$1" >/dev/null 2>&1; }

# 1) clang-format
if has clang-format; then
  if (( FIX )); then
    echo "[lint] clang-format: fixing in-place"
    if ((${#CXX_FILES[@]})); then
      clang-format -style=file -i "${CXX_FILES[@]}"
    fi
  else
    echo "[lint] clang-format: checking"
    if ((${#CXX_FILES[@]})); then
      if ! clang-format -style=file --dry-run -Werror "${CXX_FILES[@]}"; then
        echo "[lint] clang-format reported issues" >&2
        fail=1
      fi
    fi
  fi
else
  echo "[lint] clang-format not found, skipping"
fi

# 2) clang-tidy
if has clang-tidy; then
  echo "[lint] clang-tidy: running (this may take a bit)"
  # Prefer compile_commands.json from build/Debug; fallback to root if present
  if [[ -f build/Debug/compile_commands.json ]]; then
    CCDB=build/Debug
  elif [[ -f compile_commands.json ]]; then
    CCDB=.
  else
    echo "[lint] No compile_commands.json found; run a Debug configure/build first" >&2
    fail=1
    CCDB=""
  fi
  if [[ -n "$CCDB" ]] && ((${#CXX_FILES[@]})); then
    # Limit parallelism to avoid OOM in CI
    if ! clang-tidy -p "$CCDB" -quiet -j $(nproc) "${CXX_FILES[@]}"; then
      echo "[lint] clang-tidy reported issues" >&2
      fail=1
    fi
  fi
else
  echo "[lint] clang-tidy not found, skipping"
fi

# 3) cppcheck
if has cppcheck; then
  echo "[lint] cppcheck: running"
  if ! cppcheck \
      --project=compile_commands.json \
      --enable=warning,performance,portability,style \
      --suppress=missingIncludeSystem \
      --error-exitcode=1 \
      --inline-suppr \
      --quiet; then
    echo "[lint] cppcheck reported issues" >&2
    fail=1
  fi
else
  echo "[lint] cppcheck not found, skipping"
fi

# 4) cmake-format
if has cmake-format; then
  if ((${#CMAKE_FILES[@]})); then
    echo "[lint] cmake-format: checking"
    if ! cmake-format --check "${CMAKE_FILES[@]}"; then
      echo "[lint] cmake-format reported issues" >&2
      fail=1
      if (( FIX )); then
        echo "[lint] cmake-format: fixing"
        cmake-format -i "${CMAKE_FILES[@]}" || true
      fi
    fi
  fi
else
  echo "[lint] cmake-format not found, skipping"
fi

# 5) codespell (typos)
if has codespell; then
  echo "[lint] codespell: checking"
  if ! codespell -q 3 -L crate,te,crate,nd -S build,compile_commands.json,.git; then
    echo "[lint] codespell reported issues" >&2
    fail=1
  fi
else
  echo "[lint] codespell not found, skipping"
fi

if (( fail )); then
  echo "[lint] failures detected" >&2
  exit 1
fi

echo "[lint] OK"
