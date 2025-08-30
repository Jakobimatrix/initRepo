#!/bin/bash
# checkFileHeader.sh
# Runs over all C/C++ source files in the repo and checks if they have a proper Doxygen header.
# Returns 0 if no warnings/errors, 1 otherwise.


set -e

if ! command -v shellcheck >/dev/null 2>&1; then
    echo "shellCheck not installed on this system"
    exit 1
fi


# Ensure we are in the root repository folder 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "${REPO_ROOT}"


# Find all staged and tracked C/C++ files (excluding submodules and build folders)
FILES=$(git ls-files '*.c' '*.cpp' '*.h' '*.hpp' ':!:build*' ':!:*/build*' ':!:_deps/*' ':!:*/_deps/*')

BAD_FILES=()


for file in $FILES; do
    echo "run ./initRepo/scripts/checkDoxygenHeader.sh \"$file\""
    if ! initRepo/scripts/checkDoxygenHeader.sh "$file"; then
        BAD_FILES+=("$file")
    fi
done

if [ ${#BAD_FILES[@]} -eq 0 ]; then
    echo "All files have a proper header."
    exit 0
else
    echo "The following files do not have a proper header:"
    for f in "${BAD_FILES[@]}"; do
        echo "$f"
    done
    echo "If you disagree, then run './initRepo/scripts/checkDoxygenHeader.sh path/to/file --verbose' to see why the file was flagged."
    exit 1
fi
