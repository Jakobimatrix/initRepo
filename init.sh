#!/bin/bash
#
#Execute this script to install clang-format on your machine (if not installed)
#and install hook in your git repository to check formating before committing.
#
#usage: sudo ./init.sh PATH_TO_YOUR_REPOSITORY

CLANG_FORMAT_VERSION="6.0";
HOOK_FILE=".git/hooks/pre-commit";

# validate input
REPRO="$1"

if [ $# -lt 1 ]
then
        echo "Usage: sudo ./init.sh PATH_TO_YOUR_REPOSITORY"
        exit
elif [ ! -d "$REPRO" ]
then
        echo "Given $REPRO does not exist!"
        exit
fi

SLASH_CHAR="/"
[ "${REPRO: -1}" != "$SLASH_CHAR" ] && REPRO=$REPRO$SLASH_CHAR

if [ ! -d "$REPRO.git/hooks/" ]
then
        echo "Given $REPRO is not a git repository"
        exit
fi

HOOK_FILE=$REPRO$HOOK_FILE

# install clang format
apt-get install clang-format-$CLANG_FORMAT_VERSION -y

# check if a pre-commit hook already exists
if [ -f "$HOOK_FILE" ]
then
        read -p "pre-commit (file) already exists. Should I [c]oncatinate, [o]verwrite or [e]xit?" coe
        case $coe in
                [Cc]* ) cat $HOOK_FILE clang-format > tmp.txt && mv tmp.txt $HOOK_FILE;;
                [Oo]* ) cp clang-format $HOOK_FILE;;
                [Ee]* ) exit;;
        esac
else
       cp clang-format $HOOK_FILE
fi

chmod +x $HOOK_FILE
echo "Clang-format installed in $HOOK_FILE"
