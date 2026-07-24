#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
SIMKA_HOST=0.0.0.0 SIMKA_PORT=3389 SIMKA_NO_BROWSER=1 python3 app.py
