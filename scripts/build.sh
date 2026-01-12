#!/bin/bash

set -e

# Ensure we are in the root folder of the repository:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "${REPO_ROOT}"

show_help() {
    echo "Usage: ./build.sh [options]"
    echo "Options:"
    echo "  -c               Clean build"
    echo "  -d               Debug build -g -O1"
    echo "  --debug          Debug build -g -O1"
    echo "  --o1debug        Debug build -g -O1"
    echo "  -r               Release build"
    echo "  --release        Release build"
    echo "  -o               RelWithDebInfo build"
    echo "  --relwithdebinfo RelWithDebInfo build"
    echo "  -i               Install after build"
    echo "  --compiler COMP  Use specific compiler (e.g. gcc, clang)"
    echo "  --builddir NAME  Use custom build directory name (default is build-COMPILER-BUILD_TYPE-ARCH-ARCH_BITS-march)"
    echo "  --arch ARCH      Architecture (x86, x64) [default: $ARCH_BITS]"
    echo "  --march VALUE    Set -march architecture string for CMake (ENABLE_MARCH). Allowed inputs are: native or the target like: core2, nehalem, sandybridge, skylake, zen3, zen4,... or the year + vendor like: 2017;AMD, 2018;Intel"
    echo "  -h               Show this help message"
    echo "  -t               Build tests"
    echo "  -T               Run Tests after build"
    echo "  -J               Test output returns junit"
    echo "  -f               Enable fuzzing"
    echo "  -v               Verbose: dump CMake variables"
    echo "  -l               List available compilers"
    echo "  -s               skip cmake and build [to be combined with -T, expects complete build]"
    echo "  -g               enable code coverage (only in combination with -d)"
    echo "  -n, --ninja      Use Ninja generator if available"
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
FUZZER_ENABLED=OFF
LIST_COMPILERS=false
VERBOSE=false
COMPILER="${DEFAULT_COMPILER}"
RUN_TESTS=false
TEST_OUTPUT_JUNIT=false
SKIP_BUILD=false
ENABLE_COVERAGE=OFF
USE_NINJA=false
TARGET_ARCH_BITS="${ARCH_BITS}"
TARGET_ARCH="${ARCH}"
ENABLE_MARCH=""
BUILD_DIR=""

# Compiler paths from .environment
CLANG_CPP_PATH="${CLANG_CPP_PATH}"
CLANG_C_PATH="${CLANG_C_PATH}"
GCC_CPP_PATH="${GCC_CPP_PATH}"
GCC_C_PATH="${GCC_C_PATH}"


list_available_compiler() {
    if [[ "$ENVIRONMENT" == "Windows-msys" ]]; then
        echo "This option is not available on windows"
        return
    fi

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
        -d) BUILD_TYPE="O1Debug" ;;
        --debug) BUILD_TYPE="O1Debug" ;;
        --o1debug) BUILD_TYPE="O1Debug" ;;
        -r) BUILD_TYPE="Release" ;;
        --release) BUILD_TYPE="Release" ;;
        -o) BUILD_TYPE="RelWithDebInfo" ;;
        -i) INSTALL=true ;;
        -s) SKIP_BUILD=true ;;
        --compiler)
            shift
            COMPILER="$1"
            ;;
        --builddir)
            shift
            BUILD_DIR="$1"
            ;;
        --arch)
            shift
            TARGET_ARCH_BITS="$1"
            if [[ "$TARGET_ARCH_BITS" != "x86" && "$TARGET_ARCH_BITS" != "x64" ]]; then
                echo "Error: Architecture must be x86 or x64"
                exit 1
            fi
            if [[ "$ARCH_BITS" == "x86" && "$TARGET_ARCH_BITS" == "x64" ]]; then
                echo "Error: Cannot cross-compile to 64-bit on a 32-bit system"
                exit 1
            fi
            if [[ "$ARCH_BITS" == "x64" && "$TARGET_ARCH_BITS" == "x86" ]]; then
                if [[ "$ENVIRONMENT" == "Linux" ]]; then
                    if ! dpkg --print-foreign-architectures | grep -q i386; then
                        echo "Error: 32-bit cross-compilation support not installed"
                        echo "Please install required packages with:"
                        echo "  sudo dpkg --add-architecture i386"
                        echo "  sudo apt update"
                        echo "  sudo apt install libc6:i386 libstdc++6:i386"
                        exit 1
                    fi
                fi
            fi
            ;;
        -t) ENABLE_TESTS=ON ;;
        -f) FUZZER_ENABLED=ON ;;
        -v) VERBOSE=true ;;
        -l) LIST_COMPILERS=true ;;
        -h) 
            show_help
            exit 1
            ;;
        -g) ENABLE_COVERAGE=ON ;;
        -T) 
            RUN_TESTS=true 
            ENABLE_TESTS=ON
            ;;
        -J) TEST_OUTPUT_JUNIT=true ;;
        -n|--ninja) USE_NINJA=true ;;
        --march)
            shift
            ENABLE_MARCH="$1"
            ;;
         *)
            echo "Unknown option: $1"
            show_help
            exit 1
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
elif [[ "$COMPILER" == "msvc" ]]; then
    echo "Error: to build for windows, you must use the build.bat script"
    exit 1
fi

# set compiler paths
if [[ "$ENVIRONMENT" == "Windows-msys" ]]; then
    if [[ "$COMPILER" == "g++" ]]; then
        if [[ "$TARGET_ARCH_BITS" == "x86" ]]; then
            COMPILER_PATH="$GCC_32_CPP_PATH"
            CC_PATH="$GCC_32_C_PATH"
        else
            COMPILER_PATH="$GCC_CPP_PATH"
            CC_PATH="$GCC_C_PATH"
        fi
        COMPILER_NAME="gcc"
        COMPILER_VERSION=$(gcc -dumpfullversion -dumpversion)
    elif [[ "$COMPILER" == "clang++" ]]; then
        if [[ "$TARGET_ARCH_BITS" == "x86" ]]; then
            COMPILER_PATH="$CLANG_32_CPP_PATH"
            CC_PATH="$CLANG_32_C_PATH"
        else
            COMPILER_PATH="$CLANG_CPP_PATH"
            CC_PATH="$CLANG_C_PATH"
        fi
        COMPILER_NAME="clang"
        COMPILER_VERSION=$(clang -dumpfullversion -dumpversion)
    fi
else
    # Unix-like systems (Linux, macOS, WSL)
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
    fi
    # shellcheck source-path=SCRIPTDIR source=ensureToolVersion.sh
    source ./initRepo/scripts/ensureToolVersion.sh
    ensure_tool_versioned "${COMPILER_NAME}" "${COMPILER_VERSION}"
fi

if [[ -z "$COMPILER_NAME" ]]; then
    echo "Error: Compiler \"$COMPILER\" is not valid for environment \"$ENVIRONMENT\""
    exit 1
fi

if [[ -z "$BUILD_DIR" ]]; then
    if [[ "$ENVIRONMENT" == "Linux" ]]; then
        # ${VAR,,} is a Bash operator that converts the value of VAR to lowercase.
        BUILD_DIR="build-${COMPILER_NAME,,}-${COMPILER_VERSION,,}-${BUILD_TYPE,,}-${TARGET_ARCH,,}-${TARGET_ARCH_BITS,,}"
    else
        BUILD_DIR="build-${COMPILER_NAME,,}-${BUILD_TYPE,,}-${TARGET_ARCH_BITS,,}"
    fi
    if [[ -n "$ENABLE_MARCH" ]]; then
        BUILD_DIR+="-$ENABLE_MARCH"
    fi
fi
echo "working direktory: $BUILD_DIR"

if [[ "$SKIP_BUILD" == false ]]; then

    # validate paths only on linux, on windows we let ninja find the paths
    if [[ "$ENVIRONMENT" == "Linux" ]]; then
        if [ ! -f "$COMPILER_PATH" ]; then
            echo "$COMPILER_PATH not found! Check the paths in .environment!"
            list_available_compiler
            exit 1
        fi
        if [ ! -f "$CC_PATH" ]; then
            echo "$CC_PATH not found! Check the paths in .environment!"
            list_available_compiler
            exit 1
        fi
    fi

    # Validate fuzzer option
    if [[ "$FUZZER_ENABLED" == "ON" && "$COMPILER" != "clang++" ]]; then
        echo "Error: Fuzzing (-f) is only supported with the clang compiler."
        exit 1
    fi

    # Validate fuzzer option
    if [[ "$FUZZER_ENABLED" == "ON" && "$BUILD_TYPE" == "Release" ]]; then
        echo "Error: Fuzzing (-f) in release mode (-r)--> O3 is a bad Idea. Use debug (-d) --> (-g -O1) or RelWithDebInfo (-o) --> (-g -O2)."
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
    echo "Using cpp compiler at: $COMPILER_PATH version $COMPILER_VERSION" 
    echo "Using c compiler at: $CC_PATH"
    echo "compiling from: $ENVIRONMENT: $ARCH-$ARCH_BITS"
    echo "compiling for: $ENVIRONMENT: $ARCH-$TARGET_ARCH_BITS"
    echo "Configuring with CMake..."

    CMAKE_ARGS=(-DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_CXX_COMPILER=$COMPILER_PATH -DCMAKE_C_COMPILER=$CC_PATH -DBUILD_TESTING=$ENABLE_TESTS -DFUZZER_ENABLED=$FUZZER_ENABLED -DENABLE_COVERAGE=$ENABLE_COVERAGE)
    if [[ -n "$ENABLE_MARCH" ]]; then
        CMAKE_ARGS+=(-DENABLE_MARCH="$ENABLE_MARCH")
    fi
    
    # Use ninja if requested and found
    if [[ "$USE_NINJA" == true ]]; then
        if ! command -v ninja &>/dev/null; then
            echo "Warning: Ninja not found, falling back to default generator"
            USE_NINJA=false
        else
            CMAKE_ARGS+=(-G "Ninja")
        fi
    fi    

    # Add architecture flags only if needed
    if [[ "$TARGET_ARCH_BITS" != "$ARCH_BITS" ]]; then
        if [[ "$TARGET_ARCH_BITS" == "x86" ]]; then
            CMAKE_ARGS+=(-DCMAKE_CXX_FLAGS="-m32" -DCMAKE_C_FLAGS="-m32")
        elif [[ "$TARGET_ARCH_BITS" == "x64" ]]; then
            CMAKE_ARGS+=(-DCMAKE_CXX_FLAGS="-m64" -DCMAKE_C_FLAGS="-m64")
        fi
    fi

    
    echo "Running: cmake ${CMAKE_ARGS[*]} .."
    cmake "${CMAKE_ARGS[@]}" ..
    if [[ "$VERBOSE" == true ]]; then
        echo "Dumping CMake variables:"
        cmake -LAH ..
    fi

    echo "Building project..."
    cmake --build . -- -j"$(nproc)"

else
    cd "$BUILD_DIR"
fi

TESTS_OK=true
# Run tests if enabled
if [[ "$RUN_TESTS" == true ]]; then
    echo "Running ctest --output-on-failure"

    if [[ "$TEST_OUTPUT_JUNIT" == true ]]; then
        echo "Running ctest --output-on-failure --output-junit test_results.xml"
        ctest --output-on-failure --output-junit test_results.xml
    else
        echo "Running ctest --output-on-failure"
        ctest --output-on-failure
    fi
    if [[ $? -eq 0 ]]; then
        TESTS_OK=true
    else
        TESTS_OK=false
    fi
    NUM_TESTS=$(ctest -N | grep -c "Test #[0-9]\+:" || true)
    if [[ "$NUM_TESTS" -eq 0 ]]; then
        echo "WARNING No tests were found or executed!"
    fi
    
    if [[ "TESTS_OK" == false ]]; then
        exit 1
    fi
fi

# Install if requested
if [[ "$INSTALL" == true ]]; then
    echo "cmake --install ."
    cmake --install .
fi

exit 0
