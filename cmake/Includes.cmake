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
# add_catch_test(${CMAKE_CURRENT_SOURCE_DIR}/path_to_folder_containing_files_with_TEST_CASE lib1, lib2, lib3, ${ENVIRONMENT_SETTINGS})
function(add_catch_test FOLDER)
# ARGN will contain all additional arguments passed after FOLDER
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
