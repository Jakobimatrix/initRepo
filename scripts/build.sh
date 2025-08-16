#!/bin/bash

set -e

# Ensure we are in the root folder of the repository:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "${REPO_ROOT}"

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
    echo "  -t              Build tests"
    echo "  -T              Run Tests after build"
    echo "  -J              Test output returns junit"
    echo "  -f              Enable fuzzing"
    echo "  -v              Verbode: dump CMake variables"
    echo "  -l              List available compilers"
    echo "  -C              only run CMake"
    echo "  -s              skip cmake and build [to be combined with -T, expects complete build]"
    exit 0
}

# Source environment variables
# shellcheck source-path=../ 
source "initRepo/.environment"
if [ -f ".environment" ]; then
    source ".environment"
fi

# Defaults
CLEAN=false
INSTALL=false
BUILD_TYPE=""
ENABLE_TESTS=OFF
ENABLE_FUZZING=OFF
LIST_COMPILERS=false
VERBOSE=false
COMPILER="${DEFAULT_COMPILER}"
CONFIG_CMAKE_ONLY=false
RUN_TESTS=false
TEST_OUTPUT_JUNIT=false
SKIP_BUILD=false

# Compiler paths from .environment
CLANG_CPP_PATH="${CLANG_CPP_PATH}"
CLANG_C_PATH="${CLANG_C_PATH}"
GCC_CPP_PATH="${GCC_CPP_PATH}"
GCC_C_PATH="${GCC_C_PATH}"


list_available_compiler() {
    for base in gcc g++ clang clang++; do
        echo ""
        echo "=== $base ==="
        # Find unversioned
        if command -v "$base" &>/dev/null; then
            echo "  $(command -v $base)"
        fi
        # Find versioned (handle pluses for g++ and clang++)
        if [[ "$base" == "g++" || "$base" == "clang++" ]]; then
            compgen -c | grep -E "^${base//+/\\+}-[0-9]+$" | sort -V | while read -r ver; do
                if command -v "$ver" &>/dev/null; then
                    echo "  $(command -v "$ver")"
                fi
            done
        else
            compgen -c | grep -E "^${base}-[0-9]+$" | sort -V | while read -r ver; do
                if command -v "$ver" &>/dev/null; then
                    echo "  $(command -v "$ver")"
                fi
            done
        fi
    done
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c) CLEAN=true ;;
        -d) BUILD_TYPE="Debug" ;;
        -r) BUILD_TYPE="Release" ;;
        -o) BUILD_TYPE="RelWithDebInfo" ;;
        -i) INSTALL=true ;;
        -s) SKIP_BUILD=true ;;
        --compiler)
            shift
            COMPILER="$1"
            ;;
        -t) ENABLE_TESTS=ON ;;
        -f) ENABLE_FUZZING=ON ;;
        -v) VERBOSE=true ;;
        -l) LIST_COMPILERS=true ;;
        -h) show_help ;;
        -C) CONFIG_CMAKE_ONLY=true ;;
        -T) 
            RUN_TESTS=true 
            ENABLE_TESTS=ON
            ;;
        -J) TEST_OUTPUT_JUNIT=true ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
    shift
done


if [[ "$LIST_COMPILERS" == true ]]; then
    list_available_compiler
    if [[ -z "$BUILD_TYPE" ]]; then
        exit 0
    fi
fi

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

# set compiler paths
if [[ "$COMPILER" == "g++" ]]; then
    COMPILER_PATH="$GCC_CPP_PATH"
    CC_PATH="$GCC_C_PATH"
    COMPILER_NAME="gcc"
    COMPILER_VERSION="${GCC_VERSION}"
elif [[ "$COMPILER" == "clang++" ]]; then
    COMPILER_PATH="$CLANG_CPP_PATH"
    CC_PATH="$CLANG_C_PATH"
    COMPILER_NAME="clang"
    COMPILER_VERSION="${CLANG_VERSION}"
else
    echo "Error: Compiler \"$COMPILER\" is not a valid input."
    exit 1
fi

BUILD_DIR="build-${COMPILER_NAME,,}-${COMPILER_VERSION,,}-${BUILD_TYPE,,}"

if [[ "$SKIP_BUILD" == false ]]; then

    # shellcheck source-path=SCRIPTDIR source=ensureToolVersion.sh
    source ./initRepo/scripts/ensureToolVersion.sh
    ensure_tool_versioned g++ "${GCC_VERSION}"
    ensure_tool_versioned gcc "${GCC_VERSION}"
    ensure_tool_versioned clang++ "${CLANG_VERSION}"
    ensure_tool_versioned clang "${CLANG_VERSION}"

    if [ ! -f "$COMPILER_PATH" ]; then
        echo "$COMPILER_PATH not found! Check the paths variables at the begin of this script!"
        list_available_compiler
        exit 1
    fi
    if [ ! -f "$CC_PATH" ]; then
        echo "$CC_PATH not found! Check the paths variables at the begin of this script!"
        list_available_compiler
        exit 1
    fi


    # Validate fuzzer option
    if [[ "$ENABLE_FUZZING" == "ON" && "$COMPILER" != "clang++" ]]; then
        echo "Error: Fuzzing (-f) is only supported with the clang compiler."
        exit 1
    fi


    # Clean build directory if requested
    if [[ "$CLEAN" == true ]]; then
        echo "Cleaning build directory: $BUILD_DIR"
        rm -rf "$BUILD_DIR"
    fi

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    # Run CMake
    echo "Using cpp compiler at: $COMPILER_PATH"
    echo "Using c compiler at: $CC_PATH"
    echo "To change compiler versions, set the variables in the .environment!!"
    echo "Configuring with CMake..."
    echo "Running: cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_CXX_COMPILER=$COMPILER_PATH -DCMAKE_C_COMPILER=$CC_PATH -DBUILD_TESTING=$ENABLE_TESTS -DENABLE_FUZZING=$ENABLE_FUZZING .."
    cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_CXX_COMPILER=$COMPILER_PATH -DCMAKE_C_COMPILER=$CC_PATH -DBUILD_TESTING=$ENABLE_TESTS -DENABLE_FUZZING=$ENABLE_FUZZING ..
    if [[ "$VERBOSE" == true ]]; then
        echo "Dumping CMake variables:"
        cmake -LAH ..
    fi

    if [[ "$CONFIG_CMAKE_ONLY" == true ]]; then
        echo "CMake configuration only (-C set). Exiting before build."
        echo "BUILD_DIR=$BUILD_DIR"
        exit 0
    fi


    echo "Building project..."
    cmake --build . -- -j"$(nproc)"

else
    cd "$BUILD_DIR"
fi


# Run tests if enabled
if [[ "$RUN_TESTS" == true ]]; then
    echo "Running ctest --output-on-failure"

    if [[ "$TEST_OUTPUT_JUNIT" == true ]]; then
        echo "Running ctest --output-on-failure --output-junit test_results.xml"
        ctest --output-on-failure --output-junit test_results.xml
    else
        echo "Running ctest --output-on-failure"
        ctest --output-on-failure

        # Check if any tests were found
        NUM_TESTS=$(ctest -N | grep -c "Test #[0-9]\+:" || true)
        if [[ "$NUM_TESTS" -eq 0 ]]; then
            echo "ERROR: No tests were found or executed!"
            exit 2
        fi
    fi
fi

# Install if requested
if [[ "$INSTALL" == true ]]; then
    echo "cmake --install ."
    cmake --install .
fi
