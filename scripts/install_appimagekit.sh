#!/bin/bash
set -e

ARCH=$(uname -m)
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TOOLS="${SCRIPT_DIR}/tools"

# Download tools for bulding app image
# https://appimage-builder.readthedocs.io/en/latest/intro/install.html


if [[ ! -e `which appimagetool` ]]; then
    echo "Download appimagetool and install into /usr/local/bin"
    if [ "$ARCH" = "x86_64" ]; then
        wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O /tmp/appimagetool
    elif [ "$ARCH" = "aarch64" ]; then
        wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-aarch64.AppImage  -O /tmp/appimagetool
    else
        echo "Architecture ${ARCH} not supported"
    fi
    if [[ ! -e `which unsquashfs` ]]; then
        sudo apt install -y squashfs-tools
    fi
    
    # Extract the archive, because AppImage is not possible execute in chroot environment
    ELFSIZE=$(readelf -h /tmp/appimagetool)
    START_OF_SECTION=$(echo $ELFSIZE | grep -oP "(?<=Start of section headers: )[0-9]+")
    SECTION_SIZE=$(echo $ELFSIZE | grep -oP "(?<=Size of section headers: )[0-9]+")
    SECTION_NO=$(echo $ELFSIZE | grep -oP "(?<=Number of section headers: )[0-9]+")
    APPIMG_OFFSET=$(( $START_OF_SECTION + $SECTION_SIZE * $SECTION_NO ))
    unsquashfs -o $APPIMG_OFFSET -d /usr/local/share/appimagetool /tmp/appimagetool
    rm /tmp/appimagetool
    ln -s /usr/local/share/appimagetool/AppRun /usr/local/bin/appimagetool
fi

if [[ ! -e `which appimage-builder` ]]; then
    echo "Install appimage-builder"
    sudo apt-get update
    sudo apt install -y python3-pip python3-setuptools patchelf desktop-file-utils libgdk-pixbuf2.0-dev fakeroot strace fuse    
    sudo pip3 install git+https://github.com/AppImageCrafters/appimage-builder.git
fi

