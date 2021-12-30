#!/bin/bash
set -e
MODULE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
MODULE=`basename "${MODULE_DIR}"`

[[ -z $RUN_MODULE_BUILD  ]] && source "${MODULE_DIR}/../build.sh"

if [[ "$1" == "clean" ]]; then
  echo "Xboxdrv: Clean build directory"
  cd "${SRC_DIR}"
  python2 `which scons` -c
  rm -rf .sconf_temp/
  rm -f .sconsign.dblite
  rm -f config.log
  exit 0
fi

if [[ -e "${APPDIR}/usr/bin/xboxdrv" ]]; then
  echo "Xboxdrv is already compiled"
  echo "   APPDIR: ${APPDIR}"
  echo
  exit 0
fi

# Install dependency files
sudo apt-get install \
 g++ \
 libboost1.71-dev \
 scons \
 pkg-config \
 libusb-1.0-0-dev \
 libx11-dev \
 libudev-dev \
 x11proto-core-dev \
 libdbus-glib-1-dev

cd "${SRC_DIR}" 
python2 `which scons`
make PREFIX=/usr DESTDIR="${APPDIR}" install


