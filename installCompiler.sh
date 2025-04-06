#!/bin/bash

set -e

CLANG_VERSION="19"
GCC_VERSION="13"

read -p "Do you want to install Clang ${CLANG_VERSION}? [y/N] " install_clang
if [[ "$install_clang" =~ ^[Yy]$ ]]; then
    echo "Installing Clang ${CLANG_VERSION}..."
    wget -qO- https://apt.llvm.org/llvm.sh | bash -s -- "$CLANG_VERSION"
    apt install -y clang-${CLANG_VERSION} lld-${CLANG_VERSION} lldb-${CLANG_VERSION}
    clang-$CLANG_VERSION --version
else
    echo "Skipping Clang installation."
fi

read -p "Do you want to install GCC ${GCC_VERSION}? [y/N] " install_gcc
if [[ "$install_gcc" =~ ^[Yy]$ ]]; then
    echo "Adding GCC PPA and installing GCC ${GCC_VERSION}..."
    add-apt-repository -y ppa:ubuntu-toolchain-r/test
    apt update
    apt install -y gcc-${GCC_VERSION} g++-${GCC_VERSION} gdb
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 60 --slave /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION}
    gcc-${GCC_VERSION} --version
else
    echo "Skipping GCC installation."
fi
