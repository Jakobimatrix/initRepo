
if(NOT DEFINED INIT_REPO_INCLUDED)
    set(INIT_REPO_INCLUDED TRUE)

include(cmake/CompilerSetup.cmake)
include(cmake/Includes.cmake)
include(cmake/ProjectSettings.cmake)

option(BUILD_TESTING "Enable building of unit tests with CTest/Catch2" ON)
set(ENABLE_MARCH "" CACHE STRING "Architecture for -march: empty disables, 'native' for host, 'year;vendor (2017;AMD)' or 'chip name (e.g. skylake)' for specific CPU.")
option(ENABLE_MFPMATH_SSE "Use SSE for floating-point math (legacy x86)" OFF)
option(ENABLE_MMS_BITFIELDS "MSVC-compatible bitfield layout (MinGW/Windows only)" OFF)
option(ENABLE_FNO_STRICT_ALIASING "Disable strict aliasing optimizations (safer for type-punning)" OFF)

option(ENABLE_LTO "Enable Link Time Optimization" OFF)
option(ENABLE_COVERAGE "Enable code coverage instrumentation" OFF)
option(WARNINGS_AS_ERRORS "Treat all compiler warnings as errors" TRUE)
option(ENABLE_CLANG_TIDY "Run clang-tidy static analysis if available" OFF)
option(ENABLE_CPPCHECK "Run cppcheck static analysis if available" OFF)
option(ENABLE_MULTITHREADING "Link against pthreads/Threads on Unix" OFF)

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
    option(FUZZER_ENABLED "Enable fuzz testing build options" OFF)
else()
    set(FUZZER_ENABLED OFF)
endif ()

if (FUZZER_ENABLED)
    if (CMAKE_BUILD_TYPE STREQUAL "Release")
        message(FATAL_ERROR "Fuzzer build requires -O1 or -O2 optimization level and -g (debug symbols), not -O3 (Release). Please set -DCMAKE_BUILD_TYPE to 'RelWithDebInfo' or '01'.")
    endif()
endif()

add_library(BuildSettings_LIB INTERFACE)
add_library(BuildSettings_EXE INTERFACE)
add_library(BuildSettings_FUZZER INTERFACE)
add_library(BuildSettings_CATHCH2_UNITTEST INTERFACE) 

set_project_settings(BuildSettings_LIB)
set_project_settings(BuildSettings_EXE)
set_project_settings(BuildSettings_FUZZER)
set_project_settings(BuildSettings_CATHCH2_UNITTEST)

##### Target specific options #####

## Compiler warnings:
if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
  target_compile_options(BuildSettings_CATHCH2_UNITTEST INTERFACE
    -Wno-unused-macros
  )
endif()

## Fuzzer:
set(FUZZ_MODE "ADDRESS" CACHE STRING "Choose fuzzing sanitizer mode: ADDRESS, THREAD, MEMORY")
if(FUZZ_MODE STREQUAL "ADDRESS")
    # Enable fuzzing with address sanitizer and undefined behavior sanitizer
    set(FUZZER_SAN_FLAGS address,undefined)
elseif(FUZZ_MODE STREQUAL "THREAD")
    # Enable fuzzing with thread sanitizer for race condition detection
    set(FUZZER_SAN_FLAGS thread)
elseif(FUZZ_MODE STREQUAL "MEMORY")
    # Enable fuzzing with memory sanitizer for uninitialized memory detection
    set(FUZZER_SAN_FLAGS memory)
else()
    message(FATAL_ERROR "Invalid FUZZ_MODE: ${FUZZ_MODE}. Choose BASIC, SAFE, THREAD, MEMORY.")
endif()

if(FUZZER_ENABLED)
    # Apply all targets against sanitizer flag for full fuzzing instrumentation (without main function)
    target_link_options(BuildSettings_LIB INTERFACE -fsanitize=fuzzer-no-link,${FUZZER_SAN_FLAGS})
    target_compile_options(BuildSettings_LIB INTERFACE -fsanitize=fuzzer-no-link,${FUZZER_SAN_FLAGS})

    # Apply fuzzer sanitizer flags for full fuzzing instrumentation (fsanitize will provide the main function)
    target_compile_options(BuildSettings_FUZZER INTERFACE -fsanitize=fuzzer,${FUZZER_SAN_FLAGS})
    target_link_options(BuildSettings_FUZZER INTERFACE -fsanitize=fuzzer,${FUZZER_SAN_FLAGS})
endif()

# Function: generate_fuzzer_name
# Args:
#   BASE_NAME     - base name of the fuzzer (e.g., "fuzzer_example")
#   OUT_VAR       - name of variable to store the resulting fuzzer name
function(generate_fuzzer_name BASE_NAME OUT_VAR)
    # Ensure build type is set
    if(NOT CMAKE_BUILD_TYPE)
        message(FATAL_ERROR "CMAKE_BUILD_TYPE must be set for fuzzing. Choose one of: O1, RelWithDebInfo, etc.")
    endif()

    # Convert FUZZ_MODE to lowercase for the executable name
    string(TOLOWER "${FUZZ_MODE}" FUZZ_MODE_LOWER)

    # Construct full fuzzer executable name
    # Example: fuzzer_example_address_O1
    set(FULL_NAME "${BASE_NAME}_${FUZZ_MODE_LOWER}_${CMAKE_BUILD_TYPE}")

    # Return value
    set(${OUT_VAR} "${FULL_NAME}" PARENT_SCOPE)
endfunction()


# graphviz
set(GRAPHVIZ_IGNORE_TARGETS "test*")
set(GRAPHVIZ_EXTERNAL_LIBS FALSE)



message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "Cpp standard: C++${CMAKE_CXX_STANDARD}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Architecture: ${TARGET_ARCH}")
message(STATUS "CMake source dir: ${CMAKE_SOURCE_DIR}")
message(STATUS "CMake binary dir: ${CMAKE_BINARY_DIR}")
message(STATUS "CMake install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "CMake generator: ${CMAKE_GENERATOR}")
message(STATUS "CMake version: ${CMAKE_VERSION}")
message(STATUS "CMake system: ${CMAKE_SYSTEM}")
message(STATUS "CMake system name: ${CMAKE_SYSTEM_NAME}")
message(STATUS "CMake system processor: ${CMAKE_SYSTEM_PROCESSOR}")

message(STATUS "CMake host system: ${CMAKE_HOST_SYSTEM}")
message(STATUS "CMake host system name: ${CMAKE_HOST_SYSTEM_NAME}")
message(STATUS "CMake host system processor: ${CMAKE_HOST_SYSTEM_PROCESSOR}")

endif()
