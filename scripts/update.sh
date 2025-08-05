#!/bin/bash
# update.sh
# Updates the initRepo subrepository and optionally updates default files in the main repo.

set -e

# Go to the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"


git stash
git pull

# Go to the main repository root
cd ../../

git add initRepo

# shellcheck disable=SC2162 # read -r does not work here
read -p "Update default files? [y/n]: " yn
case $yn in
    [Yy]* )
        echo "Running ./initRepo/scripts/init.sh ..."
        ./initRepo/scripts/init.sh
        ;;
    * )
        echo "Default files not updated."
        ;;
esac
