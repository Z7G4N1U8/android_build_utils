#!/bin/bash

handle_error() {
    echo "Error: $1."
    exit 1
}

echo "Cleaning up..."
for path in $(xmllint --xpath '//project/@path' ".repo/local_manifests/default.xml" | sed 's/path="//g; s/"//g'); do
    echo "Removing directory: $path"
    rm -rf "$path"
done
rm -rf vendor/private .repo/local_manifests ${removals}

set -o pipefail
trap 'handle_error "An unexpected error occurred"' ERR

case "${android}" in
    "LineageOS")
        manifest="https://github.com/LineageOS/android.git"
        branch="lineage-23.0"
        target="bacon"
        ;;
    "EvolutionX")
        manifest="https://github.com/Evolution-X/manifest.git"
        branch="bka"
        target="evolution"
        ;;
esac
repo init --depth 1 --git-lfs -u ${manifest} -b ${branch} || handle_error "Repo init failed"
curl -fLSs --create-dirs "${utils}/manifests/${device}.xml" -o .repo/local_manifests/default.xml || handle_error "Local manifest init failed"
git clone https://${token}@github.com/Z7G4N1U8/android_vendor_private_keys vendor/private/keys || handle_error "cloning keys failed"

if [ -f "/opt/crave/resync.sh" ]; then
    echo "Attempting to run sync script..."
    /opt/crave/resync.sh || handle_error "sync script execution failed"
else
    echo "Attempting to run repo sync command..."
    repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all) || handle_error "repo sync execution failed"
fi

# Dump ROM & Extract Vendor
cd device/motorola/eqe
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env bash
sudo apt update -y && sudo apt install protobuf-compiler python3-protobuf -y
git clone https://github.com/DumprX/DumprX.git && cd DumprX
bash dumper.sh https://mirrors.lolinet.com/firmware/lenomola/2024/eqe/official/RETAIL/EQE_RETAIL_15_V1UMS35H.10-67-7-2_subsidy-DEFAULT_regulatory-DEFAULT_cid50_CFC.xml.zip
cd ..
./extract-files.py DumprX/out
rm -rf DumprX
cd ../../..

echo "Starting build process..."
source build/envsetup.sh
breakfast ${device} ${build}
cmka ${target}
