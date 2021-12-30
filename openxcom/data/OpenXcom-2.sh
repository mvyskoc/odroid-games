#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

APPIMAGE=("${SCRIPT_DIR}"/OpenXcom-*.AppImage)

mkdir -p "${APPIMAGE}.home"
mkdir -p "${APPIMAGE}.config"

"$APPIMAGE" --setup -master xcom2 $@

