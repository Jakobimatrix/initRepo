
if (FUZZER_ENABLED)

add_library(fuzzer_lib STATIC
  src/fuzzer_lib/example_file.cpp
  include/fuzzer_lib/example_file.hpp
  )

#target_link_libraries(library_lib
#    other_lib)

target_include_directories(fuzzer_lib PUBLIC STATIC "${CMAKE_CURRENT_SOURCE_DIR}/include")

endif ()
