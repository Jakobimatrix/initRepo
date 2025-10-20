setlocal enabledelayedexpansion
rem ============================================================================
rem  Minimal Windows build script (MSVC only)
rem  Mirrors build.sh but runs in native cmd environment
rem  Detects Visual Studio version and generator automatically
rem ============================================================================

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%"

rem --- Defaults ---
set CLEAN=0
set INSTALL=0
set BUILD_TYPE=
set ENABLE_TESTS=OFF
set RUN_TESTS=0
set TEST_OUTPUT_JUNIT=0
set USE_NINJA=0
set TARGET_ARCH_BITS=x64
set SKIP_BUILD=0
set VERBOSE=0

rem --- Help ---
if "%~1"=="" (
    echo Usage: build.bat [options]
    echo Options:
    echo   -c              Clean build
    echo   -d              Debug build
    echo   -r              Release build
    echo   -o              RelWithDebInfo build
    echo   -t              Enable tests
    echo   -T              Run tests
    echo   -i              Install after build
    echo   -n              Use Ninja generator if available
    echo   --arch ARCH     Target architecture (x86 or x64)
    echo   -v              Verbose (dump CMake vars)
    exit /b 1
)

rem --- Parse args ---
:parse
if "%~1"=="" goto parsed
if "%~1"=="-c" set CLEAN=1
if "%~1"=="-d" set BUILD_TYPE=Debug
if "%~1"=="--debug" set BUILD_TYPE=Debug
if "%~1"=="-r" set BUILD_TYPE=Release
if "%~1"=="--release" set BUILD_TYPE=Release
if "%~1"=="-o" set BUILD_TYPE=RelWithDebInfo
if "%~1"=="--relwithdebinfo" set BUILD_TYPE=RelWithDebInfo
if "%~1"=="-i" set INSTALL=1
if "%~1"=="-t" set ENABLE_TESTS=ON
if "%~1"=="-T" (
    set RUN_TESTS=1
    set ENABLE_TESTS=ON
)
if "%~1"=="-n" set USE_NINJA=1
if "%~1"=="-v" set VERBOSE=1
if "%~1"=="--arch" (
    shift
    set TARGET_ARCH_BITS=%~1
)
shift
goto parse
:parsed

if "%BUILD_TYPE%"=="" (
    echo Error: must specify -d, -r, or -o
    exit /b 1
)

rem --- Detect Visual Studio installation ---
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    echo ERROR: vswhere not found!
    exit /b 1
)

for /f "usebackq tokens=*" %%v in (`"%VSWHERE%" -latest -requires Microsoft.Component.MSBuild -property installationPath`) do set VS_PATH=%%v

if not defined VS_PATH (
    echo ERROR: Visual Studio not found!
    exit /b 1
)

rem --- Detect version (e.g. 2022, 2019) ---
for %%a in ("%VS_PATH%") do (
    if exist "%%a\Common7\Tools\VsDevCmd.bat" (
        set VS_DEV_CMD="%%a\Common7\Tools\VsDevCmd.bat"
    )
)
if not defined VS_DEV_CMD (
    echo ERROR: Could not find VsDevCmd.bat!
    exit /b 1
)

call %VS_DEV_CMD% -arch=%TARGET_ARCH_BITS% >nul
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

set "BUILD_DIR=build-msvc-%BUILD_TYPE%-%TARGET_ARCH_BITS%"
if "%CLEAN%"=="1" (
    echo Cleaning build directory: %BUILD_DIR%
    if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
cd "%BUILD_DIR%"

rem --- Configure CMake args depending on selected generator ---
set "CMAKE_ARGS=-DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_TESTING=%ENABLE_TESTS% -G \"%GENERATOR%\""

rem For Visual Studio generators supply -A; for Ninja (when used with MSVC) do NOT pass -A
if /i not "%GENERATOR%"=="Ninja" (
    set "CMAKE_ARGS=%CMAKE_ARGS% -A %TARGET_ARCH_BITS%"
)

echo working direktory: %BUILD_DIR%
echo Running: cmake %CMAKE_ARGS% ..
cmake %CMAKE_ARGS% ..

if errorlevel 1 (
    echo ERROR: CMake configuration failed!
    exit /b 1
)

if "%VERBOSE%"=="1" (
    cmake -LAH ..
)

rem --- Build ---
echo Building project...
if "%GENERATOR%"=="Ninja" (
    cmake --build . -- -j %NUMBER_OF_PROCESSORS%
) else (
    cmake --build . --config %BUILD_TYPE%
)
if errorlevel 1 exit /b 1

rem --- Run tests ---
if "%RUN_TESTS%"=="1" (
    echo Running tests...
    if "%TEST_OUTPUT_JUNIT%"=="1" (
        ctest --output-on-failure --output-junit test_results.xml
    ) else (
        ctest --output-on-failure
    )
    if errorlevel 1 exit /b 1
)

rem --- Install if requested ---
if "%INSTALL%"=="1" (
    cmake --install . --config %BUILD_TYPE%
)

echo Build completed successfully.
exit /b 0
