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

### Build

Use the provided `build.sh` script.

Important flags:
* `-h`
  help
* `-t`
  build tests
* `-T`
  run tests
* `-i`
  install all targets

* `--compiler clang`
  default is gcc

* `-d` or `-o` or `-r`
  Selects the optimization level:

  * `-d` → Debug-like build using **`-O0 -g`**
  * `-o` → RelWithDebInfo using **`-O2 -g`**
  * `-r` → Release using **`-O3`**

Example:

```bash
./build.sh -t --compiler clang -d
```

---
You can also use the provided CMakePresets.json but you probably need to change the compiler paths!

`cmake --preset <preset name>`
`cmake --build --preset <preset name>`
`ctest --preset <preset name>`
`cmake --install --preset <preset name>`

---

## Fuzzing

The fuzzer helps automatically find bugs by executing your code with a large number of generated and mutated inputs.
This project uses **Clang libFuzzer**

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

**Note:**
Pure Debug builds (`-O0`) are intentionally rejected for fuzzing, because libFuzzer and sanitizers rely on compiler optimizations to work correctly. Release builds (`-O3`) are  discouraged for fuzzing, because aggressive optimizations can remove code paths, inline away checks, and reduce coverage quality, making bugs harder to detect and debugging more difficult.

**Important:**
Each fuzzer target now produces **three executables** (`_fuzz_address`, `_fuzz_memory`, `_fuzz_thread`) for the same source.
This increases compile time roughly **3×**, so plan your CI/build accordingly.

---

### Fuzzer types and coverage

| Fuzzer executable       | Detects / Bugs / Errors                                                                |
| ----------------------- | -------------------------------------------------------------------------------------- |
| `<target>_fuzz_address` | Heap use-after-free, stack out-of-bounds, null dereference, general undefined behavior |
| `<target>_fuzz_memory`  | Uninitialized reads, memory leaks, buffer misuse |
| `<target>_fuzz_thread`  | Data races, thread-safety violations, race-condition-induced UB |
| `<target>_fuzz_addressOXDebug` | for debugging crashes created by `<target>_fuzz_address` |
| `<target>_fuzz_memoryOXDebug` | for debugging crashes created by `<target>_fuzz_memory` |
| `<target>_fuzz_threadOXDebug` | for debugging crashes created by `<target>_fuzz_thread` |
| `<target>_fuzz_coverage` | feed it the corpus to create coverage reports (.profraw) |

* **Address**: combines AddressSanitizer + UndefinedBehaviorSanitizer
* **Memory**: MemorySanitizer detects uninitialized memory access and leaks
* **Thread**: ThreadSanitizer detects concurrent memory access issues

---

### Optimization levels and bug classes

Different optimization levels expose **different classes of bugs**. `-O2` does **not** strictly supersede `-O1`.

| Bug class / behavior                      | -O1 |    -O2   |
| ----------------------------------------- | :-: | :------: |
| Heap use-after-free                       | Yes |    Yes   |
| Stack out-of-bounds                       | Yes |    Yes   |
| Null dereference                          | Yes | Partial* |
| Missing bounds checks                     | Yes |    No*   |
| Undefined behavior (general)              | Yes |    Yes   |
| Lifetime / aliasing bugs                  |  No |    Yes   |
| Bugs caused by optimizer assumptions (UB) |  No |    Yes   |
| Code paths removed by optimization        |  No |    Yes   |
| Coverage quality / fuzzing guidance       | Yes |  Partial |

* Some checks or code paths may be optimized away at `-O2`, making certain bugs harder or impossible to trigger.
* Both modes are complementary and should be used together for best results.

---

| Fuzzer executable       | -O1  | -O2 |
| `<target>_fuzz_address` | Heap use-after-free, Stack out-of-bounds, Null dereference, Undefined behavior, Coverage guidance | Heap use-after-free, Stack out-of-bounds, Partial null dereference, Undefined behavior, Lifetime/aliasing bugs, Optimizer UB assumptions, Code paths removed, Partial coverage guidance |
| `<target>_fuzz_memory`  | Uninitialized reads, Memory leaks, Buffer misuse | Uninitialized reads, Memory leaks, Partial buffer misuse |
| `<target>_fuzz_thread`  | Data races, Thread-safety violations, Race-condition-induced UB | Data races, Thread-safety violations, Partial race-condition-induced |

---

### Running the fuzzer

`scripts/runFuzzer.sh <executable> [-c corpus_dir] [-j jobs] [-m] [--max_len N] [-h]`

* Run the **specific fuzzer variant** depending on the bug type you want to target
* `_fuzz_address` → general memory and UB
* `_fuzz_memory` → uninitialized memory, leaks
* `_fuzz_thread` → concurrency bugs

---

### Reproducing crashes


* Run the .*_fuzz_.*_Debug version of the fuzzer with the arguments `-d path/to/crash`
* Process waits for User input (enter)  --> Attach debugger to running process, then press enter.
* The debugger should stop where the bug manifests.


---

**Notes / Best Practices**

* Always use `-runs=1` when reproducing a crash.
* Use `-handle_segv=0 -handle_abort=0` so that the debugger catches signals immediately.
* Ensure the fuzzer binary is compiled with `-g` and **O1** or **O2** (not O0 or O3).
* Remember that **each fuzzer target builds three executables**, increasing compile time.
* You can step through `LLVMFuzzerTestOneInput` as a normal function; the crash will appear there.
