

if (FUZZER_ENABLED)

  generate_fuzzer_name("fuzzer_example" FUZZER_EXE_NAME)
  add_executable(FUZZER_EXE_NAME src/fuzzer_example.cpp)

  target_link_libraries(FUZZER_EXE_NAME 
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
