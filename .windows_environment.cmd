@echo off

:: Compiler versions
set "GCC_VERSION=13"
set "CLANG_VERSION=19"
set "MSVC_VERSION=2022"

:: MinGW paths
set "MINGW_GCC_BASE=C:\msys64\mingw64\bin"
set "MINGW_32_GCC_BASE=C:\msys64\mingw32\bin"

:: MSVC paths
set "MSVC_BASE=C:\Program Files\Microsoft Visual Studio\%MSVC_VERSION%\Community\VC\Tools\MSVC"
set "MSVC_BASE_X86=C:\Program Files (x86)\Microsoft Visual Studio\%MSVC_VERSION%\Community\VC\Tools\MSVC"

:: Compiler paths
set "GCC_CPP_PATH=%MINGW_GCC_BASE%\g++.exe"
set "GCC_C_PATH=%MINGW_GCC_BASE%\gcc.exe"
set "GCC_32_CPP_PATH=%MINGW_32_GCC_BASE%\g++.exe"
set "GCC_32_C_PATH=%MINGW_32_GCC_BASE%\gcc.exe"

set "CLANG_CPP_PATH=%MINGW_GCC_BASE%\clang++.exe"
set "CLANG_C_PATH=%MINGW_GCC_BASE%\clang.exe"
set "CLANG_32_CPP_PATH=%MINGW_32_GCC_BASE%\clang++.exe"
set "CLANG_32_C_PATH=%MINGW_32_GCC_BASE%\clang.exe"

:: Default compiler
set "DEFAULT_COMPILER=msvc"
