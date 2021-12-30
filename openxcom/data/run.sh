#!/bin/bash
set -e

if [[ ! -d "${APPDIR}" ]]; then
  echo "APPDIR is not defined."
  export APPDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  echo "  APPDIR=${APPDIR}"
  echo ""
fi

XBOXDRV_MAPPINGS="${APPDIR}/usr/share/openxcom/xboxdrv"
XBOXDRV_MAPPINGS_USR="${HOME}/.openxcom/xboxdrv"

GAME_DATA="${HOME}/.openxcom"
if [[ ! -z "${XDG_DATA_HOME}" ]]; then
    GAME_DATA="${XDG_DATA_HOME}/openxcom"
fi

GAME_CONFIG="${HOME}/.config/openxcom"
if [[ ! -z "${XDG_CONFIG_HOME}" ]]; then
    GAME_CONFIG="${XDG_CONFIG_HOME}/openxcom"
fi


echo "Command line arguments:"
echo "  --xboxdrv-test"      
echo "       Setup xboxdv configuration without running game"
echo "  --setup"
echo "       Configure udev rules for write access by current user"
echo ""
 
mkdir -p -v ${XBOXDRV_MAPPINGS} ${XBOXDRV_MAPPINGS_USR}

# Copy but do not ovewrite user user files
cp -n -v "${XBOXDRV_MAPPINGS}"/*.ini "${XBOXDRV_MAPPINGS_USR}"

# Check if uinput device is available with write access
if [[ -e /dev/uinput ]]; then
    if [[ ! -w /dev/uinput ]]; then
        if [[ "${1}" == "--setup" ]]; then 
           sudo install -v -m 664 ${APPDIR}/etc/udev/rules.d/10-uinput.rules /etc/udev/rules.d
           echo "Udev rules will be updated after restart. Setup rules temporarily by chmod command"
           sudo chmod -v 0660 /dev/uinput
           echo "Add current user into the input group"
           [[ $EUID != 0 ]] && sudo usermod -a -G input $USERNAME
        else
           echo "Missing write access permision to /dev/uinput"
           echo "Start ${0} --setup to configure udev rules and add current user to input group."
        fi
    fi
else
    echo "Device /dev/uinput is not available"
fi

# Select configuration for specific device
if [[ ! -e "${GAME_CONFIG}/options.cfg" ]]; then
  mkdir -p "${GAME_CONFIG}"
  if [[ -e /dev/input/by-path/platform-odroidgo3-joypad-event-joystick ]]; then
  # Odroid GO Super
    cp "$APPDIR/usr/share/openxcom/common/config/options-ogs.cfg" "${GAME_CONFIG}/options.cfg"
  else
    cp "$APPDIR/usr/share/openxcom/common/config/options.cfg" "${GAME_CONFIG}/options.cfg"
  fi  
fi

# Check if game data files are available, patch if needed
mkdir -p "${GAME_DATA}/UFO"
[[ ! -e "${GAME_DATA}/UFO/README.txt" ]] && \
    cp -f "$APPDIR/usr/share/openxcom/UFO/README.txt" "${GAME_DATA}/UFO"
 
if [[ -d "${GAME_DATA}/UFO/GEODATA" ]]; then
    if [[ ! -e "${GAME_DATA}/UFO/patch.txt" ]]; then
        echo "Apply patch to data files: ${GAME_DATA}/UFO"
        cp -fR "$APPDIR/usr/share/openxcom/patch/UFO" "${GAME_DATA}"
    fi
else
    echo "XCOM-1 data files not found"
    echo   "Data folder: ${GAME_DATA}/UFO"
fi

# Patch XCOM-2 data files
mkdir -p "${GAME_DATA}/TFTD"
[[ ! -e "${GAME_DATA}/TFTD/README.txt" ]] && \
    cp -f "$APPDIR/usr/share/openxcom/TFTD/README.txt" "${GAME_DATA}/TFTD"
 
if [[ -d "${GAME_DATA}/TFTD/GEODATA" ]]; then
    if [[ ! -e "${GAME_DATA}/TFTD/patch.txt" ]]; then
        echo "Apply patch to data files: ${GAME_DATA}/TFTD"
        cp -fR "$APPDIR/usr/share/openxcom/patch/TFTD" "${GAME_DATA}"
    fi
else
    echo "XCOM-2 data files not found"
    echo   "Data folder: ${GAME_DATA}/UFO"
fi

FOUND_INI=0
for xboxdrv_ini in "${XBOXDRV_MAPPINGS_USR}"/*.ini
do
    EVDEV=$(grep -P "evdev[[:space:]]*=" ${xboxdrv_ini} | cut -d= -f2 | xargs)
    echo ""
    echo "Check compatibility of xboxdrv configuration:"
    echo "  path: ${xboxdrv_ini}"
    echo "  device: ${EVDEV}"
    if [[ -c ${EVDEV} ]]; then
        FOUND_INI=1
        echo "  comaptible: YES"
        break
    fi
done

[[ "${1}" == "--setup" ]] && shift

if [[ $FOUND_INI == 1 ]]; then 
    echo "Found xboxdrv mapping: ${xboxdrv_ini}"
    if [[ "${1}" == "--xboxdrv-test" ]]; then
        "${APPDIR}/usr/bin/xboxdrv" -c "${xboxdrv_ini}"
    else
        "${APPDIR}/usr/bin/xboxdrv" -c "${xboxdrv_ini}" -- "${APPDIR}/usr/bin/openxcom" $@
        kill -- -$$ || true
    fi
else
    echo "ERROR: Cannot find suitable xboxdrv ini for your gamepad."
    echo "Please add it to ${XBOXDRV_MAPPINGS_USR}"
    "${APPDIR}/usr/bin/openxcom"
fi

