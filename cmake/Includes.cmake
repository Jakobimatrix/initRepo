# Include Eigen with target-specific flags
function(include_eigen target_name)
    find_package(Eigen3 3.3 REQUIRED NO_MODULE)

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

function(setup_catch2_and_ctest)
    include(FetchContent)
    FetchContent_Declare(
        Catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG        v3.4.0
    )
    FetchContent_MakeAvailable(Catch2)
    include(Catch)
    include(CTest)
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