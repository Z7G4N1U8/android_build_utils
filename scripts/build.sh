#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Z7G4N1U8 (Peace)

function set_vars() {
  MANIFEST=$1
  BRANCH=$2
  TARGET=$3
  BUILD_TYPE=$4
}

case "$ANDROID" in
  LineageOS) set_vars https://github.com/LineageOS/android.git lineage-23.1 bacon userdebug ;;
  Evolution-X) set_vars https://github.com/Evolution-X/manifest.git bq1 evolution user ;;
esac

PROJECT=android
PROJECT_FILES=$HOME/files/$ANDROID
UTILS="https://raw.githubusercontent.com/$GH_REPOSITORY/refs/heads/main"
RSYNC_OPTS=( -avP --exclude='*-ota.zip' --include='*.zip' --exclude='*' )

function handle_error() {
  cat out/error.log
  paste out/error.log
  exit 1
} ; trap handle_error ERR

mkdir -p $PROJECT $PROJECT_FILES
curl -LSs $UTILS/scripts/gcpsetup.sh | bash

cd $PROJECT && rm -rf .repo/local_manifests
repo init --git-lfs -u $MANIFEST -b $BRANCH
git clone https://github.com/$GH_ACTOR/android_local_manifests.git .repo/local_manifests
curl -LSs $UTILS/scripts/sync.sh | bash

[ "$ANDROID" != "LineageOS" ] && (cd device/motorola/eqe && curl -LSs $UTILS/patches/$ANDROID.patch | git am) || true
source <(curl -LSs $UTILS/scripts/envsetup.sh)

breakfast eqe $BUILD_TYPE
cmka $TARGET

rsync "${RSYNC_OPTS[@]}" $OUT/ $PROJECT_FILES
[ $SF_UPLOAD == true ] && rsync "${RSYNC_OPTS[@]}" $OUT/ z7g4n1u8@frs.sourceforge.net:/home/frs/project/eqe/$ANDROID || true
