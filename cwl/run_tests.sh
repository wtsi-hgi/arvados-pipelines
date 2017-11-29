#!/bin/bash

set -euf -o pipefail

tmp_folder=$(mktemp -d)
venv="${tmp_folder}/venv"
echo "Creating virtual env ${venv}"
virtualenv "${venv}"
set +u
. "${venv}/bin/activate"
set -u

echo "Installing requirements for tests"
pip install -r test_requirements.txt

echo "Running tests"
py.test tests/test.py 

echo "Deactivating virtualenv and deleting ${tmp_folder}"
deactivate
rm -r "${tmp_folder}"
