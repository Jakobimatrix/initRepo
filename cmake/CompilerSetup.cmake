# Require C++20 without compiler extensions
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Default to Release build if not specified
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type (default Release)" FORCE)
endif()

# Define general flags for each build type
set(CMAKE_CXX_FLAGS_DEBUG "-g")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O2 -g -DNDEBUG")

# Compiler-specific settings
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    # Check for minimum version supporting full C++20
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 12)
        message(FATAL_ERROR "Clang >= 12 is required for full C++20 support. You are using ${CMAKE_CXX_COMPILER_VERSION}")
    endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 11)
        message(FATAL_ERROR "GCC >= 11 is required for full C++20 support. You are using ${CMAKE_CXX_COMPILER_VERSION}")
    endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 19.28)
        message(FATAL_ERROR "MSVC >= 19.28 is required for full C++20 support (VS2019 16.8+). You are using ${CMAKE_CXX_COMPILER_VERSION}")
    endif()
    # Disable warnings about deprecated std functions and secure CRT
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
    # Force conformance mode
    add_compile_options(/permissive- /Zc:preprocessor)
endif()

option(ENABLE_LTO "Enable Link Time Optimization" OFF)
# Link Time Optimization (LTO)
if(ENABLE_LTO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT result OUTPUT output)
    if(result)
        set_target_properties(${ENVIRONMENT_SETTINGS} PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE)
    else()
        message(WARNING "IPO / LTO not supported: ${output}")
    endif()
endif()

# Export compile_commands.json for clang-tidy/clangd
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
