#!/bin/bash

set -e

show_help() {
    echo "Usage: ./build.sh [options]"
    echo "Options:"
    echo "  -c              Clean build"
    echo "  -d              Debug build"
    echo "  -r              Release build"
    echo "  -o              RelWithDebInfo build"
    echo "  -i              Install after build"
    echo "  --compiler COMP Use specific compiler (e.g. gcc, clang)"
    echo "  -h              Show this help message"
    echo "  -t              Enable tests"
    exit 0
}

# Defaults
CLEAN=false
INSTALL=false
BUILD_TYPE=""
COMPILER=""
ENABLE_TESTS=OFF
ARGS=()
COMPILER="gcc"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c) CLEAN=true ;;
        -d) BUILD_TYPE="Debug" ;;
        -r) BUILD_TYPE="Release" ;;
        -o) BUILD_TYPE="RelWithDebInfo" ;;
        -i) INSTALL=true ;;
        --compiler)
            shift
            COMPILER="$1"
            ;;
        -t) ENABLE_TESTS=ON ;;
        -h) show_help ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
    shift
done

# Validate build type
if [[ -z "$BUILD_TYPE" ]]; then
    echo "Error: You must specify a build type (-d, -r, or -o)"
    exit 1
fi


# Find full compiler path
COMPILER_PATH=$(command -v "$COMPILER")
if [[ -z "$COMPILER_PATH" ]]; then
    echo "Error: Compiler '$COMPILER' not found in PATH"
    exit 1
fi

# Normalize compiler name
if [[ "$COMPILER_PATH" =~ .*clang.* ]]; then
    COMPILER_NAME="clang"
elif [[ "$COMPILER_PATH" =~ .*g\+\+.* || "$COMPILER_PATH" =~ .*gcc.* ]]; then
    COMPILER_NAME="gcc"
else
    echo "Error: Unknown compiler '$COMPILER' or path not found."
    exit 1
fi

BUILD_DIR="build-${COMPILER_NAME,,}-${BUILD_TYPE,,}"

# Clean build directory if requested
if [[ "$CLEAN" == true ]]; then
    echo "Cleaning build directory: $BUILD_DIR"
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Run CMake and build
echo "Using compiler at: $COMPILER_PATH"
echo "Configuring with CMake..."
cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DCMAKE_CXX_COMPILER="$COMPILER_PATH" -DBUILD_TESTING="$ENABLE_TESTS" ..
echo "Building project..."
cmake --build . -- -j$(nproc)


# Run tests if enabled
if [[ "$ENABLE_TESTS" == "ON" ]]; then
    echo "Running tests..."
    ctest --output-on-failure
fi

# Install if requested
if [[ "$INSTALL" == true ]]; then
    echo "Installing project..."
    cmake --install .
fi
