cmake_minimum_required(VERSION 3.16)

project(<MY_PROJECT> Version 1.0.0 LANGUAGES CXX)

# defines umbrella targets to link against. It is protected against multiple includes.
add_subdirectory(initRepo) # adds CompilerSetup.cmake and Includes.cmake

manage_library(${PROJECT_NAME} ${PROJECT_VERSION})

if (DEFINED ACCEPTED_LIB_VERSION)
  if(NOT ${ACCEPTED_LIB_VERSION} STREQUAL ${LIB_VERSION})
    message(FATAL_ERROR "${LIB_NAME} already included with a different version. This Version: ${LIB_VERSION}, Other Version: ${ACCEPTED_LIB_VERSION}")
  endif()
  return()
endif()

enable_testing()

# ===== CTest with Catch2 =====
setup_catch2_and_ctest()

# ===== Include helpers =====
# include_eigen(${ENVIRONMENT_SETTINGS})
# include_qt5(${ENVIRONMENT_SETTINGS})
# include_open_cv(${ENVIRONMENT_SETTINGS})

add_subdirectory(src/library)
add_subdirectory(src/executables)
add_subdirectory(src/tests)
