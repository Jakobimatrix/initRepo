#!/bin/bash
# ensureToolVersion.sh
# given a executable and a version, makes sure that the executable is callable like executable-version

ensure_tool_versioned() {
  local tool_name="$1"
  local version="$2"
  local full_name="${tool_name}-${version}"

  if ! command -v "${full_name}" &>/dev/null; then
    if command -v "${tool_name}" &>/dev/null; then
      echo "${full_name} not found, linking to system ${tool_name}"
      sudo ln -s "$(command -v "${tool_name}")" "/usr/bin/${full_name}"
    else
      echo "Error: ${tool_name} not found at all!" >&2
      exit 1
    fi
  fi
}

ensure_tool_versioned_msvc() {
  local vs_version="$1"
  local arch="$2"
  
  if [[ "$arch" == "x86" ]]; then
    local base_path="C:/Program Files (x86)"
  else
    local base_path="C:/Program Files"
  fi
  
  if [ ! -d "${base_path}/Microsoft Visual Studio/${vs_version}" ]; then
    echo "Error: Visual Studio ${vs_version} not found!" >&2
    exit 1
  fi
}

ensure_tool_versioned_mingw() {
  local tool_name="$1"
  local expected_version="$2"
  
  # Get version from MinGW compiler
  local version_output
  if [[ "$tool_name" == "gcc" ]]; then
    version_output=$("$GCC_CPP_PATH" -dumpversion)
  elif [[ "$tool_name" == "clang" ]]; then
    version_output=$("$CLANG_CPP_PATH" --version | grep -oP 'version \K[0-9]+')
  fi

  if [[ "$version_output" != "$expected_version" ]]; then
    echo "Error: $tool_name version mismatch. Expected $expected_version, got $version_output" >&2
    exit 1
  fi
}