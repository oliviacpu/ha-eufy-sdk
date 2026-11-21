#!/usr/bin/env bash
# The fork's checks: install, tests, ruff. Run from the repository root.
set -euo pipefail
python3 -m pip install --quiet -r requirements_common.txt -r requirements_dev.txt pytest
python3 -m pytest tests -q
python3 -m ruff check custom_components tests
python3 -m ruff format --check custom_components tests
