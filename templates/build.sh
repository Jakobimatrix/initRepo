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
    echo "  -f              Enable fuzzing"
    exit 0
}

# Defaults
CLEAN=false
INSTALL=false
BUILD_TYPE=""
COMPILER=""
ENABLE_TESTS=OFF
ENABLE_FUZZING=OFF
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
        -f) ENABLE_FUZZING=ON ;;
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
    show_help
    exit 1
fi

# Normalize to correct C++ compiler
if [[ "$COMPILER" == "gcc" ]]; then
    COMPILER="g++"
elif [[ "$COMPILER" == "clang" ]]; then
    COMPILER="clang++"
fi

# Validate fuzzer option
if [[ "$ENABLE_FUZZING" == "ON" && "$COMPILER" != "clang++" ]]; then
    echo "Error: Fuzzing (-f) is only supported with the clang compiler."
    exit 1
fi

find_compiler() {
    local base=$1
    local fallback

    # Try unversioned first
    fallback=$(command -v "$base" 2>/dev/null)
    if [[ -n "$fallback" ]]; then
        echo "$fallback"
        return
    fi

    # Try to find highest versioned binary
    fallback=$(compgen -c | grep -E "^${base}-[0-9]+$" | sort -V | tail -n1)
    if [[ -n "$fallback" ]]; then
        which "$fallback"
        return
    fi

    echo "Error: Could not find $base or a versioned fallback like ${base}-13" >&2
    exit 1
}

# Find full compiler path
COMPILER_PATH=$(find_compiler "$COMPILER")
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
echo "Running: cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_CXX_COMPILER=$COMPILER_PATH -DBUILD_TESTING=$ENABLE_TESTS -DENABLE_FUZZING=$ENABLE_FUZZING .."
cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_CXX_COMPILER=$COMPILER_PATH -DBUILD_TESTING=$ENABLE_TESTS -DENABLE_FUZZING=$ENABLE_FUZZING ..
echo "Building project..."
cmake --build . -- -j$(nproc)


# Run tests if enabled
if [[ "$ENABLE_TESTS" == "ON" ]]; then
    echo "Running ctest --output-on-failure"
    ctest --output-on-failure
fi

# Install if requested
if [[ "$INSTALL" == true ]]; then
    echo "cmake --install ."
    cmake --install .
fi

