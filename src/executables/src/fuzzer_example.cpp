/**
 * @file fuzzer_example.cpp
 * @brief contains an minimal example how to fuzz a function.
 *
 * @detail The Fuzzer creates a more or less (less it does some clever things) random binary string and tries to kill your application.
 *         1) Build in release mode with clang
 *         2) Run ./fuzzer_example -print_final_stats=1
 *         3) After it ended a crash-<md5hash> binary file was created containing the input that crashed the application
 *         4) Create a Debug executable (or unit test) that can read the crash-<md5hash> and call badFunction in debug mode to analyze the crash.
 **/

#include <cstdio>

namespace {

/**
 * @brief This bad function is delibritly wrong.
 * If the given data is of size 3 and equals "FUZ" we have an access violation.
 *
 * @param data Pointer to data begin.
 * @param size Size of the Data.
 * @return true if the input starts with "FUZZ".
 */

// This bad example would be caught by the static analyser, so lets cheat a
// little NOLINTBEGIN(cppcoreguidelines-pro-bounds-pointer-arithmetic)
inline bool badFunction(const unsigned char* data, size_t size) {
  if (size >= 3) {
    if (data[0] == 'F') {
      if (data[1] == 'U') {
        if (data[2] == 'Z') {
          if (data[3] == 'Z') {
            return true;
          }
        }
      }
    }
  }
  return false;
}
// NOLINTEND(cppcoreguidelines-pro-bounds-pointer-arithmetic)


}  // end anonymous namespace


extern "C" int LLVMFuzzerTestOneInput(const unsigned char* data, unsigned long size) {

  return static_cast<int>(badFunction(data, static_cast<size_t>(size)));
}
