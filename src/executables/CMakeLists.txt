

if (FUZZER_ENABLED)
  add_executable(fuzzer_example src/fuzzer_example.cpp)

  target_link_libraries(fuzzer_example 
    PRIVATE 
    BuildSettings_FUZZER
  )
endif()

add_executable(hello_world src/hello_world.cpp)

install(TARGETS hello_world DESTINATION bin)

target_link_libraries(hello_world 
  PRIVATE 
  library_lib_0.0.1
  BuildSettings_EXE
) 
