#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Z7G4N1U8 (Peace)

function setup_disk() {
  sudo blkid $1 >/dev/null || sudo mkfs.ext4 -F -q -m 0 $1
  mkdir -p $2
  mountpoint -q $2 || { sudo mount "$1" "$2" && sudo chown -R $(whoami):$(whoami) "$2"; }
} ; setup_disk /dev/disk/by-id/google-local-nvme-ssd-0 android

packages=(
  # lineage
  "bc" "bison" "build-essential" "ccache" "curl" "flex" "g++-multilib" "gcc-multilib"
  "git" "git-lfs" "gnupg" "gperf" "imagemagick" "protobuf-compiler" "python3-protobuf"
  "python-is-python3" "lib32readline-dev" "lib32z1-dev" "libdw-dev" "libelf-dev"
  "lib32ncurses-dev" "libncurses6" "libncurses-dev" "lz4" "libsdl1.2-dev" "libssl-dev"
  "libxml2" "libxml2-utils" "lzop" "pngcrush" "rsync" "schedtool" "squashfs-tools"
  "xsltproc" "zip" "zlib1g-dev"

  # extra
  "btop" "linux-modules-extra-$(uname -r)" "micro" "rclone"
)

# Install all necessary packages
sudo apt-get update -y
sudo apt-get install -y "${packages[@]}"

# Configure git
git_configs=(
  "user.name Peace"
  "user.email git@z7g4n1u8.dev"
  "trailer.changeid.key Change-Id"
)

for config in "${git_configs[@]}"; do
  git config --global ${config}
done

git lfs install

# Setup ssh
echo "$SSH_KEY" > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub
cat <<EOF > ~/.ssh/config
Host *
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF

# Setup rclone.conf
mkdir -p ~/.config/rclone
echo "$RCLONE_CONF" > ~/.config/rclone/rclone.conf

# Install repo
sudo curl -LSs https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo
sudo chmod +x /usr/local/bin/repo

# Kernel Tuning
kernel_settings=(
  "net.core.default_qdisc=fq"
  "net.ipv4.tcp_congestion_control=bbr"
  "net.ipv4.tcp_slow_start_after_idle=0"
)

sudo sysctl -q "${kernel_settings[@]}"
