#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export APPDIR=${SCRIPT_DIR}/AppDir
#export XDG_DATA_HOME="${SCRIPT_DIR}/data"
#export XDG_CONFIG_HOME="${SCRIPT_DIR}/config"
export HOME="${SCRIPT_DIR}/OpenXcom-x86_64.AppImage.home"
#export XDG_CONFIG_HOME="${SCRIPT_DIR}/OpenXcom-x86_64.AppImage.config"

${APPDIR}/AppRun $@
