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
