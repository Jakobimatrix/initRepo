# Include Boost with target-specific flags
function(include_boost target_name)
    # Try to find a system-installed Boost first
    find_package(Boost QUIET)
    if(NOT Boost_FOUND)
        include(FetchContent)
        message(STATUS "Boost not found, downloading from git...")
        FetchContent_Declare(
            boost
            GIT_REPOSITORY https://github.com/boostorg/boost.git
            GIT_TAG        master
            GIT_PROGRESS   TRUE
        )
        # Fetch all submodules (Boost uses submodules for its libraries)
        set(FETCHCONTENT_QUIET OFF)
        FetchContent_GetProperties(boost)
        if(NOT boost_POPULATED)
            FetchContent_Populate(boost)
            execute_process(
                COMMAND git submodule update --init --recursive
                WORKING_DIRECTORY ${boost_SOURCE_DIR}
            )
        endif()
        # Add Boost include directory as INTERFACE target
        add_library(Boost::boost INTERFACE IMPORTED)
        set_target_properties(Boost::boost PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${boost_SOURCE_DIR}"
        )
    else()
        message(STATUS "Found system Boost: ${Boost_INCLUDE_DIRS}")
        if(NOT TARGET Boost::boost)
            add_library(Boost::boost INTERFACE IMPORTED)
            set_target_properties(Boost::boost PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES "${Boost_INCLUDE_DIRS}"
            )
        endif()
    endif()
    target_link_libraries(${target_name} INTERFACE Boost::boost)
endfunction()

# Include Eigen with target-specific flags
function(include_eigen target_name)
    # Try to find a system-installed Eigen3 first
    find_package(Eigen3 QUIET NO_MODULE)
    if(NOT Eigen3_FOUND)
        include(FetchContent)
        message(STATUS "Eigen3 not found, downloading from git...")
        FetchContent_Declare(
            eigen
            GIT_REPOSITORY https://gitlab.com/libeigen/eigen.git
            GIT_TAG        3.4.0
            GIT_PROGRESS   TRUE
        )
        FetchContent_MakeAvailable(eigen)
        # Eigen3Config.cmake is in eigen/cmake
        set(EIGEN3_INCLUDE_DIR "${eigen_SOURCE_DIR}")
        add_library(Eigen3::Eigen INTERFACE IMPORTED)
        set_target_properties(Eigen3::Eigen PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${EIGEN3_INCLUDE_DIR}"
        )
    else()
        message(STATUS "Found system Eigen3: ${Eigen3_DIR}")
    endif()
    target_link_libraries(${target_name} INTERFACE Eigen3::Eigen)
endfunction()

# Include Qt5 (Core, Gui, Widgets, OpenGL)
function(include_qt5 target_name)
    set(CMAKE_AUTOMOC ON)
    set(CMAKE_AUTORCC ON)
    set(CMAKE_AUTOUIC ON)

    find_package(Qt5 COMPONENTS Core Gui Widgets REQUIRED)
    find_package(Qt5OpenGL REQUIRED)

    target_link_libraries(${target_name} INTERFACE
        Qt5::Core
        Qt5::Gui
        Qt5::Widgets
        Qt5::OpenGL
    )
endfunction()

# Include OpenCV
function(include_open_cv target_name)
    find_package(OpenCV REQUIRED)
    target_include_directories(${target_name} INTERFACE ${OpenCV_INCLUDE_DIRS})
    target_link_libraries(${target_name} INTERFACE ${OpenCV_LIBS})
endfunction()

# Setup Catch2 and CTest for unit testing
function(setup_catch2_and_ctest)
    if(NOT BUILD_TESTING)
        message(STATUS "CTest is disabled, skipping Catch2 setup")
        return()
    endif()
    # Try to find a system-installed Catch2 first
    find_package(Catch2 3.4.0 QUIET)
    if(NOT Catch2_FOUND)
        include(FetchContent)
        message(STATUS "Catch2 not found, downloading from git...")
        FetchContent_Declare(
            Catch2
            GIT_REPOSITORY https://github.com/catchorg/Catch2.git
            GIT_TAG        v3.4.0
            GIT_PROGRESS   TRUE
        )
        FetchContent_MakeAvailable(Catch2)
    else()
        message(STATUS "Found system Catch2: ${Catch2_DIR}")
    endif()
    include(Catch)
    include(CTest)
    message(STATUS "Setup Catch2 complete")
endfunction()


# create a catch2 unit test executable like so: 
# add_catch_test(${CMAKE_CURRENT_SOURCE_DIR}/path_to_folder_containing_files_with_TEST_CASE lib1, lib2, lib3)
# lib1, lib2, lib3 are optional libraries to link private against the test executable
function(add_catch_test FOLDER)
# ARGN will contain all additional arguments passed after FOLDER
  if(NOT BUILD_TESTING)
    message(STATUS "CTest is disabled, skipping ${FOLDER} setup")
    return()
  endif()
  if (TARGET Catch2::Catch2WithMain)
    file(GLOB_RECURSE TEST_SOURCES "${FOLDER}/test_*.cpp")

    list(LENGTH TEST_SOURCES NUM_FILES)

    if(NUM_FILES GREATER 0)
        get_filename_component(BASENAME ${FOLDER} NAME)
        set(NAME test_${BASENAME})

        message(STATUS "Creating test executable ${NAME} with ${NUM_FILES} files")

        add_executable(${NAME} ${TEST_SOURCES})
        target_link_libraries(${NAME} PRIVATE Catch2::Catch2WithMain ${ARGN})
        catch_discover_tests(${NAME})
    else()
        message(WARNING "No test_*.cpp files found in folder ${FOLDER}")
    endif()
  endif()
endfunction()

# include guard for multiple includes of the same library cmake
function(manage_library lib_name version)
    # Get current LIB_LIST and LIB_LIST_VERSION
    if(NOT DEFINED LIB_LIST)
        set(LIB_LIST "")
    endif()
    if(NOT DEFINED LIB_LIST_VERSION)
        set(LIB_LIST_VERSION "")
    endif()

    # Check if lib_name is in LIB_LIST
    list(FIND LIB_LIST "${lib_name}" _lib_index)
    if(_lib_index EQUAL -1)
        # Not found, add lib_name and lib_name+version
        list(APPEND LIB_LIST "${lib_name}")
        list(APPEND LIB_LIST_VERSION "${lib_name}${version}")
        set(LIB_LIST "${LIB_LIST}" CACHE INTERNAL "Global library list")
        set(LIB_LIST_VERSION "${LIB_LIST_VERSION}" CACHE INTERNAL "Global library+version list")
        return()
    endif()

    # Check if lib_name+version is in LIB_LIST_VERSION
    list(FIND LIB_LIST_VERSION "${lib_name}${version}" _libver_index)
    if(_libver_index GREATER -1)
        set(ACCEPTED_LIB_VERSION "${version}" PARENT_SCOPE)
        return()
    endif()

    # Find any entry starting with lib_name in LIB_LIST_VERSION
    set(_found_version "")
    foreach(entry IN LISTS LIB_LIST_VERSION)
        string(REGEX MATCH "^${lib_name}(.+)$" _match "${entry}")
        if(_match)
            string(REGEX REPLACE "^${lib_name}" "" _found_version "${entry}")
            break()
        endif()
    endforeach()
    set(ACCEPTED_LIB_VERSION "${_found_version}" PARENT_SCOPE)
endfunction()

# Set fuzzer sanitizer flags based on FUZZ_MODE
function(set_fuzzer_sanitizer_flags FUZZ_MODE)
    string(TOUPPER "${FUZZ_MODE}" FUZZ_MODE_UPPER)

    if(FUZZ_MODE_UPPER STREQUAL "ADDRESS")
        set(FUZZER_SAN_FLAGS "address,undefined" PARENT_SCOPE)
    elseif(FUZZ_MODE_UPPER STREQUAL "THREAD")
        set(FUZZER_SAN_FLAGS "thread" PARENT_SCOPE)
    elseif(FUZZ_MODE_UPPER STREQUAL "MEMORY")
        set(FUZZER_SAN_FLAGS "memory" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Invalid FUZZ_MODE: ${FUZZ_MODE}. Supported modes: ADDRESS, THREAD, MEMORY")
    endif()
endfunction()

# Function: add_versioned_library 
# if BUILD_SHARED_LIBS is set, creates SHARED library, else STATIC
# if BUILD_FUZZERS is set, also creates OBJECT libraries for each fuzzer mode
# Args:
#   NAME          - name of the library
#   VERSION       - version of the library (e.g., 1.2.3)
#   SOURCES       - source files for the library
#   PUBLIC_HEADERS- public header files to install
#   LINK_PUBLIC   - libraries to link publicly
#   LINK_PRIVATE  - libraries to link privately
#   LINK_OPTIONS  - link options for the library
#   COMPILE_OPTIONS - compile options for the library
function(add_versioned_library NAME)
    set(options)
    set(oneValueArgs VERSION)
    set(multiValueArgs SOURCES PUBLIC_HEADERS LINK_PUBLIC LINK_PRIVATE LINK_OPTIONS COMPILE_OPTIONS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT ARG_VERSION)
        message(FATAL_ERROR "add_versioned_library requires VERSION")
    endif()

    # Determine library type based on BUILD_SHARED_LIBS
    set(LIB_TYPE STATIC)
    if(BUILD_SHARED_LIBS)
        set(LIB_TYPE SHARED)
    endif()

    # ------------------------------
    # Normal OBJECT library
    # ------------------------------
    add_library(${NAME}_obj OBJECT ${ARG_SOURCES})

    target_include_directories(${NAME}_obj
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:include>
    )

    target_link_libraries(${NAME}_obj
        PRIVATE ${ARG_LINK_PRIVATE}
    )

    if(ARG_LINK_OPTIONS)
        target_link_options(${NAME}_obj PRIVATE ${ARG_LINK_OPTIONS})
    endif()

    if(ARG_COMPILE_OPTIONS)
        target_compile_options(${NAME}_obj PRIVATE ${ARG_COMPILE_OPTIONS})
    endif()

    # ------------------------------
    # Packaged library
    # ------------------------------
    add_library(${NAME} $<TARGET_OBJECTS:${NAME}_obj>)
    add_library(${NAME}::${NAME} ALIAS ${NAME})

    set_target_properties(${NAME} PROPERTIES
        VERSION   ${ARG_VERSION}
    )

    target_link_libraries(${NAME}
        PUBLIC  ${ARG_LINK_PUBLIC}
    )

    if(ARG_LINK_OPTIONS)
        target_link_options(${NAME} PRIVATE ${ARG_LINK_OPTIONS})
    endif()

    if(ARG_COMPILE_OPTIONS)
        target_compile_options(${NAME} PRIVATE ${ARG_COMPILE_OPTIONS})
    endif()

    # ------------------------------
    # Install normal library + headers
    # ------------------------------
    install(TARGETS ${NAME}
        EXPORT ${NAME}Targets
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        RUNTIME DESTINATION bin
        INCLUDES DESTINATION include
    )

    install(DIRECTORY include/ DESTINATION include)

    install(EXPORT ${NAME}Targets
        NAMESPACE ${NAME}::
        DESTINATION lib/cmake/${NAME}
    )

    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${NAME}ConfigVersion.cmake
        VERSION ${ARG_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    configure_package_config_file(
        ${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${NAME}Config.cmake
        INSTALL_DESTINATION lib/cmake/${NAME}
    )

    install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${NAME}Config.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/${NAME}ConfigVersion.cmake
        DESTINATION lib/cmake/${NAME}
    )

    # ------------------------------
    # Fuzz OBJECT libraries
    # ------------------------------
    if(FUZZER_ENABLED)
        set(FUZZ_MODES address memory thread)
        foreach(MODE IN LISTS FUZZ_MODES)
            set_fuzzer_sanitizer_flags(${MODE})
            set(obj_name ${NAME}_obj_fuzz_${MODE})
            add_library(${obj_name} OBJECT ${ARG_SOURCES})

            target_include_directories(${obj_name} PUBLIC
                $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
            )

            target_link_libraries(${obj_name} 
                PRIVATE ${ARG_LINK_PRIVATE}
            )

            target_compile_options(${obj_name} PRIVATE
                -fsanitize=fuzzer-no-link,${FUZZER_SAN_FLAGS}
            )

            target_link_options(${obj_name} PRIVATE
                -fsanitize=fuzzer-no-link,${FUZZER_SAN_FLAGS}
            )

            if(ARG_COMPILE_OPTIONS)
                target_compile_options(${obj_name} PRIVATE ${ARG_COMPILE_OPTIONS})
            endif()

            if(ARG_LINK_OPTIONS)
                target_link_options(${obj_name} PRIVATE ${ARG_LINK_OPTIONS})
            endif()
        endforeach()
    endif()
endfunction()

# Function: add_versioned_header_only_library
# Args:
#   NAME          - name of the library
#   VERSION       - version of the library (e.g., 1.2.3)
#   PUBLIC_HEADERS- public header files to install
#   LINK_PUBLIC   - libraries to link publicly
#   LINK_PRIVATE  - libraries to link privately
function(add_versioned_header_only_library NAME)
    set(options)
    set(oneValueArgs VERSION)
    set(multiValueArgs PUBLIC_HEADERS LINK_PUBLIC LINK_PRIVATE)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT ARG_VERSION)
        message(FATAL_ERROR "add_versioned_header_only_library requires VERSION")
    endif()

    # ------------------------------
    # Create INTERFACE library
    # ------------------------------
    add_library(${NAME} INTERFACE)
    add_library(${NAME}::${NAME} ALIAS ${NAME})

    # Include directories
    target_include_directories(${NAME}
        INTERFACE
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:include>
    )

    # Link dependencies
    if(ARG_LINK_PUBLIC)
        target_link_libraries(${NAME} INTERFACE ${ARG_LINK_PUBLIC})
    endif()
    if(ARG_LINK_PRIVATE)
        target_link_libraries(${NAME} PRIVATE ${ARG_LINK_PRIVATE})
    endif()

    # Optionally add headers to IDE/target for convenience
    if(ARG_PUBLIC_HEADERS)
        target_sources(${NAME} INTERFACE ${ARG_PUBLIC_HEADERS})
    endif()

    # ------------------------------
    # Install headers + export target
    # ------------------------------
    install(TARGETS ${NAME}
        EXPORT ${NAME}Targets
        INCLUDES DESTINATION include
    )

    install(DIRECTORY include/ DESTINATION include)

    install(EXPORT ${NAME}Targets
        NAMESPACE ${NAME}::
        DESTINATION lib/cmake/${NAME}
    )

    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${NAME}ConfigVersion.cmake
        VERSION ${ARG_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    configure_package_config_file(
        ${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${NAME}Config.cmake
        INSTALL_DESTINATION lib/cmake/${NAME}
    )

    install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${NAME}Config.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/${NAME}ConfigVersion.cmake
        DESTINATION lib/cmake/${NAME}
    )
endfunction()

# Function: add_versioned_executable
# Args:
#   NAME          - name of the executable
#   SOURCES       - source files for the executable
#   LINK_PUBLIC   - libraries to link publicly
#   LINK_PRIVATE  - libraries to link privately
#   LINK_OPTIONS  - link options for the executable
#   COMPILE_OPTIONS - compile options for the executable
function(add_versioned_executable NAME)
    set(options)
    set(oneValueArgs VERSION)
    set(multiValueArgs SOURCES LINK_PUBLIC LINK_PRIVATE LINK_OPTIONS COMPILE_OPTIONS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR "add_versioned_executable requires SOURCES")
    endif()

    add_executable(${NAME} ALL ${ARG_SOURCES})

    target_link_libraries(${NAME}
        PRIVATE
            ${ARG_LINK_PRIVATE}
        PUBLIC
            ${ARG_LINK_PUBLIC}
    )

    if(ARG_COMPILE_OPTIONS)
        target_compile_options(${NAME} PRIVATE ${ARG_COMPILE_OPTIONS})
    endif()

    if(ARG_LINK_OPTIONS)
        target_link_options(${NAME} PRIVATE ${ARG_LINK_OPTIONS})
    endif()

    install(TARGETS ${NAME}
        RUNTIME DESTINATION bin
    )
endfunction()

# Function: add_versioned_fuzzer_executable
# Args:
#   NAME          - name of the fuzzer executable
#   SOURCES       - source files for the fuzzer executable
#   LINK_PRIVATE  - libraries to link privately
#   LINK_PRIVATE_INSTRUMENT  - libraries to link privately which are instrumented for fuzzing
#   LINK_OPTIONS  - link options for the fuzzer executable
#   COMPILE_OPTIONS - compile options for the fuzzer executable
function(add_versioned_fuzzer_executable NAME)
    if(NOT FUZZER_ENABLED)
        return()
    endif()

    set(options)
    set(oneValueArgs)
    set(multiValueArgs SOURCES LINK_PRIVATE LINK_PRIVATE_INSTRUMENT LINK_OPTIONS COMPILE_OPTIONS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR "add_versioned_fuzzer_executable requires SOURCES")
    endif()

    foreach(MODE IN ITEMS ADDRESS MEMORY THREAD)
        string(TOLOWER ${MODE} mode_lower)
        set_fuzzer_sanitizer_flags(${MODE})

        # fuzzer executable name
        set(EXE_NAME ${NAME}_fuzz_${mode_lower}_${CMAKE_BUILD_TYPE})

        # Convert LINK_PRIVATE_INSTRUMENT entries into their corresponding object libraries
        set(INSTRUMENT_OBJECTS "")
        foreach(LIB IN LISTS ARG_LINK_PRIVATE_INSTRUMENT)
            list(APPEND INSTRUMENT_OBJECTS $<TARGET_OBJECTS:${LIB}_obj_fuzz_${mode_lower}>)
        endforeach()

        # Add executable with sources + instrumented object libraries
        add_executable(${EXE_NAME} ALL ${ARG_SOURCES} ${INSTRUMENT_OBJECTS})

        # link normal private libraries
        if(ARG_LINK_PRIVATE)
            target_link_libraries(${EXE_NAME} PRIVATE ${ARG_LINK_PRIVATE})
        endif()

        # apply fuzzer instrumentation options
        target_compile_options(${EXE_NAME} PRIVATE -fsanitize=fuzzer,${FUZZER_SAN_FLAGS})
        target_link_options(${EXE_NAME} PRIVATE -fsanitize=fuzzer,${FUZZER_SAN_FLAGS})

        # additional user options
        if(ARG_COMPILE_OPTIONS)
            target_compile_options(${EXE_NAME} PRIVATE ${ARG_COMPILE_OPTIONS})
        endif()
        if(ARG_LINK_OPTIONS)
            target_link_options(${EXE_NAME} PRIVATE ${ARG_LINK_OPTIONS})
        endif()

        install(TARGETS ${EXE_NAME} RUNTIME DESTINATION bin)
    endforeach()
endfunction()
