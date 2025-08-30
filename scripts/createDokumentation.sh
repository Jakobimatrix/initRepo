#!/bin/bash
# createDokumentation.sh
# Runs Doxygen to create a Dokumentation

set -e

# Ensure we are in the root repository folder 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "${REPO_ROOT}"


DOXYDIR="doxygen"
DOXYFILE="$DOXYDIR/Doxyfile"
DEPENDENCY_GRAPH_FILE="$DOXYDIR/dependency_tree.svg"
TEMPLATE="initRepo/templates/Doxyfile"

# Create folder if it doesn't exist
mkdir -p "$DOXYDIR"

# Copy template if Doxyfile doesn't exist
if [[ ! -f "$DOXYFILE" ]]; then
    echo "Doxyfile not found, copying template..."
    cp "$TEMPLATE" "$DOXYFILE"
fi
cd "$DOXYDIR"
doxygen "Doxyfile"

cmake --graphviz=graph . -DCMAKE_GRAPHVIZ_OPTIONS=initRepo/cmake/CMakeGraphVizOptions.cmake
dot graph -Tsvg -o DEPENDENCY_GRAPH_FILE