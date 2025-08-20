#!/bin/bash
# checkShellCheck.sh
# Runs clang-tidy on all C/C++ source files in the repo.
# Returns 0 if no warnings/errors, 1 otherwise.

set -e

# Find all staged and tracked C/C++ files (excluding submodules and build folders)
FILES=$(git ls-files '*.sh' ':!:build*' ':!:*/build*' ':!:_deps/*' ':!:*/_deps/*')

HAS_ISSUES=0

# Ensure we are in the root repository folder 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "${REPO_ROOT}"

if ! command -v shellcheck >/dev/null 2>&1; then
    echo "shellCheck not installed on this system"
    exit 1
fi

for file in $FILES; do
    echo "shellcheck -x --exclude=SC1091 \"$file\""
    shellcheck -x --exclude=SC1091 "$file" || HAS_ISSUES=1
done

if [ $HAS_ISSUES -eq 0 ]; then
    echo "No shellcheck issues found."
    exit 0
else
    echo "shellcheck found issues in the bash scripts. See output above."
    exit 1
fi
