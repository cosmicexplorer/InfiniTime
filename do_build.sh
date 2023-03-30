#!/bin/bash

# FIXME: create a spack recipe for infinitime which installs these python and js deps and builds the
# cmake project!

set -euo pipefail

## (1) Install python dependencies.
export PY=python3

"$PY" -m venv .venv/

source .venv/bin/activate

"$PY" -m pip install wheel adafruit-nrfutil -r tools/mcuboot/requirements.txt

## (2) Install js dependencies.
npm install lv_{font,img}_conv swc

## (3) Execute cmake.
mkdir -pv build/

function configured_cmake {
  cmake \
    -S . \
    -B build/ \
    -DARM_NONE_EABI_TOOLCHAIN_PATH="$ARM_NONE_EABI_TOOLCHAIN_PATH" \
    -DNRF5_SDK_PATH="$NRF5_SDK_PATH" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_DFU=1 \
    -DBUILD_RESOURCES=1 \
    "$@"
}


function get_project_version {
  configured_cmake -L 2>&1 \
    | sed -rne 's#^.*Version : (.+)$#\1#gp'
}

project_version="$(get_project_version)"

# Execute cmake to generate the Makefile.
configured_cmake

## (4) Execute make.
make -C build/ -j"${MAKE_JOBS:-12}" pinetime-mcuboot-app

result="build/src/pinetime-mcuboot-app-dfu-${project_version}.zip"

ln -sfv "$result" current-dfu
