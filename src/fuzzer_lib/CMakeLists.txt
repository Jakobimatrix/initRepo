
if (FUZZER_ENABLED)

add_library(fuzzer_lib STATIC
  include/fuzzer_lib/example_file.hpp
  src/example_file.cpp
  )

target_link_libraries(fuzzer_lib
  PRIVATE 
  ${ENVIRONMENT_SETTINGS}
  )

target_include_directories(fuzzer_lib PUBLIC STATIC "${CMAKE_CURRENT_SOURCE_DIR}/include")

endif ()
