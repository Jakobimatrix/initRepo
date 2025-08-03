#!/bin/bash
# checkClangFormat.sh
# Checks all C/C++ source files in the repo for clang-format compliance.
# Returns 0 if all files are formatted, 1 otherwise.

set -e

# Find all staged and tracked C/C++ files (excluding submodules and build folders)
FILES=$(git ls-files '*.c' '*.cpp' '*.h' '*.hpp' ':!:build*' ':!:*/build*' ':!:_deps/*' ':!:*/_deps/*')

BAD_FILES=()

for file in $FILES; do
    if ! clang-format --dry-run --Werror "$file"; then
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
    exit 1
fi
