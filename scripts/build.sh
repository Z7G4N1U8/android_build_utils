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

cleanup() {
    echo "Cleaning up..."
    for patch in "${patches[@]}"; do
        patch_url="${build_utils}/patches/${patch}.patch"
        echo "Processing reverse patch: ${patch} from ${patch_url}"

        if grep -q "Reversed (or previously applied) patch detected!" <(curl -fLSs "${patch_url}" | patch --dry-run --strip 1 --fuzz 3 2>&1); then
            echo "Attempting to reverse ${patch} patch..."
            curl -fLSs "${patch_url}" | patch --strip 1 --fuzz 3 --reverse || handle_error "Failed to reverse ${patch} patch"
            echo "${patch} patch reversed successfully."
        else
            echo "${patch} patch has not been applied. Skipping."
        fi
        echo
    done
    rm -rf {device,vendor,kernel,hardware}/motorola vendor/private .repo/local_manifests
    unset GH_TOKEN
    echo "Exiting."
}

set -o pipefail
trap 'handle_error "An unexpected error occurred"' ERR
trap 'cleanup' EXIT

# crave resync script
local_script="/opt/crave/resync.sh"
remote_script="${build_utils}/scripts/resync.sh"

# Initialize ROM and Device source
case "${android}" in
    "LineageOS")
        repo_url="https://github.com/LineageOS/android.git"
        repo_branch="lineage-22.2"
        ;;
    "EvolutionX")
        repo_url="https://github.com/Evolution-X/manifest.git"
        repo_branch="vic"
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
curl -fLSs --create-dirs "${build_utils}/manifests/${android}.xml" -o .repo/local_manifests/default.xml || handle_error "Local manifest init failed"
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

# Apply patches
patches=(
    "telephony"
    "vibrator"
    "misc_kernel"
    "temp"
)

for patch in "${patches[@]}"; do
    patch_url="${build_utils}/patches/${patch}.patch"
    echo "Processing patch: ${patch} from ${patch_url}"

    if ! grep -q "Reversed (or previously applied) patch detected!" <(curl -fLSs "${patch_url}" | patch --dry-run --strip 1 --fuzz 3 2>&1); then
        echo "Attempting to apply ${patch} patch..."
        curl -fLSs "${patch_url}" | patch --strip 1 --fuzz 3 || handle_error "Failed to apply ${patch} patch"
        echo "${patch} patch applied successfully."
    else
        echo "${patch} patch has already been applied. Skipping."
    fi
    echo
done

echo "Exporting important variables..."
export TZ="Asia/Kolkata"
export TARGET_HAS_UDFPS=true
export DISABLE_ARTIFACT_PATH_REQUIREMENTS=true

echo "Starting build process..."
source build/envsetup.sh
brunch ${device} ${build_type}

echo "Uploading file..."
curl ${build_utils}/scripts/upload.sh | bash -s ${OUT}/{*.zip,recovery.img,vendor_boot.img}
