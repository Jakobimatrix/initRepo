#!/bin/bash
#
#Execute this script to install clang-format on your machine (if not installed)
#and install hook in your git repository to check formating before committing.
#
#usage: ./init.sh PATH_TO_YOUR_REPOSITORY


# Prevent running the script with sudo
if [ "$EUID" -eq 0 ]; then
  echo "This script should not be run as root or with sudo privileges."
  exit 1
fi

# Ensure we are in the script folder repo/initRepo/scripts/:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# find all scripts in the current folder and make them executable
find . -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;


# Source environment variables
# shellcheck disable=SC1091 # its there trust me
source "../.environment"
if [ -f "../../.environment" ]; then
    # shellcheck disable=SC1091 # its there trust me
    source "../../.environment"
fi


HOOK_FILE_DEST=".git/hooks/pre-commit";
HOOK_SCRIPT="format_hook";
FORMAT_FILE_F=".clang-format"
FORMAT_FILE_T=".clang-tidy"
GIT_ATTRIBUTES_FILE=".gitattributes"
GIT_IGNORE_FILE=".gitignore"
GIT_MODULES_FILE=".gitmodules"
GITHUB_HOOK_FILE="ubuntu_build_test.yml"
GITHUB_HOOK_FILE_DEST=".github/workflows"
CMAKE_LISTS_FILE="CMakeLists.txt"
PROCECT_STRUCUR_FOLDER="src/"
PROCECT_STRUCUR_TEMPLATE="../src/"

TEMPLATE_FILE_PATH="../templates/"


REPO="../../"

if [ ! -d "$REPO.git/hooks/" ]
then
  echo "Given $REPO is not a git repository"
  exit
fi

askYesNo() {
  echo; echo -e "\e[33m**********************\e[0m"; echo; 
  while true; do     
    # shellcheck disable=SC2162
    read -p $'Do you want to \e[1;4;34m'"$task"$'\e[0m? [y/n]' yn
    case $yn in
      [Yy]* ) answer=1; break;; 
      [Nn]* ) answer=0; break;;
      * ) echo -e "\e[33mPlease answer yes or no.\e[0m";; 
    esac 
  done  
}

copyFileWithPrompt() {
  local src="$1"
  local dest="$2"

  if [ ! -f "$dest" ]; then
    cp "$src" "$dest"
    echo "$(basename "$dest") installed"
  else
    task="The file $(basename "$dest") already exists. Do you want to overwrite it?"
    askYesNo
    if [ $answer = 1 ]; then
      cp -f "$src" "$dest"
      echo "$(basename "$dest") overwritten"
    else
      echo "$(basename "$dest") not overwritten"
    fi
  fi
}

if ! command -v clang-format-"${CLANG_FORMAT_VERSION}" >/dev/null 2>&1; then
  task="Do you want to install clang-format-${CLANG_FORMAT_VERSION}"
  askYesNo 
  if [ $answer = 1  ]
  then 
    # install clang format
    sudo apt install clang-format-"${CLANG_FORMAT_VERSION}" -y
    echo "clang-format-${CLANG_FORMAT_VERSION} installed"
  fi
fi

task="Do you want to install clang-format --> pre-comit git hook?"
askYesNo
if [ $answer = 1 ]
then
  cp "$TEMPLATE_FILE_PATH$HOOK_SCRIPT" "$REPO$HOOK_FILE_DEST"
  chmod +x "$REPO$HOOK_FILE_DEST"
  echo "Clang-format hook installed in $REPO$HOOK_FILE_DEST"
fi

if ! command -v shellcheck >/dev/null 2>&1; then
  task="Do you want to install shellcheck?"
  askYesNo
  if [ $answer = 1 ]
  then
    sudo apt install shellcheck -y
  fi
fi

if ! command -v gcovr >/dev/null 2>&1; then
  task="o you want to install gcovr --> code coverage for gcc"
  askYesNo
  if [ $answer = 1 ]
  then
    sudo apt install gcovr -y
  fi
fi

cp "$TEMPLATE_FILE_PATH$FORMAT_FILE_F" "$REPO"
echo ".clang-format copied"

if ! command -v clang-tidy-"${CLANG_TIDY_VERSION}" >/dev/null 2>&1; then
  task="Do you want to install/update clang-tidy-${CLANG_TIDY_VERSION}?"
  askYesNo
  if [ $answer = 1 ]
  then
    sudo apt install clang-tidy-"${CLANG_TIDY_VERSION}" -y
    echo "clang-tidy-${CLANG_TIDY_VERSION} installed"
  fi
fi
cp "$TEMPLATE_FILE_PATH$FORMAT_FILE_T" "$REPO"
echo ".clang-tidy copied"

if ! command -v cppcheck >/dev/null 2>&1; then
  task="Do you want to install cppcheck?"
  askYesNo
  if [ $answer = 1 ]
  then
    sudo apt install cppcheck -y
    echo "cppcheck installed"
  fi
fi

if ! command -v valgrind >/dev/null 2>&1; then
  task="Do you want to install valgrind?"
  askYesNo
  if [ $answer = 1 ]
  then
    sudo apt install valgrind -y
    echo "valgrind installed"
  fi
fi

echo "Dont continue if you already initiated your repo!"


task="Do you want to enforece LF line ending for that REPO?"
askYesNo
if [ $answer = 1 ]
then
  cp "$TEMPLATE_FILE_PATH$GIT_ATTRIBUTES_FILE" "$REPO"
  echo ".gitattributes installed, LF line ending enforeced" 
fi

task="Do you want to copy the .gitignore?"
askYesNo
if [ $answer = 1 ]
then
  copyFileWithPrompt "$TEMPLATE_FILE_PATH$GIT_IGNORE_FILE" "$REPO$GIT_IGNORE_FILE"
fi

if [ ! -f "$REPO$GIT_MODULES_FILE" ]
then
  task="Do you want to copy the .gitmodules?"
  askYesNo
  if [ $answer = 1 ]
    then
    cp "$TEMPLATE_FILE_PATH$GIT_MODULES_FILE" "$REPO$GIT_MODULES_FILE"
  fi
fi


task="Do you want to copy the github CI/CD pipeline script <build and test for ubuntu>?"
askYesNo
if [ $answer = 1 ]
then
  mkdir -p "${REPO}$GITHUB_HOOK_FILE_DEST"
  copyFileWithPrompt "$TEMPLATE_FILE_PATH$GITHUB_HOOK_FILE" "${REPO}$GITHUB_HOOK_FILE_DEST/$GITHUB_HOOK_FILE"
fi

task="Do you want to copy the Cmake project?"
askYesNo
if [ $answer = 1 ]; then
  copyFileWithPrompt "$TEMPLATE_FILE_PATH$CMAKE_LISTS_FILE" "$REPO$CMAKE_LISTS_FILE"
fi

task="Do you want to copy the procect structure?"
askYesNo
if [ $answer = 1 ]
then
  if [ ! -d "$REPO$PROCECT_STRUCUR_FOLDER" ]; then
    cp -r "$PROCECT_STRUCUR_TEMPLATE" "$REPO$PROCECT_STRUCUR_FOLDER"
    echo "$REPO$PROCECT_STRUCUR_FOLDER installed"
  else
    echo "$REPO$PROCECT_STRUCUR_FOLDER already exists. !!!Do you really want to Overwrite???"
    askYesNo
    if [ $answer = 1 ]; then
      rm -rf "$REPO$PROCECT_STRUCUR_FOLDER"
      cp -r "$PROCECT_STRUCUR_TEMPLATE" "$REPO$PROCECT_STRUCUR_FOLDER"
      echo "$REPO$PROCECT_STRUCUR_FOLDER overwritten"
    fi
  fi
fi

./build.sh -l

