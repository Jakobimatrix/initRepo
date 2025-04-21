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


TEMPLATE_FILE_PATH=$(realpath "$0" | sed 's|\(.*\)/.*|\1|')

CLANG_FORMAT_VERSION="19";
CLANG_TIDY_VERSION="19";
HOOK_FILE_DEST="$.git/hooks/pre-commit";
HOOK_SCRIPT="format_hook";
FORMAT_FILE_F=".clang-format"
FORMAT_FILE_T=".clang-tidy"
GIT_ATTRIBUTES_FILE=".gitattributes"
GIT_IGNORE_FILE=".gitignore"
CMAKE_LISTS_FILE="CMakeLists.txt"
BUILD_FILE="build.sh"
FUZZER_FILE="runFuzzer.sh"
PROCECT_STRUCUR_FOLDER="src/"
PROCECT_STRUCUR_TEMPLATE="$TEMPLATE_FILE_PATH/src/"

TEMPLATE_FILE_PATH="$TEMPLATE_FILE_PATH/templates/"



# validate input
REPO="$1"

if [ $# -lt 1 ]
then
        echo "Usage: ./init.sh PATH_TO_YOUR_REPOSITORY"
        exit
elif [ ! -d "$REPO" ]
then
        echo "Given $REPO does not exist!"
        exit
fi
SLASH_CHAR="/"
REPO="${REPO%/}$SLASH_CHAR"

if [ ! -d "$REPO.git/hooks/" ]
then
  echo "Given $REPO is not a git repository"
  exit
fi

askYesNo() {
  echo; echo -e "\e[33m**********************\e[0m"; echo; 
  while true; do     
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
      cp "$src" "$dest"
      echo "$(basename "$dest") overwritten"
    else
      echo "$(basename "$dest") not overwritten"
    fi
  fi
}

task="Do you want to installUpdate clang-format-$CLANG_FORMAT_VERSION and hooks"
askYesNo 
if [ $answer = 1  ]
then 
  # install clang format
  sudo apt install clang-format-$CLANG_FORMAT_VERSION -y

  cp "$TEMPLATE_FILE_PATH$HOOK_SCRIPT" "$REPO$HOOK_FILE_DEST"
  cp "$TEMPLATE_FILE_PATH$FORMAT_FILE_F" "$REPO"
  chmod +x "$REPO$HOOK_FILE_DEST"

  echo "Clang-format installed in $REPO$HOOK_FILE_DEST"
fi

task="Do you want to install/update clang-tidy-$CLANG_TIDY_VERSION?"
askYesNo
if [ $answer = 1 ]
then
  sudo apt install clang-tidy-$CLANG_TIDY_VERSION -y
  cp "$TEMPLATE_FILE_PATH$FORMAT_FILE_T" "$REPO"
  echo "clang-tidy-$CLANG_TIDY_VERSION"
fi

task="Do you want to install cppcheck?"
askYesNo
if [ $answer = 1 ]
then
  sudo apt install cppcheck -y
  echo "cppcheck installed"
fi

task="Do you want to install valgrind?"
askYesNo
if [ $answer = 1 ]
then
  sudo apt install valgrind -y
  echo "valgrind installed"
fi

task="Do you want to enforece LF line ending for that REPO?"
askYesNo
if [ $answer = 1 ]
then
  cp "$TEMPLATE_FILE_PATH$GIT_ATTRIBUTES_FILE" "$REPO"
  echo ".gitattributes installed, LF line ending enforeced" 
fi

echo "Dont continue if you already initiated your repo!"

task="Do you want to copy the .gitignore?"
askYesNo
if [ $answer = 1 ]; then
  copyFileWithPrompt "$TEMPLATE_FILE_PATH$GIT_IGNORE_FILE" "$REPO$GIT_IGNORE_FILE"
fi

task="Do you want to copy the Cmake project?"
askYesNo
if [ $answer = 1 ]; then
  copyFileWithPrompt "$TEMPLATE_FILE_PATH$CMAKE_LISTS_FILE" "$REPO$CMAKE_LISTS_FILE"
fi

task="Do you want to copy the build script?"
askYesNo
if [ $answer = 1 ]; then
  copyFileWithPrompt "$TEMPLATE_FILE_PATH$BUILD_FILE" "$REPO$BUILD_FILE"
fi

task="Do you want to copy the fuzzer run script?"
askYesNo
if [ $answer = 1 ]; then
  copyFileWithPrompt "$TEMPLATE_FILE_PATH$FUZZER_FILE" "${REPO}fuzz/$FUZZER_FILE"
fi


task="Do you want to copy the procect structure?"
askYesNo
if [ $answer = 1 ]
then
  if [ ! -d "$REPO$PROCECT_STRUCUR_FOLDER" ]; then
    cp -r "$PROCECT_STRUCUR_TEMPLATE" "$REPO$PROCECT_STRUCUR_FOLDER"
    echo "$REPO$PROCECT_STRUCUR_FOLDER installed"
  else
    echo "$REPO$PROCECT_STRUCUR_FOLDER already exists. Don't overwrite."
  fi
fi



