# Enable shared library build options
function(enable_shared_libraries target_name)
    if (UNIX)
        target_compile_options("${target_name}" INTERFACE -fPIC)
        if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
            target_link_options("${target_name}" INTERFACE -fuse-ld=lld)
        endif ()
    endif ()
endfunction()

# Enable multithreading for a target
function(enable_multithreading target_name)
    # use cmakes build in function to link against -pthread or -mthreads if necessarry
    find_package(Threads REQUIRED)
    target_link_libraries("${target_name}" INTERFACE Threads::Threads)
endfunction()


