option(ENABLE_FUZZING "Enable fuzzing support" OFF)
set(FUZZER_ENABLED OFF)

if (ENABLE_FUZZING AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_definitions(${PROJECT_NAME} PUBLIC FUZZER_ACTIVE)
    set(FUZZER_ENABLED ON)

    message(STATUS "Fuzzing enabled for target: ${PROJECT_NAME}")

    set(FUZZER_SAN_FLAGS
        -fsanitize=fuzzer,address
        -Wno-unused-command-line-argument
        -fprofile-instr-generate
        -fcoverage-mapping
        -fprofile-arcs
        -ftest-coverage
    )

    target_compile_definitions(${PROJECT_NAME} PUBLIC FUZZER_ACTIVE)
    target_compile_options(${PROJECT_NAME} PUBLIC ${FUZZER_SAN_FLAGS})
    target_link_options(${PROJECT_NAME} PUBLIC ${FUZZER_SAN_FLAGS})
endif ()
