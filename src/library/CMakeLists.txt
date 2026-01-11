#add_versioned_library(time
#    VERSION 
#      1.2.0
#    SOURCES 
#      src/time.cpp
#    PUBLIC_HEADERS i
#      include/time/templated_header.hpp
#    LINK_PUBLIC 
#      lib_1
#      lib_2
#    LINK_PRIVATE  
#      lib_3
#      lib_4
#    LINK_OPTIONS
#      -option1
#      -option2
#    COMPILE_OPTIONS
#      -option3
#      -option4
#)

#add_versioned_header_only_library(my_header_lib
#    VERSION 1.0.0
#    PUBLIC_HEADERS
#        include/my_header_lib/foo.hpp
#        include/my_header_lib/bar.hpp
#    LINK_PUBLIC utils_lib
#    LINK_PRIVATE BuildSettings_LIB
#)

add_versioned_library(library_name 
  VERSION 
    0.0.1
  SOURCES
    src/math.cpp
  LINK_PRIVATE
    BuildSettings_LIB
)
