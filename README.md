Dear stranger 
If I write "you" I mean me. Though you might use this repo too, it is mostly for me to manage my projects (for example to enforce them to have the same structure)

Due to the structure of the repository its tests are in a seperate [test repository](https://github.com/Jakobimatrix/initRepoTest) using this repo as a subrepository

Works for Linux:
[![C/C++ CI](https://github.com/Jakobimatrix/initRepoTest/actions/workflows/ubuntu_build_test.yml/badge.svg)](https://github.com/Jakobimatrix/initRepoTest/actions/workflows/ubuntu_build_test.yml)

Works for Windows:
[![Windows C/C++ CI](https://github.com/Jakobimatrix/initRepoTest/actions/workflows/windows_build_test.yml/badge.svg)](https://github.com/Jakobimatrix/initRepoTest/actions/workflows/windows_build_test.yml)

# initRepo 

This repo helps when createing a new project in cpp20. It provides a solid structure and enforces some rules.
After creating a new  project add this repo as a submodule (or copy it)
Than run ./initRepo/scripts/init.sh. This copies the base structur installes helpfull tools and provides a Template for the CMakeLists.txt.

All is optional! Read what the script says.

## Installments
- clang-tidy
- clang-format
- cppcheck
- valgrind
- shellcheck

### Git hook for clang format
To enforce clang-format inside a repository for c, cpp, cxx, h, hpp files.
The init.sh installes clang-format on the local machine and a git-hook for the specified repository to check the format before every commit.
Look inside **format_hook** for the enforced clang-version

Now every time you commit a file not meeting the clang-format rules you will be asked to format properly.
**This only applies to YOUR_REPOSITORY (local).**

btw. Your IDE probably is able to enforce clang-format upon saving too.

**USE ONLY FOR NEW REPOSITORIES! OTHERWISE YOU BREAK GIT BLAME**

further reading:

[githook-clang-format](https://github.com/andrewseidl/githook-clang-format)

### LF
In case you are working on Linux and windof you probably want to enforce LF line endings


## Provided structure COPIED with init.sh
This gives you a good starting point for your project. Some files are supposed to be changed by you or even renamed!

```
├── build.sh                            --> Run this to make/build/install You probably want to change things in the script.  
├── CMakeLists.txt                      --> Already includes some cmake functions and the project structore   
└── src                                 --> Contains all neded for making executables  
    ├── executables                     --> Here go all main() functions which become executables  
    │   ├── CMakeLists.txt              --> Contains CMake how to build and install the examples  
    │   └── src                         --> Here goes your code  
    │       ├── fuzzer_example.cpp      --> Example for fuzzy testing  
    │       └── hello_world.cpp         --> Example for an executable
    ├── libary                          --> Example libary for putting in your functions. Please rename!  
    │   ├── CMakeLists.txt              --> Contains CMake how to make the static library  
    │   ├── include                     --> Header files go in include  
    │   │   └── library                 --> Foldername equals library name to enforce #include <library/file.hpp>  Please rename!  
    │   │       └── math.hpp            --> Header file for your library declarations.  
    │   └── src                         --> Source files go in include  
    │         └── math.cpp              --> Header file for your library definitions.  
    └── tests                           --> Example unit tests [Catch2](https://github.com/catchorg/Catch2) for your functions.  
        ├── CMakeLists.txt              --> Contains CMake how to build the tests.  
        └── src                         --> Source files go in include  
            └── hello_world_test.cpp    --> Contains the unit tests.  
```

## Provided CMake functions 
The root CMakeLists.txt which is copied will include some helper functions. These are managed by the repo "initRepo"
If change is needed, update the repo. All projects should be based on the same rules especially thouse which include other projects.
```
initRepo
├── cmake
│   ├── ClangFuzzyTests.cmake           --> if Option FUZZER_ENABLED is set, link the project against clang fuzzer
│   ├── CompilerSetup.cmake             --> sets c++ standard 20, defines release/debug modes, enables LTO if ENABLE_LTO is set
│   ├── CMakeGraphVizOptions.cmake      --> Options for graphviz, used for Documentation / Dependencey graph
│   ├── CompilerWarnings.cmake          --> All warnings are errors (except some exceptions)
│   ├── Includes.cmake                  --> optional includes for third party libraries
│   └── Options.cmake                   --> helps with shared libraries and mutlti threading
```

## Provided Scripts
The scripts make your life better. Simmilar to the cmake scripts these shall not be copied but managed by the initRepo and called from there.
You may add your own .environment in the root of your repository to overwrite paths and versions.
```
initRepo
├── scripts
│   ├── build.sh               --> helps to build your project
│   ├── checkClangFormat.sh    --> checks if clang format rules are followed
│   ├── checkClangTidy.sh      --> checks if clang tidy rules are followed
│   ├── checkDoxygenHeader.sh  --> checks if a given file starts with a doxygen header.
│   ├── checkFileHeaders.sh    --> checks if each cpp/hpp/h file starts with a doxygen header.
│   ├── checkShellCheck.sh     --> checks if shellcheck rules are followed (for bash)
│   ├── createDokumentation.sh --> runns Doxygen
│   ├── ensureToolVersion.sh   --> helper for build.sh (checks if a tool is installed in the expected version)
│   ├── init.sh                --> used to install files and project struckture in your new repository
│   ├── installCompiler.sh     --> used to install compilers
│   ├── runFuzzer.sh           --> used to run the fuzzy tests
│   ├── showCoverage.sh        --> runs gcc tests in debug mode and prints the coverage
│   ├── update.sh              --> update the subrepository and scripts

```

## CI / CD
Two simple CI / CD pipeline for github is included.
 - One runns on Windows, one on Linux.
 - the Linux runner uses the check*.sh scripts to ensure rules.
 - both build the project with clang and gcc (Windows also with msvc) 32 Bit and 64 Bit in debug and release mode
 - It runns all available ctests for all compilers and modes.

 ## .environment
 There is a .environment inside the initRepo root folder dictating compiler paths, versions etc.
 To overwrite one or more variables just create your own .environment in your repository root.

## Usage
1. `git clone YOUR_REPOSITORY`  // clone your new empty repository
2. `cd YOUR_REPOSITORY`
3. `git submodule add https://github.com/Jakobimatrix/initRepo.git`  // @stranger OR COPY if you dont want submodules, but it needs to be at the root of your repo
4. `chmod +x initRepo/scripts/init.sh`
5. `./initRepo/scripts/init.sh`  // answer the questions (with yes if you want the feature)
6. In case you answered yes for the ci cd pipeline, the sample project structure and the cmake file, after you commit, the CI / CD pipeline should automatically run (green)
7. you can copy initRepo/.environment into your root and change the settings.
6. To update scripts: `./initRepo/scripts/update.sh`

   

## Fuzzing

The fuzzer helps to automatically find bugs by executing your code with a large number of generated and mutated inputs.
This project uses **Clang libFuzzer**, optionally combined with sanitizers, to detect memory errors, undefined behavior, and logic bugs.

---

### Precondition

A minimal example fuzzer can be found here:

```
src/executables/src/fuzzer_example.cpp
```

The fuzzer entry point is implemented via:

```cpp
extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size);
```

This function is called repeatedly by libFuzzer with different inputs.

---

It links against **BuildSettings_FUZZER** which is an umbrella target.
All other libraries which get linked against the fuzzer should themself link against **BuildSettings_LIB** which is also an umbrella target:

```cmake
set(FUZZ_MODE "ADDRESS" CACHE STRING "Choose fuzzing sanitizer mode: ADDRESS, THREAD, MEMORY")
if(FUZZ_MODE STREQUAL "ADDRESS")
    # Enable fuzzing with address sanitizer and undefined behavior sanitizer
    set(FUZZER_SAN_FLAGS address,undefined)
elseif(FUZZ_MODE STREQUAL "THREAD")
    # Enable fuzzing with thread sanitizer for race condition detection
    set(FUZZER_SAN_FLAGS thread)
elseif(FUZZ_MODE STREQUAL "MEMORY")
    # Enable fuzzing with memory sanitizer for uninitialized memory detection
    set(FUZZER_SAN_FLAGS memory)
else()
    message(FATAL_ERROR "Invalid FUZZ_MODE: ${FUZZ_MODE}. Choose BASIC, SAFE, THREAD, MEMORY.")
endif()

if(FUZZER_ENABLED)
    # Apply all targets against sanitizer flag for full fuzzing instrumentation (without main function)
    target_link_options(BuildSettings_LIB INTERFACE -fsanitize=fuzzer-no-link,${FUZZER_SAN_FLAGS})
    target_compile_options(BuildSettings_LIB INTERFACE -fsanitize=fuzzer-no-link,${FUZZER_SAN_FLAGS})
    
    # Apply fuzzer sanitizer flags for full fuzzing instrumentation (fsanitize will provide the main function)
    target_compile_options(BuildSettings_FUZZER INTERFACE -fsanitize=fuzzer,${FUZZER_SAN_FLAGS})
    target_link_options(BuildSettings_FUZZER INTERFACE -fsanitize=fuzzer,${FUZZER_SAN_FLAGS})
endif()
```


### Build

Use the provided `build.sh` script.

Important flags:

* `-f`
  Enables the fuzzer build configuration (libFuzzer + sanitizers)

* `--compiler clang`
  Required, since libFuzzer is a Clang tool

* `-d` or `-o`
  Selects the optimization level:

  * `-d` → Debug-like build using **`-O1 -g`**
  * `-o` → RelWithDebInfo using **`-O2 -g`**

Example:

```bash
./build.sh -f --compiler clang -d
```

or

```bash
./build.sh -f --compiler clang -o
```

**Note:**
Pure Debug builds (`-O0`) are intentionally rejected for fuzzing, because libFuzzer and sanitizers rely on compiler optimizations to work correctly. Release builds (`-O3`) are also discouraged for fuzzing, because aggressive optimizations can remove code paths, inline away checks, and reduce coverage quality, making bugs harder to detect and debugging more difficult.

---

### Optimization levels and bug classes

Different optimization levels expose **different classes of bugs**.
`-O2` does **not** strictly supersede `-O1`.

| Bug class / behavior                      | -O1 | -O2 |
| ----------------------------------------- | :-: | :-: |
| Heap use-after-free                       | Yes | Yes |
| Stack out-of-bounds                       | Yes | Yes |
| Null dereference                          | Yes | Partial* |
| Missing bounds checks                     | Yes | No* |
| Undefined behavior (general)              | Yes | Yes |
| Lifetime / aliasing bugs                  | No  | Yes |
| Bugs caused by optimizer assumptions (UB) | No  | Yes |
| Code paths removed by optimization        | No  | Yes |
| Coverage quality / fuzzing guidance       | Yes | Partial |

* Some checks or code paths may be optimized away at `-O2`, making certain bugs harder or impossible to trigger.
* Both modes are complementary and should be used together for best results.

---

### Running the fuzzer

`scripts/runFuzzer.sh <executable> [-c corpus_dir] [-j jobs] [-m] [--max_len N] [-h]`

### Reproducing crashes

#### 1. Qt Creator

1. **Add your fuzzer binary as a run configuration**

   * Go to **Projects → Run → Add Kit / Custom Executable**
   * Set the **executable path** to `fuzzer_binary`

2. **Set command-line arguments**

   * Add your crash file as an argument:

     ```
     crash-<hash>
     ```
   * Optionally add libFuzzer flags:

     ```
     -runs=1 -handle_segv=0
     ```

3. **Debug**

   * Click the debug button. Qt Creator will launch the fuzzer under its debugger.
   * When the crash happens, you can inspect the call stack, variables, and step through `LLVMFuzzerTestOneInput`.

---

#### 2. Visual Studio Code (with C++ extension / launch.json)

1. **Open `launch.json`** (Ctrl+Shift+D → create a launch config)

2. **Add a configuration** like:

```json
{
    "name": "Debug Fuzzer Crash",
    "type": "cppdbg",
    "request": "launch",
    "program": "${workspaceFolder}/build/fuzzer_binary",
    "args": ["crash-<hash>", "-runs=1", "-handle_segv=0"],
    "stopAtEntry": false,
    "cwd": "${workspaceFolder}",
    "environment": [],
    "externalConsole": false,
    "MIMode": "gdb",
    "miDebuggerPath": "/usr/bin/gdb"
}
```

3. **Launch the debugger**

   * Select your configuration
   * Click **Start Debugging** (F5)
   * When the crash occurs, the debugger stops exactly at the crash point.

---

#### Notes / Best Practices

* Always use `-runs=1` when reproducing a crash, otherwise libFuzzer will loop endlessly.
* Use `-handle_segv=0 -handle_abort=0` so that the debugger catches signals immediately.
* Ensure the fuzzer binary is compiled with `-g` and **O1** or **O2** (not O0 or O3 for fuzzing).
* You can step through `LLVMFuzzerTestOneInput` as a normal function; the crash will appear there.
