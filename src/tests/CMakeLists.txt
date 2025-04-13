

Include(FetchContent)

FetchContent_Declare(
  Catch2
  GIT_REPOSITORY https://github.com/catchorg/Catch2.git
  GIT_TAG        v3.4.0 # or a later release
)

FetchContent_MakeAvailable(Catch2)

enable_testing()

add_executable(test_hello_world src/test_hello_world.cpp)

target_link_libraries(test_hello_world 
  PRIVATE
  Catch2::Catch2WithMain
  library_lib_0.0.1
  ${ENVIRONMENT_SETTINGS}
  )

include(CTest)
include(Catch)

catch_discover_tests(test_hello_world)


