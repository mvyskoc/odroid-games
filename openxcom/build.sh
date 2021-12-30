#!/bin/bash
set -e
MODULE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
MODULE=`basename "${MODULE_DIR}"`

[[ -z $RUN_MODULE_BUILD  ]] && source "${MODULE_DIR}/../build.sh"

# Install dependency files
sudo apt install libyaml-cpp-dev

# Build source codes
cd ${BUILD_DIR}
if [[ ! -e "${BUILD_DIR}/.cmake_done" ]]; then
  if [[ "${ARCH}" == "x86_64" ]]; then
    cmake ${SRC_DIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DUSE_OPENGL=ON
  else
    cmake ${SRC_DIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DUSE_OPENGL=OFF
  fi
  touch "${BUILD_DIR}/.cmake_done"
fi

make
make install DESTDIR="${APPDIR}"

# https://openxcom.org/translations/latest.zip


