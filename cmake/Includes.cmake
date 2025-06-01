# Include Eigen with target-specific flags
function(include_eigen target_name)
    find_package(Eigen3 3.3 REQUIRED NO_MODULE)

    set(EIGEN_COMPILE_FLAGS
        -march=native
        -mfpmath=sse
        -mms-bitfields       # Optional: mainly for mingw32, known bug with epoll on 32bit
        -fno-strict-aliasing
    )

    target_compile_options(${target_name} INTERFACE ${EIGEN_COMPILE_FLAGS})
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
    if (NOT FUZZER_ENABLED)
        include(FetchContent)
        FetchContent_Declare(
            Catch2
            GIT_REPOSITORY https://github.com/catchorg/Catch2.git
            GIT_TAG        v3.4.0
        )
        FetchContent_MakeAvailable(Catch2)
        enable_testing()
        include(Catch)
        include(CTest)
    endif()
endfunction()
