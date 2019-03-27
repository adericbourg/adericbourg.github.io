#!/usr/bin/env bash

VENV="venv"
THEME="${VENV}/dev-random4"

# Check prerequisites
prerequisites=(git virtualenv python3)
echo "Checking prerequisites..."
for prerequisite in ${prerequisites[@]}; do
    echo -n "  ${prerequisite}... "
    if ! type "$prerequisite" &> /dev/null; then
        echo "missing command ${prerequisite} in path."
        echo "Cancelling bootstrap..."
        return 1
    else
        echo "OK"
    fi
done

if [ ! -d "${VENV}" ]; then
    virtualenv -p python3 ${VENV}
fi

source ${VENV}/bin/activate

pip install -r requirements.txt

# Install theme
if [ -d "${THEME}" ]; then
    cd ${THEME}
    git reset --hard
    git pull --rebase
    cd -
else
    git clone git@github.com:adericbourg/pelican-dev-random4.git ${THEME}
fi
echo "Installing theme"
pelican-themes --clean
pelican-themes --upgrade ${THEME}
