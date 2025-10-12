@echo off
setlocal EnableDelayedExpansion

:: Change to repository root
pushd %~dp0..\..

:: Source environment
if exist initRepo\.windows_environment.cmd call initRepo\.windows_environment.cmd
if exist .windows_environment.cmd call .windows_environment.cmd

:: Default values
set "CLEAN="
set "BUILD_TYPE="
set "ENABLE_TESTS=OFF"
set "COMPILER=%DEFAULT_COMPILER%"
set "RUN_TESTS="
set "TEST_OUTPUT_JUNIT="
set "SKIP_BUILD="
set "ARCH=x64"
set "USE_NINJA="

:parse_args
if "%~1"=="" goto :main
if "%~1"=="-c" set "CLEAN=1"
if "%~1"=="-d" set "BUILD_TYPE=Debug"
if "%~1"=="--debug" set "BUILD_TYPE=Debug"
if "%~1"=="-r" set "BUILD_TYPE=Release"
if "%~1"=="--release" set "BUILD_TYPE=Release"
if "%~1"=="-o" set "BUILD_TYPE=RelWithDebInfo"
if "%~1"=="--compiler" (
    set "COMPILER=%~2"
    shift
)
if "%~1"=="--arch" (
    set "ARCH=%~2"
    shift
)
if "%~1"=="-t" set "ENABLE_TESTS=ON"
if "%~1"=="-T" (
    set "RUN_TESTS=1"
    set "ENABLE_TESTS=ON"
)
if "%~1"=="-J" set "TEST_OUTPUT_JUNIT=1"
if "%~1"=="-s" set "SKIP_BUILD=1"
if "%~1"=="-N" set "USE_NINJA=1"
if "%~1"=="--ninja" set "USE_NINJA=1"
shift
goto :parse_args

:main
if "%BUILD_TYPE%"=="" (
    echo Error: Build type must be specified
    goto :show_help
)

set "BUILD_DIR=build-%COMPILER%-%ARCH%-%BUILD_TYPE%"

if not "%SKIP_BUILD%"=="1" (
    if "%CLEAN%"=="1" (
        echo Cleaning build directory: %BUILD_DIR%
        if exist "%BUILD_DIR%" rd /s /q "%BUILD_DIR%"
    )

    if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
    cd "%BUILD_DIR%"

    :: Configure based on compiler
    if "%COMPILER%"=="msvc" (
        cmake -G "Visual Studio 17 2022" -A %ARCH% -DBUILD_TESTING=%ENABLE_TESTS% ..
    ) else (
        if "%USE_NINJA%"=="1" (
            where ninja >nul 2>&1
            if !errorlevel! equ 0 (
                cmake -G "Ninja" -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_TESTING=%ENABLE_TESTS% ..
            ) else (
                echo Warning: Ninja not found, falling back to MinGW Makefiles
                cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_TESTING=%ENABLE_TESTS% ..
            )
        ) else (
            cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_TESTING=%ENABLE_TESTS% ..
        )
    )

    cmake --build . --config %BUILD_TYPE%
) else (
    cd "%BUILD_DIR%"
)

if "%RUN_TESTS%"=="1" (
    if "%TEST_OUTPUT_JUNIT%"=="1" (
        ctest -C %BUILD_TYPE% --output-on-failure --output-junit test_results.xml
    ) else (
        ctest -C %BUILD_TYPE% --output-on-failure
    )
)

popd
exit /b 0

:show_help
echo Usage: build.cmd [options]
echo Options:
echo   -c              Clean build
echo   -d              Debug build
echo   --debug         Debug build
echo   -r              Release build
echo   --release       Release build
echo   -o              RelWithDebInfo build
echo   --compiler COMP Use specific compiler (gcc, clang, msvc)
echo   --arch ARCH     Architecture (x86, x64)
echo   -t              Build tests
echo   -T              Run Tests after build
echo   -J              Test output returns junit
echo   -N, --ninja     Use Ninja generator if available
echo   -s              Skip cmake and build
exit /b 1
