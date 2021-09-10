#!/bin/bash

# Set Working Dir
sudo mkdir -p /opt/ffmpeg_build
sudo chmod 777 /opt/ffmpeg_build -R
sudo chown runner:docker /opt/ffmpeg_build -R

# Install rclone
curl -sL git.io/Rclone4fr3aky.sh | bash

# Build ffmpeg
cd /opt/ffmpeg_build
curl -sL https://github.com/rokibhasansagar/ffmpeg-build-script/raw/update3/build-ffmpeg -O
chmod a+x build-ffmpeg
sudo apt-get -qy install \
  build-essential curl ca-certificates libva-dev libdrm-dev python3 python-is-python3 libtool \
  intel-microcode intel-gpu-tools intel-opencl-icd intel-media-va-driver opencl-headers \
  libwayland-dev mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers mesa-utils mesa-utils-extra \
  libglx-dev libgl1-mesa-glx libgl1-mesa-dev
NUMJOBS=8 SKIPINSTALL=yes ./build-ffmpeg --build --enable-gpl-and-non-free --full-static

# Check Binary
./workspace/bin/ffmpeg -hide_banner -buildconf
./workspace/bin/ffmpeg -hide_banner -hwaccels

# Upload
rclone delete td:/ffmpeg_testBuilds/ --progress || true
for i in ffmpeg ffplay ffprobe; do
  rclone copy ./workspace/bin/${i} td:/ffmpeg_testBuilds/ --progress
done
