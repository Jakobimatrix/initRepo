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
cd $SCRIPT_DIR # repo/initRepo/scripts/:
cd ../../

# run CMake in debug environment with tests enabled and take the build directory
BUILD_INFO=$(./initRepo/scripts/build.sh -d -C -t)
BUILD_DIR=$(echo "$BUILD_INFO" | grep '^BUILD_DIR=' | cut -d'=' -f2)

if [ ! -f "compile_commands.json" ]; then
    echo "Warning: compile_commands.json not found. CMake probably has failed."
fi

# Source environment variables
source "initRepo/.environment"
if [ -f ".environment" ]; then
    source ".environment"
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
