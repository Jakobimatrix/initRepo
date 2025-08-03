#!/bin/bash
# checkClangTidy.sh
# Runs clang-tidy on all C/C++ source files in the repo.
# Returns 0 if no warnings/errors, 1 otherwise.

set -e

# Find all staged and tracked C/C++ files (excluding submodules and build folders)
FILES=$(git ls-files '*.c' '*.cpp' ':!:build*' ':!:*/build*' ':!:_deps/*' ':!:*/_deps/*')

HAS_ISSUES=0

# Source environment variables
source "../.environment"
if [ -f "../../.environment" ]; then
    source "../../.environment"
fi

for file in $FILES; do
    # Only check files that have a corresponding compilation database entry
    if [ -f "compile_commands.json" ]; then
        clang-tidy-${CLANG_TIDY_VERSION} "$file" --quiet --warnings-as-errors='*' --export-fixes=tidy-fixes.yaml || HAS_ISSUES=1
    else
        echo "Warning: compile_commands.json not found. Skipping clang-tidy for $file."
        HAS_ISSUES=1
    fi
done

if [ $HAS_ISSUES -eq 0 ]; then
    echo "No clang-tidy issues found."
    exit 0
else
    echo "clang-tidy found issues. See output above."
    exit 1
fi
