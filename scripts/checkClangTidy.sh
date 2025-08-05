#!/bin/bash
# checkClangTidy.sh
# Runs clang-tidy on all C/C++ source files in the repo.
# Returns 0 if no warnings/errors, 1 otherwise.

set -e

# Find all staged and tracked C/C++ files (excluding submodules and build folders)
FILES=$(git ls-files '*.c' '*.cpp' ':!:build*' ':!:*/build*' ':!:_deps/*' ':!:*/_deps/*')

HAS_ISSUES=0

# Ensure we are in the root repository folder 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "${REPO_ROOT}"

# Source environment variables
# shellcheck source-path=../ 
source "initRepo/.environment"
if [ -f ".environment" ]; then
    source ".environment"
fi

# shellcheck source-path=SCRIPTDIR source=ensureToolVersion.sh
source ./initRepo/scripts/ensureToolVersion.sh
ensure_tool_versioned clang-tidy "${CLANG_TIDY_VERSION}"

# run CMake in debug environment with tests enabled and take the build directory
BUILD_INFO=$(./initRepo/scripts/build.sh -d -C -t --compiler clang)
# shellcheck disable=SC2181 # Reason: output goes into variable before I check if the command was successfull
if [ $? -ne 0 ]; then
    echo "Error: ./initRepo/scripts/build.sh -d -C -t --compiler clang ."
    echo "{$BUILD_INFO}"
    exit 1
fi
BUILD_DIR=$(echo "$BUILD_INFO" | grep '^BUILD_DIR=' | cut -d'=' -f2)

if [ ! -f "${BUILD_DIR}/compile_commands.json" ]; then
    echo "Warning: compile_commands.json not found. CMake probably has failed."
    exit 1
fi

for file in $FILES; do
    # Only check files that have a corresponding compilation database entry
    clang-tidy-${CLANG_TIDY_VERSION} "$file" --quiet --warnings-as-errors='*' --export-fixes=tidy-fixes.yaml -p "$BUILD_DIR" || HAS_ISSUES=1
done

if [ $HAS_ISSUES -eq 0 ]; then
    echo "No clang-tidy issues found."
    exit 0
else
    echo "clang-tidy found issues. See output above."
    exit 1
fi
