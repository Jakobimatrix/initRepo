cmake_minimum_required(VERSION 3.16)

# Define project if not already defined (useful for subproject inclusion)
if (NOT DEFINED PROJECT_NAME)
    project(<MY_PROJECT> LANGUAGES CXX)

    add_library(${PROJECT_NAME})

    # ===== Compiler Settings =====
    include(InitRepo/cmake/CompilerSetup.cmake)

    # ===== Warnings and Tools =====
    include(InitRepo/cmake/CompilerWarnings.cmake)
    set_project_warnings(${PROJECT_NAME})

    # ===== External Dependencies =====
    include(InitRepo/cmake/Includes.cmake)

    # ===== Options =====
    include(InitRepo/cmake/Options.cmake)
    enable_multithreading(${PROJECT_NAME})
    enable_shared_libraries(${PROJECT_NAME})
    # enforce_libstdc(${PROJECT_NAME})

    # ===== Fuzzing =====
    include(InitRepo/cmake/ClangFuzzyTests.cmake)
endif()

# include_eigen(${PROJECT_NAME})
# include_qt5(${PROJECT_NAME})
# include_open_cv(${PROJECT_NAME})
# include_unit_testing(${PROJECT_NAME})

add_subdirectory(src/library)
add_subdirectory(src/fuzzer_lib)
add_subdirectory(src/executables)
add_subdirectory(src/tests)
