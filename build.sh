#!/bin/bash
set -e
OLD_PWD=$PWD
trap 'cd "${OLD_PWD}"' EXIT

ARCH=$(uname -m)
SRC_BASE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPT_DIR="${SRC_BASE_DIR}/scripts"

RUN_MODULE_BUILD=1
if [[ -z "$MODULE" ]]; then
  if [[ -z "$1" ]]; then
    echo "You must specify name of module to build or execute build script from specifi module folder"
    exit 1
  fi
  MODULE="$1"
else
  # If MODULE variable is specified, there is expected the build script is executed
  # from module folder
  RUN_MODULE_BUILD=0
fi

BUILD_BASE_DIR="${SRC_BASE_DIR}/build-${ARCH}"

get_module_dirs () {
  local MODULE_DIR="${SRC_BASE_DIR}/$1"
  declare -g $1_MODULE_DIR="${MODULE_DIR}"
  declare -g $1_BUILD_DIR="${BUILD_BASE_DIR}/$1/compile"
  declare -g $1_SRC_DIR="${MODULE_DIR}/src"
  declare -g $1_PATCH_DIR="${MODULE_DIR}/patch"
  declare -g $1_DATA_DIR="${MODULE_DIR}/data"
  declare -g $1_APPDIR="${BUILD_BASE_DIR}/$1/AppDir"
  declare -g $1_DOWNLOAD_DIR="${BUILD_BASE_DIR}/$1/download"
} 

get_module_dirs ${MODULE}

# Declare aliases for currently build module
declare -n BUILD_DIR="${MODULE}_BUILD_DIR"
declare -n SRC_DIR="${MODULE}_SRC_DIR"
declare -n PATCH_DIR="${MODULE}_PATCH_DIR"
declare -n DATA_DIR="${MODULE}_DATA_DIR"
declare -n APPDIR="${MODULE}_APPDIR"
declare -n MODULE_DIR="${MODULE}_MODULE_DIR"
declare -n DOWNLOAD_DIR="${MODULE}_DOWNLOAD_DIR"

if [[ ! -d "${MODULE_DIR}" ]]; then
  echo "Error: Module directory not found: ${MODULE_DIR}"
  exit 1
fi

# Update SRC folder if does not exist
[[ ! -e "${SRC_DIR}/.git" ]] && git submodule update --init -- ${SRC_DIR}

mkdir -p "${BUILD_DIR}"

if [[ -d "${PATCH_DIR}" ]]; then
    echo "Apply patches to: ${SRC_DIR}"
    if [[ ! -e  "${MODULE_DIR}/.patched" ]]; then
        cd "${SRC_DIR}"
        git am "${PATCH_DIR}"/*.patch
        touch "${MODULE_DIR}/.patched"
    else
        echo "Already patched - skipped"
    fi
else
    echo "  There are not any patches"
fi

if [[ $RUN_MODULE_BUILD == 1 ]]; then
  source "${MODULE_DIR}/build.sh"
fi

cd "${MODULE_DIR}"
