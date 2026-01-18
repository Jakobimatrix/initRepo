# Require C++20 without compiler extensions
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Export compile_commands.json for clang-tidy/clangd
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "" FORCE)

if(NOT CMAKE_BUILD_TYPE)
    message(FATAL_ERROR " CMAKE_BUILD_TYPE is not set. Please set it to one of the supported build types.")
endif()

if(UNIX AND NOT CMAKE_CONFIGURATION_TYPES)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
        Debug
        Release
        RelWithDebInfo
        MinSizeRel
        O0Debug
        O1Debug
        O2Debug
        O3Debug
    )
endif()   

function(set_compiler_settings target)
    if(UNIX)
        target_compile_options(${target} INTERFACE
            $<$<CONFIG:O0Debug>:-O0 -g>
            $<$<CONFIG:O1Debug>:-O1 -g>
            $<$<CONFIG:O2Debug>:-O2 -g>
            $<$<CONFIG:O3Debug>:-O3 -g>
        )
    endif()
endfunction()


if (MSVC)
    # Disable warnings about deprecated std functions and secure CRT
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
    # Force conformance mode
    add_compile_options(/permissive- /Zc:preprocessor)
endif()

