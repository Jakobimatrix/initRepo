Dear stranger 
If I write "you" I mean me. Though you might use this repo too, it is mostly for me to manage my projects (for example to enforce them to have the same structure)

# initRepo

This repo helps when createing a new project in cpp20. It provides a solid structure and enforces some rules.
After creating a new  project add this repo as a submodule (or copy it)
Than run ./ init.sh This copies the base structur installes helpfull tools and provides a Template for the CMakeLists.txt.

All is optional!

## Installments
- clang-tidy
- clang-format
- cppcheck
- valgrind

## Git hook
To enforce clang-tidy inside a repository for c, cpp, cxx, h, hpp files.
The init.sh installes clang-tidy on the local machine and a git-hook for the specified repository to check the format before every commit.
Look inside **format_hook** for the enforced clang-version

Now every time you commit a file not meeting the clang-format rules you will be asked to format properly.
**This only applies to YOUR_REPOSITORY (local).**

btw. Your IDE probably is able to enforce clang-format upon saving too.

**USE ONLY FOR NEW REPOSITORIES! OTHERWISE YOU BREAK GIT BLAME**

further reading:
[How-to-use-Clang-Tidy-to-automatically-correct-code](https://github.com/KratosMultiphysics/Kratos/wiki/How-to-use-Clang-Tidy-to-automatically-correct-code)

[githook-clang-format](https://github.com/andrewseidl/githook-clang-format)

## LF
In case you are working on Linux And windof you probably want to enforce LF lineendings

## Provided structure COPIED
This gives you a good starting point for your project. Some files are supposed to be changed by you or even renamed!

├── build.sh                            --> Run this to make/build/install You probably want to change things in the script.
├── CMakeLists.txt                      --> Already includes some cmake functions and the project structore 
└── src                                 --> Contains all neded for making executables
    ├── executables                     --> Here go all main() functions which become executables
    │   ├── CMakeLists.txt              --> Contains CMake how to build and install the examples
    │   └── src                         --> Here goes your code
    │       ├── fuzzer_example.cpp      --> Example for fuzzy testing
    │       └── hello_world.cpp         --> Example for an executable
    ├── fuzzer_lib                      --> Libary for putting in helper functions for the fuzzer
    │   ├── CMakeLists.txt              --> Contains CMake how to make the static library for the fuzzer
    │   ├── include                     --> Header files go in include
    │   │   └── fuzzer_lib              --> Foldername equals library name to enforce #include <library_name/file.hpp>
    │   │       └── example_file.hpp    --> Empty header file for library declarations.
    │   └── src                         --> Source files go in include
    │       └── fuzzer_lib              --> Foldername equals library name to mirror include folder
    │           └── example_file.cpp    --> Empty source file for library definitions.
    ├── libary                          --> Example libary for putting in your functions. Please rename!
    │   ├── CMakeLists.txt              --> Contains CMake how to make the static library
    │   ├── include                     --> Header files go in include
    │   │   └── library                 --> Foldername equals library name to enforce #include <library/file.hpp>  Please rename!
    │   │       └── math.hpp            --> Header file for your library declarations.
    │   └── src                         --> Source files go in include
    │       └── library                 --> Foldername equals library name to mirror include folder.  Please rename!
    │           └── math.cpp            --> Header file for your library definitions.
    └── tests                           --> Example unit tests [Catch2](https://github.com/catchorg/Catch2) for your functions.
        ├── CMakeLists.txt              --> Contains CMake how to build the tests.
        └── src                         --> Source files go in include
            └── hello_world_test.cpp    --> Contains the unit tests.

## Provided CMake functions 
The root CMakeLists.txt which is copied will include some helper functions. These are managed by the repo "InitRepo"
If change is needed, update the repo. All projects should be based on the same rules especially thouse which include other projects.

InitRepo
├── cmake
│   ├── ClangFuzzyTests.cmake           --> if Option ENABLE_FUZZING is set, link the project against clang fuzzer
│   ├── CompilerSetup.cmake             --> sets c++ standard 20, defines release/debug modes, enables LTO if ENABLE_LTO is set
│   ├── CompilerWarnings.cmake          --> All warnings are errors (except some exceptions)
│   ├── Includes.cmake                  --> optional includes for third party libraries
│   └── Options.cmake                   --> helps with shared libraries and mutlti threading


## Usage
1. `git clone YOUR_REPOSITORY`
2. `cd YOUR_REPOSITORY`
3. `git submodule add https://github.com/Jakobimatrix/initRepo.git`  // @stranger OR COPY if you dont want submodules
4. `cd initRepo`
4. `chmod +x initRepo/init.sh`
5. `sudo ./initRepo/init.sh ../`

   
