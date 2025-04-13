
add_executable(hello_world src/hello_world.cpp)

# Optionally, you can also install the executable
install(TARGETS hello_world DESTINATION bin)

target_link_libraries(hello_world 
    PRIVATE 
    ${ENVIRONMENT_SETTINGS}
    ) 

if (FUZZER_ENABLED)

add_executable(fuzzer_example src/fuzzer_example.cpp)

target_link_libraries(fuzzer_example 
    PRIVATE 
    fuzzer_lib
    ${ENVIRONMENT_SETTINGS}
    )

endif()
