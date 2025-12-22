# Library name and version
set(LIB_VERSION "0.0.1")
set(LIB_NAME "library_lib")

add_library(${LIB_NAME}_${LIB_VERSION} STATIC
  include/library/math.hpp
  src/math.cpp
)

target_link_libraries(${LIB_NAME}_${LIB_VERSION}
  PRIVATE
  BuildSettings_LIB
)

target_include_directories(${LIB_NAME}_${LIB_VERSION} PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)