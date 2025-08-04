#!/bin/bash
# checkClangFormat.sh
# Checks all C/C++ source files in the repo for clang-format compliance.
# Returns 0 if all files are formatted, 1 otherwise.

set -e

# Find all staged and tracked C/C++ files (excluding submodules and build folders)
FILES=$(git ls-files '*.c' '*.cpp' '*.h' '*.hpp' ':!:build*' ':!:*/build*' ':!:_deps/*' ':!:*/_deps/*')

BAD_FILES=()

# Ensure we are in the root repository folder 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $SCRIPT_DIR # repo/initRepo/scripts/:
cd ../../

# Source environment variables
source "initRepo/.environment"
if [ -f ".environment" ]; then
    source ".environment"
fi

source ./initRepo/scripts/ensureToolVersion.sh
ensure_tool_versioned clang-format "${CLANG_FORMAT_VERSION}"

for file in $FILES; do
    if ! clang-format-${CLANG_FORMAT_VERSION} -style=file --dry-run --Werror "$file"; then
        BAD_FILES+=("$file")
    fi
done

if [ ${#BAD_FILES[@]} -eq 0 ]; then
    echo "All files are properly formatted."
    exit 0
else
    echo "The following files are not properly formatted:"
    for f in "${BAD_FILES[@]}"; do
        echo "$f"
    done
    echo "You can format them by running:\n"
    echo "clang-format-${CLANG_FORMAT_VERSION} -style=file -i ${BAD_FILES[@]}"
    exit 1
fi
