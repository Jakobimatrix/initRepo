# Enable shared library build options
function(enable_shared_libraries target_name)
    if (UNIX)
        target_compile_options(${target_name} INTERFACE -fPIC)
        if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
            target_link_options(${target_name} INTERFACE -fuse-ld=lld)
        endif ()
    endif ()
endfunction()

# Enable multithreading for a target
function(enable_multithreading target_name)
    if (UNIX OR MINGW)
        target_link_libraries(${target_name} INTERFACE pthread)
    endif ()
    # MSVC links threads by default
endfunction()

# Enforce a consistent C++ standard on a target
function(enforce_libstdc target_name)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        # Force use of libc++
        target_compile_options(${target_name} INTERFACE -stdlib=libc++)
        target_link_options(${target_name} INTERFACE -stdlib=libc++)
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        # Implicitly uses libstdc++, no special flags needed
        message(STATUS "GCC will use libstdc++ (default)")
    elseif(MSVC)
        # MSVC uses its own STL, can't change it
        message(STATUS "MSVC STL in use (default, cannot be changed)")
    else()
        message(WARNING "Unknown compiler: cannot enforce standard library")
    endif()
endfunction()
