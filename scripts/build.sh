#!/bin/bash

# Check if at least 3 argument is provided
if [ "$#" -lt 3 ]; then
    echo "Error: At least 3 arguments are required."
    exit 1
fi
android="${1}"
device="${2}"
build_type="${3}"

# my repo containing patches and scripts
build_utils="https://raw.githubusercontent.com/Z7G4N1U8/android_build_utils/refs/heads/main"

# Function for centralized error handling
handle_error() {
    local error_message="$1"
    echo "Error: ${error_message}."
    exit 1
}

echo "Cleaning up..."
for path in $(xmllint --xpath '//project/@path' ".repo/local_manifests/default.xml" | sed 's/path="//g; s/"//g'); do
    echo "Removing directory: $path"
    rm -rf "$path"
done
rm -rf vendor/private .repo/local_manifests

set -o pipefail
trap 'handle_error "An unexpected error occurred"' ERR

# crave resync script
local_script="/opt/crave/resync.sh"
remote_script="${build_utils}/scripts/resync.sh"

# Initialize ROM and Device source
case "${android}" in
    "LineageOS")
        repo_url="https://github.com/LineageOS/android.git"
        repo_branch="lineage-23.0"
        ;;
    "EvolutionX")
        repo_url="https://github.com/Evolution-X/manifest.git"
        repo_branch="bka"
        ;;
    "RisingOS")
        repo_url="https://github.com/RisingOS-Revived/android.git"
        repo_branch="qpr2"
        ;;
    "Matrixx")
        repo_url="https://github.com/ProjectMatrixx/android.git"
        repo_branch="15.0"
        ;;
    "PixelOS")
        repo_url="https://github.com/PixelOS-AOSP/manifest.git"
        repo_branch="fifteen"
        ;;
    *)
        handle_error "Invalid option: ${android}. Use lineage, evolution, or rising"
        ;;
esac
repo init --depth 1 --git-lfs --manifest-url ${repo_url} --manifest-branch ${repo_branch} || handle_error "Repo init failed"
curl -fLSs --create-dirs "${build_utils}/manifests/${device}.xml" -o .repo/local_manifests/default.xml || handle_error "Local manifest init failed"
git clone https://${GH_TOKEN}@github.com/Z7G4N1U8/android_vendor_private_keys vendor/private/keys || handle_error "cloning keys failed"

# check if local sync script exists. if not, use remote sync script
if [ -f "${local_script}" ]; then
    echo "Attempting to run local sync script: ${local_script}"
    "${local_script}" || handle_error "Local sync script execution failed"
else
    echo "Local sync script (${local_script}) not found."
    echo "Attempting to download and run remote sync script from: ${remote_script}"
    curl -fLSs "${remote_script}" | bash || handle_error "Remote sync script download or execution failed"
fi

# Dump ROM & Extract Vendor
cd device/motorola/eqe
git clone https://github.com/DumprX/DumprX.git && cd DumprX
bash dumper.sh https://mirrors.lolinet.com/firmware/lenomola/2024/eqe/official/RETAIL/EQE_RETAIL_15_V1UMS35H.10-67-7-2_subsidy-DEFAULT_regulatory-DEFAULT_cid50_CFC.xml.zip
cd ..
./extract-files.py DumprX/out
cd ../../..

# Apply patches
patches=(
    "packages/services/Telephony:2by2-Project/packages_services_Telephony/commit/6d1276ad67ec5a023e4d65cec1e0c659cf756cef"
)

for patch in "${patches[@]}"; do
    IFS=":" read -r patch_path patch_url <<< "${patch}"
    rm -rf ${patch_path}
    repo sync ${patch_path}
    cd ${patch_path}
    curl -fLSs https://github.com/${patch_url}.patch | git am
    cd -
done

echo "Starting build process..."
source build/envsetup.sh
brunch ${device} ${build_type}

echo "Uploading file..."
curl ${build_utils}/scripts/upload.sh | bash -s ${OUT}/{*.zip,recovery.img,vendor_boot.img}
