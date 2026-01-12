#add_versioned_executable(time_tool
#    VERSION 
#      1.2.0
#    SOURCES 
#      src/normal_exe.cpp
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


add_versioned_executable(hello_world
    SOURCES 
      src/hello_world.cpp
    LINK_PRIVATE
      library_name
      BuildSettings_EXE
)

#add_versioned_fuzzer_executable(time_tool
#    SOURCES 
#      src/fuzzer_example.cpp
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

add_versioned_fuzzer_executable(example
    SOURCES
      src/fuzzer_example.cpp
    LINK_PRIVATE 
      BuildSettings_FUZZER
    LINK_PRIVATE_INSTRUMENT
      library_name
)

