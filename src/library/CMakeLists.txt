add_library(library_lib STATIC
  src/library/math.cpp
  include/library/math.hpp
  )

#target_link_libraries(library_lib
#    other_lib)

target_include_directories(library_lib PUBLIC STATIC "${CMAKE_CURRENT_SOURCE_DIR}/include")
