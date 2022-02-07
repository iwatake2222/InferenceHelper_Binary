# docker create  -v /mnt/c/iwatake/devel:/root/devel -v /etc/localtime:/etc/localtime:ro -it --name=ubuntu20_build_00 ubuntu:20.04
# docker start ubuntu20_build_00
# docker exec -it ubuntu20_build_00 bash

# Check if sudo needed
sudo
if [ "$?" -le 10 ]
then
L_SUDO=sudo
else
L_SUDO=
fi

set -e

# Set env
TFLITE_VERSION_TAG=v2.8.0

# Prepare output directory
DIR_TOP=`pwd`
DIR_ARTIFACTS=`pwd`/tflite_prebuilt
mkdir ${DIR_ARTIFACTS}


# Install requirements
## For TensorFlow Lite
${L_SUDO} apt update
${L_SUDO} apt install -y apt-transport-https wget curl gnupg cmake build-essential git unzip
${L_SUDO} apt install -y mesa-common-dev libegl1-mesa-dev libgles2-mesa-dev

## CMake
wget https://github.com/Kitware/CMake/releases/download/v3.21.5/cmake-3.21.5-linux-x86_64.tar.gz
tar xzvf cmake-3.21.5-linux-x86_64.tar.gz
${L_SUDO} apt remove -y cmake
${L_SUDO} cp cmake-3.21.5-linux-x86_64/bin/cmake /usr/bin/.
${L_SUDO} cp -r cmake-3.21.5-linux-x86_64/share/cmake-3.21 /usr/share/.


# Get code
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
DIR_TFLITE=`pwd`
git checkout ${TFLITE_VERSION_TAG}


# Native Build (linux_x64)
mkdir build && cd build
cmake ${DIR_TFLITE}/tensorflow/lite \
-DCMAKE_BUILD_TYPE=Release \
-DTFLITE_ENABLE_XNNPACK=ON
# -DTFLITE_ENABLE_GPU=ON
# -DBUILD_SHARED_LIBS=ON

cmake --build . -j4


