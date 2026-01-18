/*===- StandaloneFuzzTargetMain.c - standalone main() for fuzz targets. ---===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
// This main() function can be linked to a fuzz target (i.e. a library
// that exports LLVMFuzzerTestOneInput() and possibly LLVMFuzzerInitialize())
// instead of libFuzzer. This main() function will not perform any fuzzing
// but will simply feed all input files one by one to the fuzz target.
//
// Use this file to provide reproducers for bugs when linking against libFuzzer
// or other fuzzing engine is undesirable.
//===----------------------------------------------------------------------===*/
// This is a modified version that makes clang tidy and my compiler happy.
// Also it prints the results. With the Option -d the process waits until
// you press enter which allowes you to attach a debugger.
//===----------------------------------------------------------------------===*/

#include <cstddef>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

#if defined(_WIN32)
#define FUZZ_PLATFORM_WINDOWS
#include <windows.h>
#include <cstring>
#elif defined(__linux__)
#define FUZZ_PLATFORM_LINUX
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#else
#error Unsupported platform
#endif

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size);
extern "C" int LLVMFuzzerInitialize(int* argc, char*** argv) __attribute__((weak));

namespace {
auto read_file(const std::string& path)
  -> std::pair<std::vector<std::uint8_t>, std::error_code> {
  std::ifstream file(path, std::ios::binary | std::ios::ate);
  if (!file) {
    return {{}, std::make_error_code(std::errc::no_such_file_or_directory)};
  }

  const std::ifstream::pos_type file_size = file.tellg();
  if (file_size < 0) {
    return {{}, std::make_error_code(std::errc::io_error)};
  }

  std::vector<std::uint8_t> buffer(static_cast<std::size_t>(file_size));
  file.seekg(0, std::ios::beg);

  if (!file.read(reinterpret_cast<char*>(buffer.data()),
                 static_cast<std::streamsize>(buffer.size()))) {
    return {{}, std::make_error_code(std::errc::io_error)};
  }
  return {std::move(buffer), {}};
}

enum class RunResult { ok, rejected, crashed, undefined };

#if defined(FUZZ_PLATFORM_LINUX)
auto run_isolated(const std::vector<std::uint8_t>& data) -> RunResult {
  const pid_t pid = fork();
  if (pid < 0) {
    return RunResult::crashed;
  }

  if (pid == 0) {
    const int result = LLVMFuzzerTestOneInput(data.data(), data.size());
    _exit(result);
  }

  int status = 0;
  if (waitpid(pid, &status, 0) < 0) {
    return RunResult::crashed;
  }

  if (WIFEXITED(status)) {
    const int code = WEXITSTATUS(status);
    if (code == 0) {
      return RunResult::ok;
    }
    if (code == 255)  // -1 truncated
    {
      return RunResult::rejected;
    }
    return RunResult::undefined;
  }

  if (WIFSIGNALED(status)) {
    return RunResult::crashed;
  }

  return RunResult::undefined;
}
#endif

#if defined(FUZZ_PLATFORM_WINDOWS)
constexpr unsigned int EXIT_OK        = 0;
constexpr unsigned int EXIT_REJECTED  = 1;
constexpr unsigned int EXIT_UNDEFINED = 2;

auto run_child(const char* input_path) -> int {
  const auto [data, error] = read_file(input_path);
  if (error) {
    return EXIT_UNDEFINED;
  }

  const int result = LLVMFuzzerTestOneInput(data.data(), data.size());

  if (result == 0) {
    return EXIT_OK;
  }
  if (result == -1) {
    return EXIT_REJECTED;
  }

  return EXIT_UNDEFINED;
}

auto run_isolated(const std::wstring& exe_path, const std::wstring& input_path) -> RunResult {
  std::wstring command =
    L"\"" + exe_path + L"\" --fuzz-child \"" + input_path + L"\"";

  STARTUPINFOW startup_info{};
  startup_info.cb = sizeof(startup_info);

  PROCESS_INFORMATION process_info{};

  if (CreateProcessW(
        nullptr, command.data(), nullptr, nullptr, FALSE, CREATE_NO_WINDOW, nullptr, nullptr, &startup_info, &process_info) ==
      FALSE) {
    return RunResult::crashed;
  }

  WaitForSingleObject(process_info.hProcess, INFINITE);

  DWORD exit_code = 0;
  if (GetExitCodeProcess(process_info.hProcess, &exit_code) == FALSE) {
    exit_code = EXIT_UNDEFINED;
  }

  CloseHandle(process_info.hThread);
  CloseHandle(process_info.hProcess);

  if (exit_code == EXIT_OK) {
    return RunResult::ok;
  }
  if (exit_code == EXIT_REJECTED) {
    return RunResult::rejected;
  }

  return RunResult::crashed;
}
#endif
}  // namespace


auto main(int argc, char** argv) -> int {
  bool waitDebugger = false;
  int write_index   = 1;

  for (int read_index = 1; read_index < argc; ++read_index) {
    if (std::string_view{argv[read_index]} == "-d") {
      waitDebugger = true;
      continue;
    }
    argv[write_index] = argv[read_index];
    ++write_index;
  }
  argc = write_index;

  if (waitDebugger) {
    std::cerr << "\nNow attach debugger and press enter.\n";
#if defined(FUZZ_PLATFORM_LINUX)
    std::cerr
      << "If you get an error from ptrace 'Could not attach to the process.' "
         "Use 'echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope' to relax "
         "restrictions temporarily.\n"
      << std::flush;
#endif
    getchar();
  }

#if defined(FUZZ_PLATFORM_WINDOWS)
  // ---- child mode ----
  if (argc == 3 && std::string_view{argv[1]} == "--fuzz-child") {
    return run_child(argv[2]);
  }
#endif

  if (LLVMFuzzerInitialize != nullptr) {
    LLVMFuzzerInitialize(&argc, &argv);
  }

  std::size_t parsed   = 0;
  std::size_t ok       = 0;
  std::size_t rejected = 0;
  std::size_t crashed  = 0;

  std::vector<std::string> crash_list;

#if defined(FUZZ_PLATFORM_WINDOWS)
  wchar_t exe_path[MAX_PATH]{};
  GetModuleFileNameW(nullptr, exe_path, MAX_PATH);
#endif

  for (int i = 1; i < argc; ++i) {
    const std::string input_path{argv[i]};
    ++parsed;

    const auto [data, error] = read_file(input_path);
    if (error) {
      std::cerr << "Read error (" << input_path << "): " << error.message() << '\n';
      continue;
    }

#if defined(FUZZ_PLATFORM_LINUX)
    const RunResult result = run_isolated(data);
#elif defined(FUZZ_PLATFORM_WINDOWS)
    const std::wstring w_input{input_path.begin(), input_path.end()};
    const RunResult result = run_isolated(exe_path, w_input);
#endif

    switch (result) {
      case RunResult::ok:
        ++ok;
        break;

      case RunResult::rejected:
        ++rejected;
        break;

      case RunResult::crashed:
        ++crashed;
        crash_list.push_back(input_path);
        std::cerr << "Crash detected: " << input_path << '\n';
        break;

      case RunResult::undefined:
        std::cerr << "Undefined fuzzer result: " << input_path << '\n';
        break;
    }
  }

  std::cerr << "\nSummary:\n";
  std::cerr << parsed << " Files parsed\n";
  std::cerr << ok << " Files OK\n";
  std::cerr << rejected << " Files Rejected\n";
  std::cerr << crashed << " Files crashed\n";

  if (!crash_list.empty()) {
    std::cerr << "-- crashes:\n";
    for (const auto& name : crash_list) {
      std::cerr << "- " << name << '\n';
    }
  }

  return 0;
}