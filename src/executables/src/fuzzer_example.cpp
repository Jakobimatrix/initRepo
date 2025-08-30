/**
 * @file fuzzer_example.cpp
 * @brief contains an nearly minimal example how to fuzz a function.
 *
 * @detail The Fuzzer creates a more or less (less it does some clever things) random binary string and tries to kill your application.
 *         1) Build in release mode with clang
 *         2) Run ./fuzzer_example -print_final_stats=1
 *         3) After it ended a crash-<md5hash> binary file was created containing the input that crashed the application
 *         4) Build in debug mode
 *         5) Run ./fuzzer_example crash-<md5hash> and attach the debugger, than hit enter
 *
 * Fuzz your own function:
 *         1) Copy paste this file, and add a CMake entrie for the new executable
 *         2) Replace the contents of badFunction with a call to your function.
 *         3) If you have to create your own classes from the binary input. I highly suggest making a serializer/deserializer for your class.
 *
 * @date 30.03.2025
 * @author Jakob Wandel
 * @version 1.0
 **/

#include <concepts>
#include <cstdint>
#include <cstdio>
#include <exception>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <type_traits>
#include <vector>

// Concept must be outside the anonymous namespace for C++20

template <typename ByteType>
concept ByteTypeAllowed =
  !std::is_const_v<ByteType> &&
  (std::same_as<ByteType, char> || std::same_as<ByteType, unsigned char> ||
   std::same_as<ByteType, signed char> || std::same_as<ByteType, std::uint8_t>);

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

/**
 * @brief Reads a binary file into a vector of bytes.
 *
 * @tparam ByteType Must be either char, unsigned char, or std::uint8_t.
 * @param path Path to the file.
 * @return std::vector<uint8_t> Contents of the file.
 * @throws std::runtime_error if the file can't be opened.
 */

template <ByteTypeAllowed ByteType>
std::vector<ByteType> readFileBinary(const std::filesystem::path& path) {
  std::ifstream file(path, std::ios::binary | std::ios::ate);
  if (!file) {
    throw std::runtime_error("Failed to open file: " + path.string());
  }

  const std::streamsize size = file.tellg();
  file.seekg(0, std::ios::beg);

  std::vector<ByteType> buffer(static_cast<size_t>(size));
  if constexpr (std::is_same<char, ByteType>()) {
    if (!file.read(buffer.data(), size)) {
      throw std::runtime_error("Failed to read file: " + path.string());
    }
  } else {
    if (!file.read(reinterpret_cast<char*>(buffer.data()), size)) {  // NOLINT(cppcoreguidelines-pro-type-reinterpret-cast)
      // reinterpret_cast is required: std::ifstream::read takes char*,
      // and buffer.data() may be uint8_t* / unsigned char*, etc. This cast is safe and idiomatic.
      throw std::runtime_error("Failed to read file: " + path.string());
    }
  }

  return buffer;
}

}  // end anonymous namespace


#if FUZZER_ACTIVE
// we compiled in release mode, The fuzzer can do its magic


extern "C" int LLVMFuzzerTestOneInput(const unsigned char* data, unsigned long size) {

  return static_cast<int>(badFunction(data, static_cast<size_t>(size)));
}


#else
// We compiled in debug mode, you can call badFunction yourself with the data which crashed badFunction and see what went wrong

int main(int argc, char* argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0]  // NOLINT(cppcoreguidelines-pro-bounds-pointer-arithmetic) Thats how its done unfortunately
              << " <file_path>\n";
    return 1;
  }

  const std::filesystem::path file_path(argv[1]);  // NOLINT(cppcoreguidelines-pro-bounds-pointer-arithmetic) Thats how its done unfortunately

  if (!std::filesystem::exists(file_path)) {
    std::cerr << "File does not exist: " << file_path << "\n";
    return 1;
  }

  try {
    auto data = readFileBinary<unsigned char>(file_path);
    std::cerr
      << "\nFile found and read. Now attach debugger and press enter.\n";
    std::cerr
      << "If you get an error from ptrace 'Could not attach to the process.' "
      << "Use 'echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope' to relax "
      << "restrictions temporarily.\n";
    getchar();
    return static_cast<int>(badFunction(data.data(), data.size()));
  } catch (const std::exception& e) {
    std::cerr << "Error: " << e.what() << "\n";
    return 1;
  }

  return 0;
}


#endif
