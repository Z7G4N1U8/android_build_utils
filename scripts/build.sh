#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Z7G4N1U8 (Peace)

case "$ANDROID" in
  LineageOS) vars=(android lineage-23.1 bacon userdebug) ;;
  Evolution-X) vars=(manifest bq1 evolution user) ;;
esac

PROJECT=$HOME/android
read -r MANIFEST BRANCH TARGET BUILD_TYPE <<< "${vars[@]}"
UTILS="https://raw.githubusercontent.com/$GH_REPOSITORY/refs/heads/main"
FILTERS=( --max-depth 1 --filter "- *-ota.zip" --filter "+ *.zip" --filter "- *" )

function handle_error() {
  cat out/error.log
  paste out/error.log
  exit 1
} ; trap handle_error ERR

curl -LSs $UTILS/scripts/gcpsetup.sh | bash

cd $PROJECT && rm -rf .repo/local_manifests
repo init --git-lfs -u https://github.com/$ANDROID/$MANIFEST.git -b $BRANCH
git clone https://github.com/$GH_ACTOR/android_local_manifests.git .repo/local_manifests
curl -LSs $UTILS/scripts/sync.sh | bash

[ "$ANDROID" != "LineageOS" ] && (cd device/motorola/eqe && curl -LSs $UTILS/patches/$ANDROID.patch | git am) || true
source <(curl -LSs $UTILS/scripts/envsetup.sh)

breakfast eqe $BUILD_TYPE
cmka $TARGET

rclone copy "${FILTERS[@]}" $OUT/ GoogleDrive:Android/$ANDROID/
rclone copy "${FILTERS[@]}" $OUT/ SourceForge:/home/frs/project/eqe/$ANDROID/
