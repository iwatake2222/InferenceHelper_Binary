# docker create  -v /mnt/c/iwatake/devel:/root/devel -v /etc/localtime:/etc/localtime:ro -it --name=ubuntu20_build_00 ubuntu:20.04
# docker start ubuntu20_build_00
# docker exec -it ubuntu20_build_00 bash

# Prepare output directory
DIR_TOP=`pwd`
DIR_ARTIFACTS=`pwd`/mnn_prebuilt
mkdir ${DIR_ARTIFACTS}


# Install requirements
# Note: I use a cross-compiler provided by the distribution, but you can also use 
#   - http://releases.linaro.org/components/toolchain/binaries/latest-7/  , or 
#   - https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads
apt update
apt install -y build-essential git cmake wget unzip libprotobuf-dev protobuf-compiler libvulkan-dev vulkan-utils g++-arm-linux-gnueabi g++-arm-linux-gnueabihf g++-aarch64-linux-gnu

wget https://dl.google.com/android/repository/android-ndk-r23b-linux.zip
unzip android-ndk-r23b-linux.zip
export ANDROID_NDK=`pwd`/android-ndk-r23b


# Get code
git clone https://github.com/alibaba/MNN.git
cd MNN
DIR_MNN=`pwd`
git checkout 1.2.6
./schema/generate.sh


# Native Build (linux_x64)
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=./install .. && make -j4 && make install
mv install ${DIR_ARTIFACTS}/ubuntu-2004
cd ../ && rm -rf build

mkdir build && cd build
cmake -DMNN_VULKAN=ON -DCMAKE_INSTALL_PREFIX=./install .. && make -j4 && make install
mv install ${DIR_ARTIFACTS}/ubuntu-2004-vulkan
cd ../ && rm -rf build


# Cross Build (aarch64)
mkdir build && cd build
cmake .. \
-DCMAKE_SYSTEM_NAME=Linux \
-DCMAKE_SYSTEM_VERSION=1 \
-DCMAKE_SYSTEM_PROCESSOR=aarch64 \
-DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
-DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
-DCMAKE_INSTALL_PREFIX=./install
make -j4 && make install
mv install ${DIR_ARTIFACTS}/aarch64
cd ../ && rm -rf build

mkdir build && cd build
cmake .. \
-DCMAKE_SYSTEM_NAME=Linux \
-DCMAKE_SYSTEM_VERSION=1 \
-DCMAKE_SYSTEM_PROCESSOR=aarch64 \
-DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
-DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
-DMNN_VULKAN=ON \
-DCMAKE_INSTALL_PREFIX=./install
make -j4 && make install
mv install ${DIR_ARTIFACTS}/aarch64-vulkan
cd ../ && rm -rf build


# Cross Build (armv7)
mkdir build && cd build
cmake .. \
-DCMAKE_SYSTEM_NAME=Linux \
-DCMAKE_SYSTEM_VERSION=1 \
-DCMAKE_SYSTEM_PROCESSOR=arm \
-DCMAKE_C_COMPILER=arm-linux-gnueabi-gcc \
-DCMAKE_CXX_COMPILER=arm-linux-gnueabi-g++ \
-DCMAKE_INSTALL_PREFIX=./install
make -j4 && make install
mv install ${DIR_ARTIFACTS}/armv7
cd ../ && rm -rf build

mkdir build && cd build
cmake .. \
-DCMAKE_SYSTEM_NAME=Linux \
-DCMAKE_SYSTEM_VERSION=1 \
-DCMAKE_SYSTEM_PROCESSOR=arm \
-DCMAKE_C_COMPILER=arm-linux-gnueabi-gcc \
-DCMAKE_CXX_COMPILER=arm-linux-gnueabi-g++ \
-DMNN_VULKAN=ON \
-DCMAKE_INSTALL_PREFIX=./install
make -j4 && make install
mv install ${DIR_ARTIFACTS}/armv7-vulkan


# Cross Build (Android)
cd ${DIR_MNN}
./schema/generate.sh
cd project/android
sed -e "s/-DCMAKE_BUILD_TYPE=Release/-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=install/g" build_64.sh > build_temp.sh
mkdir build_64 && cd build_64 && sh ../build_temp.sh && make install && cd ..
sed -e "s/-DCMAKE_BUILD_TYPE=Release/-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=install/g" build_32.sh > build_temp.sh
mkdir build_32 && cd build_32 && sh ../build_temp.sh && make install && cd ..
mkdir android
mv build_64/install android/arm64-v8a
mv build_32/install android/armeabi-v7a
mv android ${DIR_ARTIFACTS}/android

sed -e "s/-DCMAKE_BUILD_TYPE=Release/-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=install -DMNN_VULKAN=ON/g" build_64.sh > build_temp.sh
mkdir build_64_vulkan && cd build_64_vulkan && sh ../build_temp.sh && make install && cd ..
sed -e "s/-DCMAKE_BUILD_TYPE=Release/-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=install -DMNN_VULKAN=ON/g" build_32.sh > build_temp.sh
mkdir build_32_vulkan && cd build_32_vulkan && sh ../build_temp.sh && make install && cd ..
mkdir android-vulkan
mv build_64_vulkan/install android-vulkan/arm64-v8a
mv build_32_vulkan/install android-vulkan/armeabi-v7a
mv android-vulkan ${DIR_ARTIFACTS}/android-vulkan


# Build Converter (linux_x64)
cd ${DIR_MNN}
./schema/generate.sh
mkdir build_tool
cd build_tool
cmake .. -DMNN_BUILD_CONVERTER=on -DMNN_BUILD_QUANTOOLS=on -DMNN_BUILD_SHARED_LIBS=off
make -j4
mkdir tools-ubuntu-2004
find . -maxdepth 1  -executable -type f | xargs -I% mv % tools-ubuntu-2004/
mv tools-ubuntu-2004 ${DIR_ARTIFACTS}/tools-ubuntu-2004

# Compress artifacts
cd ${DIR_TOP}
tar czvf mnn_prebuilt_linux.tgz -C ${DIR_ARTIFACTS}/../ mnn_prebuilt
