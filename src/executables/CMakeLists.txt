

if (FUZZER_ENABLED)

  add_executable(fuzzer_example src/fuzzer_example.cpp)

  target_link_libraries(fuzzer_example 
    PRIVATE 
    fuzzer_lib_my_project_0.0.1
    ${ENVIRONMENT_SETTINGS}
  )

else()
  # only enable other executables (like tests), if Fuzzer is not linked. Fuzzer brings its own main!
    
  add_executable(hello_world src/hello_world.cpp)

  # Optionally, you can also install the executable
  install(TARGETS hello_world DESTINATION bin)

  target_link_libraries(hello_world 
    PRIVATE 
    ${ENVIRONMENT_SETTINGS}
  ) 


endif()

