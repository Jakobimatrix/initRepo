cmake_minimum_required(VERSION 3.16)

# Define project if not already defined (useful for subproject inclusion)
if (NOT DEFINED PROJECT_NAME)
    project(<MY_PROJECT> LANGUAGES CXX)

    # This variable must exist!
    set(ENVIRONMENT_SETTINGS "ProjectSettings")

    add_library("${ENVIRONMENT_SETTINGS}" INTERFACE)

    # ===== Compiler Settings =====
    include(InitRepo/cmake/CompilerSetup.cmake)

    # ===== Warnings and Tools =====
    include(InitRepo/cmake/CompilerWarnings.cmake)
    set_project_warnings(${ENVIRONMENT_SETTINGS})

    # ===== External Dependencies =====
    include(InitRepo/cmake/Includes.cmake)

    # ===== Options =====
    include(InitRepo/cmake/Options.cmake)
    enable_multithreading(${ENVIRONMENT_SETTINGS})
    enable_shared_libraries(${ENVIRONMENT_SETTINGS})

    # one of these two above is needed, enable_shared_libraries must be used too!!
    enforce_clang_stl(${ENVIRONMENT_SETTINGS} "libstdc++")

    # ===== Fuzzing =====
    include(InitRepo/cmake/ClangFuzzyTests.cmake)
endif()

# include_eigen(${ENVIRONMENT_SETTINGS})
# include_qt5(${ENVIRONMENT_SETTINGS})
# include_open_cv(${ENVIRONMENT_SETTINGS})
# include_unit_testing(${ENVIRONMENT_SETTINGS})

add_subdirectory(src/library)
add_subdirectory(src/fuzzer_lib)
add_subdirectory(src/executables)
add_subdirectory(src/tests)
