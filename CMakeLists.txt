cmake_minimum_required(VERSION 3.16)

project(initRepo LANGUAGES CXX)

set(ENVIRONMENT_SETTINGS "ProjectSettings")
add_library(${ENVIRONMENT_SETTINGS} INTERFACE)

# ===== Compiler Settings =====
include(cmake/CompilerSetup.cmake)

# ===== Warnings and Tools =====
include(cmake/CompilerWarnings.cmake)
set_project_warnings(${ENVIRONMENT_SETTINGS})

# ===== External Dependencies =====
include(cmake/Includes.cmake)

# ===== Options =====
include(cmake/Options.cmake)

enable_multithreading(${ENVIRONMENT_SETTINGS})
enable_shared_libraries(${ENVIRONMENT_SETTINGS})

# ===== Fuzzing =====
include(cmake/ClangFuzzyTests.cmake)


add_subdirectory(src/library)
add_subdirectory(src/fuzzer_lib)
add_subdirectory(src/executables)
add_subdirectory(src/tests)
