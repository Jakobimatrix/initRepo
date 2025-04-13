
# CHANGE THE NAME OF THE LIBRARY AND THE VERSION and the variable holding the version!

if(TARGET library_lib)
      message(WARNING "library_lib has already been included.")
      message(WARNING "The current version being included is ${LIBARY_LIB_VERSION}.")
else()

    set(UTILS_LIB_VERSION "0.0.1")

    add_library(library_lib_${UTILS_LIB_VERSION} STATIC
      include/library/math.hpp
      src/math.cpp
      )

    target_link_libraries(library_lib_${UTILS_LIB_VERSION}
      PRIVATE
      ${ENVIRONMENT_SETTINGS}
      )

    target_include_directories(library_lib_${UTILS_LIB_VERSION} PUBLIC STATIC "${CMAKE_CURRENT_SOURCE_DIR}/include")

endif()
