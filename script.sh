#!/bin/bash

# Set Working Dir
sudo mkdir -p /opt/ffmpeg_build
sudo chmod 777 /opt/ffmpeg_build -R
sudo chown runner:docker /opt/ffmpeg_build -R

# Update Apt-cache
sudo apt-fast update -qqy

echo "::group:: Change GCC Version to 10"
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 90
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 100
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 90
sudo update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-10 100
sudo update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-9 90
sudo update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-10 100
sudo update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-9 90
sudo update-alternatives --install /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-dump-10 100
sudo update-alternatives --install /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-dump-9 90
sudo update-alternatives --install /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-tool-10 100
sudo update-alternatives --install /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-tool-9 90
sudo update-alternatives --install /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-10 100
sudo update-alternatives --install /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-9 90
sudo update-alternatives --install /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-10 100
sudo update-alternatives --install /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-9 90
sudo update-alternatives --install /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-10 100
sudo update-alternatives --install /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-9 90
echo "::endgroup::"

echo "::group:: Install rclone"
curl -sL git.io/Rclone4fr3aky.sh | bash
echo "::endgroup::"

cd /opt/ffmpeg_build
curl -sL https://github.com/rokibhasansagar/ffmpeg-build-script/raw/update3/build-ffmpeg -O
chmod a+x build-ffmpeg
echo "::group:: Prepare ffmpeg dependencies"
sudo apt-fast -qqy install \
  build-essential cmake m4 libtool make automake curl ca-certificates libva-dev libvdpau-dev libmfx-dev libnuma-dev libdrm-dev \
  intel-microcode intel-gpu-tools intel-opencl-icd intel-media-va-driver ocl-icd-opencl-dev opencl-headers \
  libwayland-dev mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers mesa-utils mesa-utils-extra \
  libglx-dev libgl1-mesa-glx libgl1-mesa-dev ninja-build yasm nasm xmlto asciidoc
sudo -EH pip3 install meson
cargo install cargo-c
echo "::endgroup::"

echo "::group:: Build ffmpeg"
NUMJOBS=8 SKIPINSTALL=yes ./build-ffmpeg --build --enable-gpl-and-non-free --full-static
echo "::endgroup::"

echo "::group:: Check Workspace and Binaries"
ls -lAog ./workspace/*
echo "::endgroup::"

echo "::group:: Check Configs"
for i in ./workspace/bin/*; do
  printf "Checking Shared Library for %s..\n" "${i}"
  ldd ${i}
  printf "\n"
done
echo "::endgroup::"

[[ -f ./workspace/bin/ffmpeg ]] || exit 1

echo "::group:: Check Configs"
./workspace/bin/x265 -V
echo
./workspace/bin/ffmpeg -hide_banner -buildconf
echo
./workspace/bin/ffmpeg -hide_banner -encoders
echo
./workspace/bin/ffmpeg -hide_banner -h encoder=libx265
echo
echo "::endgroup::"

echo "::group:: Upload"
rclone delete td:/ffmpeg_testBuilds/ --progress || true
for i in ffmpeg ffplay ffprobe x264 x265; do
  rclone copy ./workspace/bin/${i} td:/ffmpeg_testBuilds/ --progress
done
echo "::endgroup::"
