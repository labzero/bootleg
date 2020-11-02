#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
echo $SCRIPT_DIR

cd "${SCRIPT_DIR}/../.."

if ! command -v pip3 >/dev/null; then
    echo "You must have Python and Pip installed to build the docs!"
    exit 2
fi

if ! command -v virtualenv >/dev/null; then
    echo "Need virtualenv, but not present, installing.."
    pip3 install virtualenv
fi

if [ ! -d _venv ]; then
    virtualenv _venv
fi
source _venv/bin/activate
pip3 install -q -r script/docs/requirements.txt

mkdocs "$@"
