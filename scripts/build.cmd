@echo off
setlocal enabledelayedexpansion
rem ============================================================================
rem  Minimal Windows build script (MSVC only)
rem  Mirrors build.sh but runs in native cmd environment
rem  Detects Visual Studio version and generator automatically
rem ============================================================================

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%"


rem --- Defaults ---
set CLEAN=0
set INSTALL=0
set BUILD_TYPE=
set ENABLE_TESTS=OFF
set RUN_TESTS=0
set TEST_OUTPUT_JUNIT=0
set USE_NINJA=0
set TARGET_ARCH=x64
set CMAKE_ARCH=x64
set SKIP_BUILD=0
set VERBOSE=0

set i=0
echo Received arguments:

rem --- Parse args ---
:parse
if "%~1"=="" goto parsed
set "ARG=%~1"

echo   Arg !i!: "%ARG%"
set /a i+=1

rem === Long options: start with "--" ===
if "%ARG:~0,2%"=="--" (
    if "%ARG%"=="--debug" (
        set BUILD_TYPE=Debug
    ) else if "%ARG%"=="--release" (
        set BUILD_TYPE=Release
    ) else if "%ARG%"=="--relwithdebinfo" (
        set BUILD_TYPE=RelWithDebInfo
    ) else if /I "%ARG:~0,7%"=="--arch=" (
        set "ARCHVAL=%ARG:~7%"
    ) else (
        echo ERROR: Unknown long argument %ARG%
        goto help
    )

    if defined ARCHVAL (
        if /I "!ARCHVAL!"=="x86"  set "ARCHVAL=Win32"
        if /I "!ARCHVAL!"=="Win32" (
            set TARGET_ARCH=x86
            set CMAKE_ARCH=Win32
        ) else if /I "!ARCHVAL!"=="x64" (
            set TARGET_ARCH=x64
            set CMAKE_ARCH=x64
        ) else (
            echo ERROR: Invalid architecture !ARCHVAL!
            goto help
        )
    )

) else if "%ARG:~0,1%"=="-" (
    rem === Short flags: start with "-" ===
    if "%ARG%"=="-c" (
        set CLEAN=1
    ) else if "%ARG%"=="-d" (
        set BUILD_TYPE=Debug
    ) else if "%ARG%"=="-r" (
        set BUILD_TYPE=Release
    ) else if "%ARG%"=="-o" (
        set BUILD_TYPE=RelWithDebInfo
    ) else if "%ARG%"=="-i" (
        set INSTALL=1
    ) else if "%ARG%"=="-s" (
        set SKIP_BUILD=1
    ) else if "%ARG%"=="-t" (
        set ENABLE_TESTS=ON
    ) else if "%ARG%"=="-T" (
        set RUN_TESTS=1
        set ENABLE_TESTS=ON
    ) else if "%ARG%"=="-n" (
        set USE_NINJA=1
    ) else if "%ARG%"=="-v" (
        set VERBOSE=1
    ) else (
        echo ERROR: Unknown short argument %ARG%
        goto help
    )

) else (
    echo ERROR: Unexpected argument %ARG%
    goto help
)

shift
goto parse
:parsed


if "%BUILD_TYPE%"=="" (
    echo Error: must specify -d, -r, or -o
    exit /b 6
)

rem --- Detect Visual Studio installation ---
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    echo ERROR: vswhere not found!
    exit /b 7
)

for /f "usebackq tokens=*" %%v in (`"%VSWHERE%" -latest -requires Microsoft.Component.MSBuild -property installationPath`) do set VS_PATH=%%v

if not defined VS_PATH (
    echo ERROR: Visual Studio not found!
    exit /b 8
)

rem --- Detect version (e.g. 2022, 2019) ---
for %%a in ("%VS_PATH%") do (
    if exist "%%a\Common7\Tools\VsDevCmd.bat" (
        set VS_DEV_CMD="%%a\Common7\Tools\VsDevCmd.bat"
    )
)
if not defined VS_DEV_CMD (
    echo ERROR: Could not find VsDevCmd.bat!
    exit /b 9
)

echo Initializing MSVC environment for %TARGET_ARCH%...
call "%VS_DEV_CMD:"=%" -arch=%TARGET_ARCH%

echo Using Visual Studio from: %VS_PATH%

rem --- Determine generator automatically ---
set "GENERATOR="
rem prefer ninja only if requested AND available
if "%USE_NINJA%"=="1" (
    where ninja >nul 2>nul
    if "%ERRORLEVEL%"=="0" (
        set "GENERATOR=Ninja"
    ) else (
        echo Warning: Ninja requested but not found; falling back to Visual Studio generator
    )
)

rem if generator still empty, pick a Visual Studio generator based on installed VS
if "%GENERATOR%"=="" (
    rem get VS installation version (installationVersion like 17.0.x)
    for /f "usebackq tokens=*" %%v in (`"%VSWHERE%" -latest -property installationVersion 2^>nul`) do set "VS_INSTALL_VERSION=%%v"
    if defined VS_INSTALL_VERSION (
        for /f "delims=. tokens=1" %%a in ("%VS_INSTALL_VERSION%") do set "VS_MAJOR=%%a"
    ) else (
        rem fallback: assume VS 2022 if vswhere didn't return version
        set "VS_MAJOR=17"
    )

    if "%VS_MAJOR%"=="17" (
        set "GENERATOR=Visual Studio 17 2022"
    ) else if "%VS_MAJOR%"=="16" (
        set "GENERATOR=Visual Studio 16 2019"
    ) else (
        echo Warning: Unknown Visual Studio major version %VS_MAJOR%, defaulting to Visual Studio 17 2022
        set "GENERATOR=Visual Studio 17 2022"
    )
)

rem Convert to lowercase using powershell
for /f %%i in ('powershell -command "$env:BUILD_TYPE.ToLower()"') do set BUILD_TYPE_LOWER=%%i

set "BUILD_DIR=build-msvc-%BUILD_TYPE_LOWER%-%TARGET_ARCH%"

if "%SKIP_BUILD%"=="1" (
    goto runtest
)

if "%CLEAN%"=="1" (
    echo Cleaning build directory: %BUILD_DIR%
    if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
cd "%BUILD_DIR%"

rem --- Configure CMake args depending on selected generator ---
set CMAKE_ARGS=-DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_TESTING=%ENABLE_TESTS% -G "%GENERATOR%"

rem For Visual Studio generators supply -A; for Ninja (when used with MSVC) do NOT pass -A
if /i not "%GENERATOR%"=="Ninja" (
    set CMAKE_ARGS=%CMAKE_ARGS% -A %CMAKE_ARCH%
)

echo working direktory: %BUILD_DIR%
echo Running: cmake %CMAKE_ARGS% ..
rem --- github runner bug, dont run cmake multiple times for extra arguments, because of race conditions
set CMAKE_NO_PARALLEL_GENERATOR=1
set TMP=%BUILD_DIR%\tmp
set TEMP=%BUILD_DIR%\tmp
if not exist "%TMP%" mkdir "%TMP%"
timeout /t 2 >nul
cmake --no-warn-unused-cli %CMAKE_ARGS% ..

if errorlevel 1 (
    echo ERROR: CMake configuration failed!
    exit /b 10
)

if "%VERBOSE%"=="1" (
    cmake -LAH ..
)

rem --- github runner race condition problems with running cmake again because why not...
timeout /t 2 >nul

rem --- Build ---
echo Building project...
if "%GENERATOR%"=="Ninja" (
    cmake --build . -- -j %NUMBER_OF_PROCESSORS%
) else (
    cmake --build . --config %BUILD_TYPE%
)
if errorlevel 1 exit /b 11

:runtest

rem --- Run tests ---
if "%RUN_TESTS%"=="1" (
    echo Running tests...
    if "%TEST_OUTPUT_JUNIT%"=="1" (
        ctest --output-on-failure --output-junit test_results.xml
    ) else (
        ctest --output-on-failure
    )
    if errorlevel 1 exit /b 12
)

rem --- Install if requested ---
if "%INSTALL%"=="1" (
    cmake --install . --config %BUILD_TYPE%
)

echo Build completed successfully.
exit /b 0

:help
rem --- Help ---
echo Usage: build.bat [options]
echo Options:
echo   -c              Clean build
echo   -d              Debug build
echo   -r              Release build
echo   -s              Skip build
echo   -o              RelWithDebInfo build
echo   -t              Enable tests
echo   -T              Run tests
echo   -i              Install after build
echo   -n              Use Ninja generator if available
echo   --arch=ARCH     Target architecture (x86 or x64)
echo   -v              Verbose (dump CMake vars)
exit /b 1