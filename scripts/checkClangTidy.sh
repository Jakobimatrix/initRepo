#!/bin/bash
# checkClangTidy.sh
# Runs clang-tidy on all C/C++ source files in the repo.
# Returns 0 if no warnings/errors, 1 otherwise.

set -e

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


BUILD_TYPE="Debug"
BUILD_DIR=""

ORIGINAL_ARGS=("$@")
if [ ${#ORIGINAL_ARGS[@]} -eq 0 ]; then
    ORIGINAL_ARGS=(-d -t)
else
    # Otherwise, append -t
    ORIGINAL_ARGS+=(-t)
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -d) BUILD_TYPE="Debug" ;;
        --debug) BUILD_TYPE="Debug" ;;
        --o0debug) BUILD_TYPE="O0Debug" ;;
        --o1debug) BUILD_TYPE="O1Debug" ;;
        --o2debug) BUILD_TYPE="O2Debug" ;;
        --o3debug) BUILD_TYPE="O3Debug" ;;
        -r) BUILD_TYPE="Release" ;;
        --release) BUILD_TYPE="Release" ;;
        --releaseWithDebInfo) BUILD_TYPE="RelWithDebInfo" ;;
        --builddir)
            shift
            BUILD_DIR="$1"
            ;;
    esac
    shift
done

if [[ -z "$BUILD_DIR" ]]; then
    if [[ "$ENVIRONMENT" == "Linux" ]]; then
        # ${VAR,,} is a Bash operator that converts the value of VAR to lowercase.
        BUILD_DIR="build-clang-${CLANG_VERSION,,}-${BUILD_TYPE,,}-${ARCH,,}-${ARCH_BITS,,}"
    else
        BUILD_DIR="build-clang-${BUILD_TYPE,,}-${ARCH_BITS,,}"
    fi
fi


if [ ! -f "${BUILD_DIR}/compile_commands.json" ]; then
    ./initRepo/scripts/build.sh "${ORIGINAL_ARGS[@]}" --compiler clang
fi

if [ ! -f "${BUILD_DIR}/compile_commands.json" ]; then
    echo "Error ${BUILD_DIR}/compile_commands.json not found. CMake probably has failed."
    exit 1
fi

# Find all staged and tracked C/C++ files (excluding submodules and build folders)
FILES=$(git ls-files '*.c' '*.cpp' ':!:build*' ':!:*/build*' ':!:_deps/*' ':!:*/_deps/*')

HAS_ISSUES=0

for file in $FILES; do
    # Only check files that have a corresponding compilation database entry
    echo "clang-tidy-${CLANG_TIDY_VERSION} \"$file\" --quiet --warnings-as-errors='*' --export-fixes=tidy-fixes.yaml -p \"$BUILD_DIR\""
    clang-tidy-${CLANG_TIDY_VERSION} "$file" --quiet --warnings-as-errors='*' --export-fixes=tidy-fixes.yaml -p "$BUILD_DIR" || HAS_ISSUES=1
done

if [ $HAS_ISSUES -eq 0 ]; then
    echo "No clang-tidy issues found."
    exit 0
else
    echo "clang-tidy found issues. See output above."
    exit 1
fi
