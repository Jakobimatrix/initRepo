# Require C++20 without compiler extensions
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Export compile_commands.json for clang-tidy/clangd
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "" FORCE)


# Default to Release build if not specified
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type (default Release)" FORCE)
endif()

# Define our debug mode Activated with 'cmake -DCMAKE_BUILD_TYPE=O1'
set(CMAKE_CXX_FLAGS_O1Debug "-O1 -g" CACHE STRING "Flags for O1Debug build" FORCE)
set(CMAKE_C_FLAGS_O1Debug    "-O1 -g" CACHE STRING "Flags for O1Debug build" FORCE)
set(CMAKE_EXE_LINKER_FLAGS_O1Debug "" CACHE STRING "" FORCE)

if (MSVC)
    # Disable warnings about deprecated std functions and secure CRT
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
    # Force conformance mode
    add_compile_options(/permissive- /Zc:preprocessor)
endif ()

