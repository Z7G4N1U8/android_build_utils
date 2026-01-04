#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Z7G4N1U8 (Peace)

source build/envsetup.sh &> /dev/null
source <(curl -LSs $UTILS/scripts/rbe.sh)

# Setup ccache
ccache -M 50G
ccache -o compression=true
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR=$HOME/android/ccache

# Set build user/host name and timezone
export BUILD_USERNAME=$USER
export BUILD_HOSTNAME=$HOSTNAME
export TZ=Asia/Kolkata

# Temp build error fix
export SKIP_ABI_CHECKS=true

function paste() {
  local FILE=${1:-/dev/stdin}
  curl --data-binary @$FILE https://paste.rs
}
