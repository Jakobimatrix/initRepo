#!/bin/bash
# checkFileHeader.sh
# Runs over all C/C++ source files in the repo and checks if they have a proper header.
# Returns 0 if no warnings/errors, 1 otherwise.

# a proper header looks like this:
# /**
#  * @file <MATCHES_NAME_OF_THE_FILE>
#  * @brief ...description, can have multiple lines...
#  *
#  * @date <dd.mm.jjjj>
#  * @author <Name of the maintainer>
#  * @version <VERSION NUMBER>
#  **/

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

# shellcheck source-path=SCRIPTDIR source=checkDoxygenHeader.sh
source ./initRepo/scripts/checkDoxygenHeader.sh


for file in $FILES; do
    echo "check \"$file\" for header."
    if ! checkDoxygenHeader "$file"; then
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
