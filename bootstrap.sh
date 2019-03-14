#!/usr/bin/env bash

VENV="venv"

# Check prerequisites
prerequisites=(virtualenv python3)
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
    pip install -r requirements.txt
fi

source ${VENV}/bin/activate
