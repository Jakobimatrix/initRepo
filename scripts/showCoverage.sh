#!/bin/bash
# showCoverage.sh
# Runs gcc tests in debug mode and prints the coverage

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

if ! command -v gcovr >/dev/null 2>&1; then
    echo "You need to install gcc code coverage reporter: 'apt-get install -y gcovr lcov'"
    exit
fi

./initRepo/scripts/build.sh -d -g -t -T --compiler gcc

gcovr -r . --txt > coverage.txt
less coverage.txt
