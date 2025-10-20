# .windowsEnvironmentHelper
# This file defines helper functions for windows


##
# @brief Delete a file safely across platforms.
# @param $1 The file path to delete.
#
# Handles MSYS2, Cygwin, Git-Bash, and POSIX environments.
#
deleteFile() {
    local file="$1"
    if [[ -z "$file" || ! -e "$file" ]]; then
        return 0
    fi

    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Convert to Windows path for native deletion
        local winpath
        winpath=$(cygpath -w "$file" 2>/dev/null)
        if [[ -n "$winpath" ]]; then
            del /f /q "$winpath" >/dev/null 2>&1 || true
            return
        fi
    fi

    # Fallback for Linux, macOS, WSL, etc.
    rm -f "$file" >/dev/null 2>&1 || true
}

##
# @brief Create a temporary file safely across environments.
# @param $1 Optional suffix (e.g. ".ps1")
# @return The temp file path (echoed)
#
makeTempFile() {
    local suffix="${1:-}"
    local tmp

    if command -v mktemp >/dev/null 2>&1; then
        if [[ -n "$suffix" ]]; then
            tmp=$(mktemp 2>/dev/null || echo "/tmp/tmp.$$") || tmp="/tmp/tmp.$$"
            mv "$tmp" "${tmp}${suffix}" 2>/dev/null && tmp="${tmp}${suffix}"
        else
            tmp=$(mktemp 2>/dev/null || echo "/tmp/tmp.$$")
        fi
    else
        tmp="/tmp/tmp.$$${suffix}"
    fi

    # Normalize to POSIX path (avoid C:\...) for bash tools
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        tmp=$(cygpath -u "$tmp" 2>/dev/null || echo "$tmp")
    fi

    echo "$tmp"
}

##
# @brief Run PowerShell or pwsh depending on platform.
# @param $@ Command and arguments.
#
runPowerShell() {
    echo "[DEBUG] Running PowerShell command with args: $*"
    local result=0
    if command -v powershell.exe >/dev/null 2>&1; then
        echo "[DEBUG] Using powershell.exe"
        powershell.exe "$@"
        result=$?
    elif command -v powershell >/dev/null 2>&1; then
        echo "[DEBUG] Using powershell"
        powershell "$@"
        result=$?
    elif command -v pwsh >/dev/null 2>&1; then
        echo "[DEBUG] Using pwsh"
        pwsh "$@"
        result=$?
    else
        echo "Error: No PowerShell executable found." >&2
        return 1
    fi
    echo "[DEBUG] PowerShell command exit code: $result"
    return $result
}

##
# @brief Convert path to Windows format and ensure proper quoting
# @param $1 The path to convert
# @return The converted path
#
convertPath() {
    local path="$1"
    # First, convert to Windows path if cygpath is available
    if command -v cygpath >/dev/null 2>&1; then
        path=$(cygpath -w "$path" 2>/dev/null || echo "$path")
    else
        # Manual conversion if cygpath not available
        path="${path//\//\\}"  # Replace forward slashes with backslashes
        # Add drive letter if missing
        if [[ "$path" =~ ^\\[^\\] ]]; then
            path="C:$path"
        fi
    fi
    # Ensure proper quoting if path contains spaces
    if [[ "$path" == *" "* ]]; then
        path="\"$path\""
    fi
    echo "$path"
}

##
# @brief Run cmd.exe commands safely across environments.
# @param $@ Command and arguments.
#
runCmd() {
    echo "[DEBUG] Running CMD command with args: $*"
    local result=0
    if command -v cmd.exe >/dev/null 2>&1; then
        echo "[DEBUG] Using cmd.exe"
        # /D disables AutoRun, /C executes command and terminates
        cmd.exe /D /C "$@"
        result=$?
    else
        echo "Error: cmd.exe not found." >&2
        return 1
    fi
    echo "[DEBUG] CMD command exit code: $result"
    return $result
}

##
# @brief Windows-native implementation of grep-like functionality
# @param $1 Pattern to search for
# @param $2 Input string (optional, if not provided reads from stdin)
windows_grep() {
    local pattern="$1"
    local input="$2"
    
    if [[ -n "$input" ]]; then
        echo "$input" | runCmd "findstr /R /C:\"$pattern\"" 2>/dev/null || true
    else
        runCmd "findstr /R /C:\"$pattern\"" 2>/dev/null || true
    fi
}

##
# @brief Windows-native implementation of tail-like functionality
# @param $1 Number of lines (optional, defaults to 1)
# @param $2 Input string (optional, if not provided reads from stdin)
windows_tail() {
    local lines="${1:-1}"
    local input="$2"

    # PowerShell script to get last N lines
    local ps_script='Get-Content -Tail '"$lines"

    if [[ -n "$input" ]]; then
        echo "$input" | runPowerShell -Command "$ps_script" 2>/dev/null || echo "$input"
    else
        # If no input is provided, use PowerShell or fall back to cat
        runPowerShell -Command "$ps_script" 2>/dev/null || cat
    fi
}

##
# @brief Windows-native implementation of tr-like functionality for simple character replacements.
#        Only supports single character replacement, not full tr semantics (e.g., no character sets or ranges).
# @param $1 Character to replace
# @param $2 Replacement character
# @param $3 Input string (optional, if not provided reads from stdin)
windows_tr() {
    local from="$1"
    local to="$2"
    local input="$3"
    
    # For non-Windows systems, use native tr command
    if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
        if [[ -n "$input" ]]; then
            echo "$input" | tr "$from" "$to"
        else
            tr "$from" "$to"
        fi
        return
    fi

    # PowerShell script to replace characters
    local ps_script='
        $input = [Console]::In.ReadToEnd()
        $input.Replace("'"$from"'", "'"$to"'")'

    if [[ -n "$input" ]]; then
        echo "$input" | runPowerShell -Command "$ps_script" 2>/dev/null
    else
        runPowerShell -Command "$ps_script" 2>/dev/null || echo ""
    fi
}


##
# @brief Alternative VS environment setup using cmd.exe
# @param $1 Architecture ("x86" or "x64")
#
setup_msvc_env_cmd() {
    local arch_bits="$1"
    local vs_base tmpfile result=0
    
    echo "[DEBUG] Starting MSVC environment setup via CMD for architecture: $arch_bits"
    
    # Find VS installation using vswhere from the default location
    local vswhere_exe="/c/ProgramData/Chocolatey/bin/vswhere.exe"
    echo "[DEBUG] Running vswhere from: $vswhere_exe"
    
    # Run vswhere directly since we know its location
    local vswhere_out
    vswhere_out=$("$vswhere_exe" -latest -products '*' -requires Microsoft.Component.MSBuild -property installationPath)
    echo "[DEBUG] Raw vswhere output:"
    echo "$vswhere_out"
    
    # Clean up the output - remove debug lines and convert to clean path
    vs_base=$(echo "$vswhere_out" | grep -v '^\[DEBUG\]' | grep -v '^Microsoft Windows' | grep -v '^(c)' | tr -d '\r' | tail -n 1)
    echo "[DEBUG] Extracted VS path: $vs_base"
    
    if [[ -z "$vs_base" ]]; then
        echo "Error: Could not find Visual Studio installation"
        return 1
    fi
    
    # Clean up the path and convert to proper format
    vs_base="${vs_base//\"/}"  # Remove any quotes
    vs_base="${vs_base//\\/\/}"  # Convert backslashes to forward slashes
    echo "[DEBUG] Cleaned VS path: $vs_base"
    
    # Create temporary file for environment capture
    tmpfile=$(makeTempFile ".bat")
    
    # Create a batch file that will:
    # 1. Call VsDevCmd.bat
    # 2. Echo environment variables we care about
    local vs_cmd_path
    vs_cmd_path=$(convertPath "${vs_base}/Common7/Tools/VsDevCmd.bat")
    echo "[DEBUG] VS Command path: $vs_cmd_path"
    
    # Create batch file content with explicit paths for VS tools
    cat > "$tmpfile" <<BATCH
@echo off
set VS_PATH=$vs_cmd_path
echo [BATCH] Setting up Visual Studio environment...
echo [BATCH] Using: %VS_PATH%
call "%VS_PATH%" -arch=$arch_bits -no_logo
if errorlevel 1 (
echo [BATCH] Error: VsDevCmd.bat failed
exit /b 1
)

REM Add VS tools to PATH
set "PATH=%VS_BASE%\Common7\IDE;%VS_BASE%\VC\Tools\MSVC\14.29.30133\bin\Host%VSCMD_ARG_HOST_ARCH%\%VSCMD_ARG_TGT_ARCH%;%PATH%"

echo [BATCH] Environment setup complete, dumping variables:
echo PATH=%PATH%
echo INCLUDE=%INCLUDE%
echo LIB=%LIB%
echo LIBPATH=%LIBPATH%
BATCH
    
    echo "[DEBUG] Created temporary batch file: $tmpfile"
    echo "[DEBUG] Batch file contents:"
    cat "$tmpfile"
    
    # Execute batch file and capture output
    local envfile
    envfile=$(makeTempFile ".env")
    echo "[DEBUG] Running batch file: $(cygpath -w "$tmpfile")"
    runCmd "$(cygpath -w "$tmpfile")" > "$envfile" 2>&1
    result=$?
    
    if [[ $result -ne 0 ]]; then
        echo "[ERROR] Batch file execution failed with code $result"
        echo "[DEBUG] Batch file output:"
        cat "$envfile"
        deleteFile "$tmpfile"
        deleteFile "$envfile"
        return 1
    fi
    
    echo "[DEBUG] Environment setup exit code: $result"
    echo "[DEBUG] Raw environment output:"
    cat "$envfile"
    
    # Parse and export environment variables
    echo "[DEBUG] Processing environment variables..."
    while IFS='=' read -r line; do
        # Skip empty lines and debug output
        [[ -z "$line" || "$line" == \[*\]* ]] && continue
        
        name="${line%%=*}"
        value="${line#*=}"
        
        case "$name" in
            PATH|INCLUDE|LIB|LIBPATH)
                if [[ "$name" == "PATH" ]]; then
                    # Keep Windows paths as-is, just ensure proper separators
                    value="${value//\\//}"
                    # Add VS paths explicitly in case they weren't added
                    vstools="$vs_base/VC/Tools/MSVC/14.29.30133/bin/Hostx64/x86"
                    [[ ":$value:" != *":$vstools:"* ]] && value="$vstools:$value"
                    export PATH="$value"
                    echo "[DEBUG] Exported PATH=$value"
                else
                    export "$name=$value"
                    echo "[DEBUG] Exported $name=$value"
                fi
                ;;
            *)
                echo "[DEBUG] Skipping variable: $name"
                ;;
        esac
    done < "$envfile"
    
    echo "[DEBUG] Environment variables processed"
    echo "[DEBUG] Final PATH entries:"
    echo "$PATH" | tr ':' '\n' | grep -i "visual studio"
    
    # Cleanup
    deleteFile "$tmpfile"
    deleteFile "$envfile"
    
    # Verify setup
    if ! command -v cl.exe &>/dev/null; then
        echo "Error: cl.exe not found in PATH after CMD-based setup"
        echo "[DEBUG] Current PATH: $PATH"
        return 1
    fi
    
    echo "MSVC environment loaded successfully via CMD (arch=$arch_bits)"
    return 0
}

# Call this as: setup_msvc_env "<x86|x64>"
function setup_msvc_env() {
    local arch_bits="$1"   # expected "x86" or "x64"
    
    ## On GitHub Actions, prefer the simpler cmd-based approach
    #if [[ -n "$GITHUB_ACTIONS" ]]; then
    #    echo "[DEBUG] Running in GitHub Actions environment, using cmd-based setup"
    #    setup_msvc_env_cmd "$arch_bits"
    #    return $?
    #fi
    
    
    local vswhere_path="" vs_base=""
    local tmpfile

    echo "[DEBUG] Starting MSVC environment setup for architecture: $arch_bits"
    echo "[DEBUG] Current PATH: $PATH"
    
    # --- find vswhere.exe ---
    echo "[DEBUG] Searching for vswhere.exe..."
    # First check chocolatey location (common in CI)
    if [[ -f "/c/ProgramData/Chocolatey/bin/vswhere.exe" ]]; then
        vswhere_path="/c/ProgramData/Chocolatey/bin/vswhere.exe"
    else
        # Try common locations
        for p in \
            "C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe" \
            "C:/Program Files/Microsoft Visual Studio/Installer/vswhere.exe" \
            "$(command -v vswhere.exe 2>/dev/null)"
        do
            [[ -f "$p" ]] && vswhere_path="$p" && break
        done
    fi
    
    if [[ -z "$vswhere_path" || ! -f "$vswhere_path" ]]; then
        echo "Error: vswhere.exe not found on PATH or in common locations."
        return 1
    fi

    # --- get installation path ---
    echo "[DEBUG] Running vswhere from: $vswhere_path"
    # Run vswhere directly to avoid PowerShell complexities
    local vswhere_out
    vswhere_out=$("$vswhere_path" -latest -products '*' -requires Microsoft.Component.MSBuild -property installationPath)
    echo "[DEBUG] Raw vswhere output:"
    echo "$vswhere_out"
    
    # Take the last non-empty line as the VS path
    vs_base=$(echo "$vswhere_out" | while read -r line; do
        [[ -n "$line" ]] && echo "$line"
    done | tail -1)
    echo "[DEBUG] Extracted VS path: $vs_base"
    
    if [[ -z "$vs_base" ]]; then
        echo "Error: Visual Studio installation not found via vswhere!"
        return 1
    fi
    
    # Convert to proper path format
    vs_base=$(convertPath "$vs_base")
    echo "Found Visual Studio at: $vs_base"

    # --- candidate scripts ---
    # Strip quotes from vs_base if present
    vs_base="${vs_base//\"/}"
    echo "[DEBUG] Checking VS scripts in: $vs_base"
    
    local vsdev="${vs_base}/Common7/Tools/VsDevCmd.bat"
    local vcvarsall="${vs_base}/VC/Auxiliary/Build/vcvarsall.bat"
    local vcvars32="${vs_base}/VC/Auxiliary/Build/vcvars32.bat"
    local vcvars64="${vs_base}/VC/Auxiliary/Build/vcvars64.bat"
    local chosen=""

    # Convert paths to Windows format for existence checks
    local win_vsdev=$(convertPath "$vsdev")
    local win_vcvarsall=$(convertPath "$vcvarsall")
    local win_vcvars32=$(convertPath "$vcvars32")
    local win_vcvars64=$(convertPath "$vcvars64")
    
    echo "[DEBUG] Checking script existence:"
    echo "[DEBUG] VsDevCmd: $win_vsdev"
    echo "[DEBUG] vcvarsall: $win_vcvarsall"
    echo "[DEBUG] vcvars32: $win_vcvars32"
    echo "[DEBUG] vcvars64: $win_vcvars64"

    # Use cmd.exe to check file existence since -f may not work reliably with Windows paths
    if cmd.exe /c "if exist ${win_vsdev} (exit 0) else (exit 1)" 2>/dev/null; then
        chosen="$vsdev"
        echo "Using VsDevCmd: $chosen"
    elif cmd.exe /c "if exist ${win_vcvarsall} (exit 0) else (exit 1)" 2>/dev/null; then
        chosen="$vcvarsall"
        echo "Using vcvarsall: $chosen"
    elif [[ "$arch_bits" == "x86" ]] && cmd.exe /c "if exist ${win_vcvars32} (exit 0) else (exit 1)" 2>/dev/null; then
        chosen="$vcvars32"
        echo "Using vcvars32: $chosen"
    elif [[ "$arch_bits" == "x64" ]] && cmd.exe /c "if exist ${win_vcvars64} (exit 0) else (exit 1)" 2>/dev/null; then
        chosen="$vcvars64"
        echo "Using vcvars64: $chosen"
    else
        # Use dir command to find any vcvars*.bat file
        local found
        found=$(cmd.exe /c "dir /b /s ${vs_base//\//\\}\\vcvars*.bat" 2>/dev/null | head -n 1)
        if [[ -n "$found" ]]; then
            chosen="${found//\\//}"
            echo "Found alternative vcvars script: $chosen"
        fi
    fi

    if [[ -z "$chosen" || ! -f "$chosen" ]]; then
        echo "Error: No suitable vcvars/VsDevCmd script found under $vs_base"
        return 1
    fi

    # --- create temp file ---
    tmpfile=$(makeTempFile)

    ## --- run script and dump environment using a temporary PowerShell script ---
    # Write a small .ps1 file so we avoid inline quoting issues and ensure the arch
    # argument is passed as a literal (x86/x64) to the vcvars/VsDevCmd script.
    ps1file=$(makeTempFile ".ps1")
    cat > "$ps1file" <<'PS1'
param(
[string]$chosen,
[string]$arch
)

Write-Host "[PS] Starting Visual Studio environment setup..."
Write-Host "[PS] Using script: $chosen"
Write-Host "[PS] Architecture: $arch"

# Try to call the script with explicit architecture
try {
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = "cmd.exe"
$processInfo.Arguments = "/c `"'$chosen' -arch $arch`""
$processInfo.RedirectStandardOutput = $true
$processInfo.RedirectStandardError = $true
$processInfo.UseShellExecute = $false

Write-Host "[PS] Executing VS environment script..."
$process = [System.Diagnostics.Process]::Start($processInfo)
$process.WaitForExit()

$output = $process.StandardOutput.ReadToEnd()
$error = $process.StandardError.ReadToEnd()

Write-Host "[PS] Script output:"
Write-Host $output
if ($error) {
    Write-Host "[PS] Script errors:"
    Write-Host $error
}

Write-Host "[PS] Script exit code: " + $process.ExitCode
} catch {
Write-Host "[PS] Error executing VS script: $_"
}

Write-Host "[PS] Current environment variables:"
Get-ChildItem env: | ForEach-Object { "$($_.Name)=$($_.Value)" }
PS1
    echo "---- ps1file ----"
    cat "$ps1file"
    echo "---------------------------------------------"

    # Run the PowerShell script with expanded bash variables (so arch is literal)
    # Capture both stdout and stderr into the tmpfile for richer diagnostics.
    #powershell -NoProfile -File "$(cygpath -w "$ps1file")" -chosen "$(cygpath -w "$chosen")" -arch "$arch_bits" 2>&1 | tr -d '\r' > "$tmpfile"

    echo "[DEBUG] Running PowerShell script with:"
    echo "[DEBUG] ps1file: $(cygpath -w "$ps1file")"
    echo "[DEBUG] chosen: $(cygpath -w "$chosen")"
    echo "[DEBUG] arch_bits: $arch_bits"

    # Run the PowerShell script using -File (pass the PS1 path directly). Capture both stdout and stderr.
    echo "[DEBUG] PowerShell command about to execute..."
    runPowerShell -NoProfile -File "$ps1file" -chosen "$chosen" -arch "$arch_bits" 2>&1 | tee >(cat >&2) | tr -d '\r' > "$tmpfile" || true
    
    echo "[DEBUG] PowerShell execution completed"
    echo "[DEBUG] Checking tmpfile contents..."
    if [[ -f "$tmpfile" ]]; then
        echo "[DEBUG] tmpfile exists and has size: $(wc -c < "$tmpfile") bytes"
        echo "[DEBUG] First few lines of tmpfile:"
        head -n 5 "$tmpfile"
    else
        echo "[DEBUG] tmpfile does not exist!"
    fi

    # --- sanity check ---
    if [[ ! -s "$tmpfile" ]] || ! grep -qE '^PATH=' "$tmpfile"; then
        echo "Error: Visual Studio environment script ran but did not produce output (check $chosen)."
        # show partial output for debugging
        echo "---- raw vsenv output ----"
        if [[ -f "$tmpfile" ]]; then
            cat "$tmpfile"
        else
            echo "(no tmpfile created)"
        fi
        echo "---------------------------------------------"
        deleteFile "$ps1file"
        deleteFile "$tmpfile"
        return 1
    fi

    # --- import a safe whitelist of environment variables into bash ---
    echo "[DEBUG] Processing environment variables from tmpfile..."
    
    # First, let's see what we're working with
    echo "[DEBUG] Environment variables found in tmpfile:"
    grep -E '^(PATH|INCLUDE|LIB|LIBPATH|VSINSTALLDIR|VisualStudioVersion|VSCMD_ARG_TGT_ARCH|VSCMD_ARG_HOST_ARCH)=' "$tmpfile" || echo "No matching variables found!"
    
    while IFS='=' read -r name value; do
        case "$name" in
            PATH|INCLUDE|LIB|LIBPATH|VSINSTALLDIR|VisualStudioVersion|VSCMD_ARG_TGT_ARCH|VSCMD_ARG_HOST_ARCH)
                echo "[DEBUG] Processing $name"
                if [[ "$name" == "PATH" ]]; then
                    # Ensure Windows path separators and prepend VS paths
                    value="${value//\\/\/}"  # Replace backslashes with forward slashes
                    if [[ "$value" != *"Common7/IDE"* ]]; then
                        value="$(dirname "$chosen")/Common7/IDE:$value"
                    fi
                    echo "[DEBUG] Modified PATH value: $value"
                fi
                export "$name=$value"
                echo "[DEBUG] Exported $name"
                ;;
            *)
                echo "[DEBUG] Skipping variable: $name"
                ;;
        esac
    done < "$tmpfile"
    
    echo "[DEBUG] Environment variables processed"
    echo "[DEBUG] Final PATH: $PATH"

    # --- export CC/CXX ---
    export CC="cl.exe"
    export CXX="cl.exe"

    deleteFile "$ps1file"
    deleteFile "$tmpfile"

    # --- verify cl.exe in PATH ---
    if ! command -v cl.exe &>/dev/null; then
        echo "Error: MSVC environment loaded but cl.exe not found in PATH"
        echo "------------- PATH --------------------------"
        echo "C${PATH}"
        echo "---------------------------------------------"
        return 1
    fi

    echo "MSVC environment loaded successfully (arch=$arch_bits)."
    return 0
}

