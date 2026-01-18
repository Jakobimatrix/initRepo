set(MSVC_WARNINGS
    /W4 # Baseline reasonable warnings
    /WX # Warnings are errors
    /w14242 # 'identifier': conversion from 'type1' to 'type1', possible loss of data
    /w14254 # 'operator': conversion from 'type1:field_bits' to 'type2:field_bits', possible loss of data
    /w14263 # 'function': member function does not override any base class virtual member function
    /w14265 # 'classname': class has virtual functions, but destructor is not virtual instances of this class may not
            # be destructed correctly
    /w14287 # 'operator': unsigned/negative constant mismatch
    /we4289 # nonstandard extension used: 'variable': loop control variable declared in the for-loop is used outside
            # the for-loop scope
    /w14296 # 'operator': expression is always 'boolean_value'
    /w14311 # 'variable': pointer truncation from 'type1' to 'type2'
    /w14545 # expression before comma evaluates to a function which is missing an argument list
    /w14546 # function call before comma missing argument list
    /w14547 # 'operator': operator before comma has no effect; expected operator with side-effect
    /w14549 # 'operator': operator before comma has no effect; did you intend 'operator'?
    /w14555 # expression has no effect; expected expression with side- effect
    /w14619 # pragma warning: there is no warning number 'number'
    /w14640 # Enable warning on thread un-safe static member initialization
    /w14826 # Conversion from 'type1' to 'type_2' is sign-extended. This may cause unexpected runtime behavior.
    /w14905 # wide string literal cast to 'LPSTR'
    /w14906 # string literal cast to 'LPWSTR'
    /w14928 # illegal copy-initialization; more than one user-defined conversion has been implicitly applied
    /permissive- # standards conformance mode for MSVC compiler.
)


set(CLANG_WARNINGS
    -Wall
    -Werror #warnings are errors
    -Wextra # reasonable and standard
    -Wshadow # warn the user if a variable declaration shadows one from a parent context
    -Wnon-virtual-dtor # warn the user if a class with virtual functions has a non-virtual destructor. This helps
    # catch hard to track down memory errors
    -Wold-style-cast # warn for c-style casts
    -Wcast-align # warn for potential performance problem casts
    -Wunused # warn on anything being unused
    -Woverloaded-virtual # warn if you overload (not override) a virtual function
    -Wpedantic # warn if non-standard C++ is used
    -Wconversion # warn on type conversions that may lose data
    -Wsign-conversion # warn on sign conversions
    -Wnull-dereference # warn if a null dereference is detected
    -Wdouble-promotion # warn if float is implicit promoted to double
    -Wformat=2 # warn on security issues around functions that format output (ie printf)
    -Wimplicit-fallthrough # warn on statements that fallthrough without an explicit annotation
)

set(GCC_WARNINGS
    ${CLANG_WARNINGS}
    -Wmisleading-indentation # warn if indentation implies blocks where blocks do not exist
    -Wduplicated-cond # warn if if / else chain has duplicated conditions
    -Wduplicated-branches # warn if if / else branches have duplicated code
    -Wlogical-op # warn about logical operations being used where bitwise were probably wanted
)

function(set_coverage target_name)
    if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        set(PROFILE_OUTPUT_DIR "profraw")
        file(MAKE_DIRECTORY ${PROFILE_OUTPUT_DIR})

        # Generate instrumentation for binary
        target_compile_options(${target_name} INTERFACE
            -fprofile-instr-generate=${PROFILE_OUTPUT_DIR}/%m-%p.profraw
            -fcoverage-mapping
        )
        # Link with profile runtime library
        target_link_options(${target_name} INTERFACE
            -fprofile-instr-generate=${PROFILE_OUTPUT_DIR}/%m-%p.profraw
            -fcoverage-mapping
        )

    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options(${target_name} INTERFACE
            --coverage          # Enable gcov coverage instrumentation
        )
        target_link_options(${target_name} INTERFACE
            --coverage          # Link with gcov libraries
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${target_name} INTERFACE
            /PROFILE            # Enable profiling instrumentation
            /COVERAGE           # Enable coverage instrumentation
            /DEBUG              # Generate debug information
        )
        target_link_options(${target_name} INTERFACE
            /PROFILE            # Enable profiling at link time
            /COVERAGE           # Enable coverage
            /DEBUG              # Include debug information in output
        )
    endif()
endfunction()


function(set_project_settings target_name)
    # Propagate the globally set C++ standard to all consumers of the INTERFACE target
    if(NOT DEFINED CMAKE_CXX_STANDARD)
        message(FATAL_ERROR "CMAKE_CXX_STANDARD is not defined!") 
    endif()

    target_compile_features(${target_name} INTERFACE cxx_std_${CMAKE_CXX_STANDARD})

    # Compiler warnings
    if(MSVC)
        set(PROJECT_WARNINGS_CXX ${MSVC_WARNINGS})
    elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
        set(PROJECT_WARNINGS_CXX ${CLANG_WARNINGS})
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(PROJECT_WARNINGS_CXX ${GCC_WARNINGS})
    else()
        message(AUTHOR_WARNING "No compiler warnings set for CXX compiler: '${CMAKE_CXX_COMPILER_ID}'")
    endif()

    target_compile_options(${target_name} INTERFACE ${PROJECT_WARNINGS_CXX})

    # Optionally add -march flag based on user input and set TARGET_ARCH
    if(DEFINED ENABLE_MARCH)
        if(ENABLE_MARCH STREQUAL "")
            set(TARGET_ARCH "mixed" CACHE INTERNAL "Target architecture")
        elseif(ENABLE_MARCH MATCHES ";")
            string(REPLACE ";" ";" march_parts ${ENABLE_MARCH})
            list(GET march_parts 0 year)
            list(GET march_parts 1 arch)
            if(arch STREQUAL "AMD")
                if(year STREQUAL "2011")
                    target_compile_options(${target_name} INTERFACE -march=bulldozer)
                    set(TARGET_ARCH "bulldozer_amd" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2012")
                    target_compile_options(${target_name} INTERFACE -march=piledriver)
                    set(TARGET_ARCH "piledriver_amd" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2017")
                    target_compile_options(${target_name} INTERFACE -march=znver1)
                    set(TARGET_ARCH "znver1_amd" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2019")
                    target_compile_options(${target_name} INTERFACE -march=znver2)
                    set(TARGET_ARCH "znver2_amd" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2020")
                    target_compile_options(${target_name} INTERFACE -march=znver3)
                    set(TARGET_ARCH "znver3_amd" CACHE INTERNAL "Target architecture")
                else()
                    message(WARNING "No AMD mapping for year ${year}, no -march flag set.")
                    set(TARGET_ARCH "unknown_amd" CACHE INTERNAL "Target architecture")
                endif()
            elseif(arch STREQUAL "Intel")
                if(year STREQUAL "2008")
                    target_compile_options(${target_name} INTERFACE -march=nehalem)
                    set(TARGET_ARCH "nehalem_intel" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2010")
                    target_compile_options(${target_name} INTERFACE -march=corei7)
                    set(TARGET_ARCH "corei7_intel" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2011")
                    target_compile_options(${target_name} INTERFACE -march=sandybridge)
                    set(TARGET_ARCH "sandybridge_intel" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2012")
                    target_compile_options(${target_name} INTERFACE -march=ivybridge)
                    set(TARGET_ARCH "ivybridge_intel" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2013")
                    target_compile_options(${target_name} INTERFACE -march=haswell)
                    set(TARGET_ARCH "haswell_intel" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2014")
                    target_compile_options(${target_name} INTERFACE -march=broadwell)
                    set(TARGET_ARCH "broadwell_intel" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2015")
                    target_compile_options(${target_name} INTERFACE -march=skylake)
                    set(TARGET_ARCH "skylake_intel" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2017")
                    target_compile_options(${target_name} INTERFACE -march=kabylake)
                    set(TARGET_ARCH "kabylake_intel" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2018")
                    target_compile_options(${target_name} INTERFACE -march=cannonlake)
                    set(TARGET_ARCH "cannonlake_intel" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2019")
                    target_compile_options(${target_name} INTERFACE -march=icelake-client)
                    set(TARGET_ARCH "icelake-client_intel" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2020")
                    target_compile_options(${target_name} INTERFACE -march=tigerlake)
                    set(TARGET_ARCH "tigerlake_intel" CACHE INTERNAL "Target architecture")
                elseif(year STREQUAL "2021")
                    target_compile_options(${target_name} INTERFACE -march=alderlake)
                    set(TARGET_ARCH "alderlake_intel" CACHE INTERNAL "Target architecture")
                else()
                    message(WARNING "No Intel mapping for year ${year}, no -march flag set.")
                    set(TARGET_ARCH "unknown_intel" CACHE INTERNAL "Target architecture")
                endif()
            else()
                target_compile_options(${target_name} INTERFACE -march=${arch})
                set(TARGET_ARCH "mixed" CACHE INTERNAL "Target architecture")
            endif()
        elseif(ENABLE_MARCH STREQUAL "native")
            target_compile_options(${target_name} INTERFACE -march=native)
            # Try to detect vendor from CMAKE_SYSTEM_PROCESSOR
            if(CMAKE_SYSTEM_PROCESSOR MATCHES "amd64|x86_64|znver|bulldozer|piledriver")
                set(TARGET_ARCH "native_amd" CACHE INTERNAL "Target architecture")
            elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "intel|core|nehalem|sandybridge|haswell|skylake|kabylake|cannonlake|icelake|tigerlake|alderlake")
                set(TARGET_ARCH "native_intel" CACHE INTERNAL "Target architecture")
            else()
                set(TARGET_ARCH "native" CACHE INTERNAL "Target architecture")
            endif()
        else()
            # Check if ENABLE_MARCH is a known architecture
            set(_known_archs "nehalem" "corei7" "sandybridge" "ivybridge" "haswell" "broadwell" "skylake" "kabylake" "cannonlake" "icelake-client" "tigerlake" "alderlake" "bulldozer" "piledriver" "znver1" "znver2" "znver3")
            list(FIND _known_archs "${ENABLE_MARCH}" _arch_index)
            if(_arch_index GREATER -1)
                target_compile_options(${target_name} INTERFACE -march=${ENABLE_MARCH})
                # Append _intel or _amd for known architectures
                if(ENABLE_MARCH MATCHES "bulldozer|piledriver|znver1|znver2|znver3")
                    set(TARGET_ARCH "${ENABLE_MARCH}_amd" CACHE INTERNAL "Target architecture")
                else()
                    set(TARGET_ARCH "${ENABLE_MARCH}_intel" CACHE INTERNAL "Target architecture")
                endif()
            else()
                message(FATAL_ERROR "Unknown architecture for -march: ${ENABLE_MARCH}")
            endif()
        endif()
    endif()

    # Optionally add -mfpmath=sse
    if(ENABLE_MFPMATH_SSE)
        target_compile_options(${target_name} INTERFACE -mfpmath=sse)
    endif()

    # Optionally add -mms-bitfields
    if(ENABLE_MMS_BITFIELDS)
        target_compile_options(${target_name} INTERFACE -mms-bitfields)
    endif()

    # Optionally add -fno-strict-aliasing
    if(ENABLE_FNO_STRICT_ALIASING)
        target_compile_options(${target_name} INTERFACE -fno-strict-aliasing)
    endif()

    # Clang-Tidy integration
    if(ENABLE_CLANG_TIDY AND CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        find_program(CLANG_TIDY_EXE NAMES clang-tidy)
        if(CLANG_TIDY_EXE)
            set_target_properties(${target_name} PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_EXE}")
        else()
            message(WARNING "Clang-Tidy requested but not found")
        endif()
    endif()

    # Cppcheck integration
    if(ENABLE_CPPCHECK)
        find_program(CPPCHECK_EXE NAMES cppcheck)
        if(CPPCHECK_EXE)
            set_target_properties(${target_name} PROPERTIES CXX_CPPCHECK "${CPPCHECK_EXE}")
        else()
            message(WARNING "Cppcheck requested but not found")
        endif()
    endif()

    if(ENABLE_MULTITHREADING)
        find_package(Threads REQUIRED)
        target_link_libraries(${target_name} INTERFACE Threads::Threads)
    endif()

    if (UNIX)
        # Position Independent Code - allow relative address jumps (needed for shared libraries)
        target_compile_options(${target_name} INTERFACE -fPIC)
        if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
            # Use LLVM's LLD linker for faster linking
            target_link_options(${target_name} INTERFACE -fuse-ld=lld)
        endif ()
    endif ()

    if(ENABLE_LTO)
        include(CheckIPOSupported)
        check_ipo_supported(RESULT result OUTPUT output)
        if(result)
            set_target_properties(${target_name} PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE)
        else()
            message(WARNING "IPO / LTO not supported: ${output}")
        endif()
    endif()

    if (MSVC)
        target_compile_options(${target_name} INTERFACE 
            -utf-8  # Use UTF-8 encoding character sets
            -bigobj # Increase the number of sections in .obj files
        )
    endif ()

    # Code coverage instrumentation
    if (ENABLE_COVERAGE)
        if(FUZZER_ENABLED)
            message(FATAL_ERROR "Code coverage and fuzzy testing cannot be enabled at the same time.")
        endif()
        set_coverage(${target_name})
    endif()
        
endfunction()
