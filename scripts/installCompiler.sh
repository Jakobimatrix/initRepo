#!/bin/bash

set -e

# Ensure we are in the script folder repo/initRepo/scripts/:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Source environment variables
source "../.environment"
if [ -f "../../.environment" ]; then
    source "../../.environment"
fi

# shellcheck disable=SC2162 # read -r does not work here
read -p "Do you want to install Clang ${CLANG_VERSION}? [y/N] " install_clang
if [[ "$install_clang" =~ ^[Yy]$ ]]; then
    echo "Installing Clang ${CLANG_VERSION}..."
    wget -qO- https://apt.llvm.org/llvm.sh | sudo bash -s -- "$CLANG_VERSION"
    sudo apt install -y clang-"${CLANG_VERSION}" lld-"${CLANG_VERSION}" lldb-"${CLANG_VERSION}"
    clang-"$CLANG_VERSION" --version
else
    echo "Skipping Clang installation."
fi

# shellcheck disable=SC2162 # read -r does not work here
read -p "Do you want to install GCC ${GCC_VERSION}? [y/N] " install_gcc
if [[ "$install_gcc" =~ ^[Yy]$ ]]; then
    echo "Adding GCC PPA and installing GCC ${GCC_VERSION}..."
    sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
    sudo apt update
    sudo apt install -y gcc-"${GCC_VERSION}" g++-"${GCC_VERSION}" gdb
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-"${GCC_VERSION}" 60 --slave /usr/bin/g++ g++ /usr/bin/g++-"${GCC_VERSION}"
    gcc-"${GCC_VERSION}" --version
else
    echo "Skipping GCC installation."
fi
