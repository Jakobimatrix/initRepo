cmake_minimum_required(VERSION 3.16)

project(initRepo LANGUAGES CXX)

add_library(${PROJECT_NAME})

# ===== Compiler Settings =====
include(cmake/CompilerSetup.cmake)

# ===== Warnings and Tools =====
include(cmake/CompilerWarnings.cmake)
set_project_warnings(${PROJECT_NAME})

# ===== External Dependencies =====
include(cmake/Includes.cmake)

# ===== Options =====
include(cmake/Options.cmake)
enable_multithreading(${PROJECT_NAME})
enable_shared_libraries(${PROJECT_NAME})
# enforce_libstdc(${PROJECT_NAME})

# ===== Fuzzing =====
include(cmake/ClangFuzzyTests.cmake)


add_subdirectory(src/library)
add_subdirectory(src/fuzzer_lib)
add_subdirectory(src/executables)
add_subdirectory(src/tests)
