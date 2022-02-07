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

# Prepare output directory
DIR_TOP=`pwd`
DIR_ARTIFACTS=`pwd`/mnn_prebuilt
mkdir ${DIR_ARTIFACTS}


# Install requirements
# Note: I use a cross-compiler provided by the distribution, but you can also use 
#   - http://releases.linaro.org/components/toolchain/binaries/latest-7/  , or 
#   - https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads
${L_SUDO} apt update
${L_SUDO} apt install -y build-essential git cmake wget unzip libprotobuf-dev protobuf-compiler libvulkan-dev vulkan-utils g++-arm-linux-gnueabi g++-arm-linux-gnueabihf g++-aarch64-linux-gnu

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
mv install ${DIR_ARTIFACTS}/ubuntu
cd ../ && rm -rf build

mkdir build && cd build
cmake -DMNN_VULKAN=ON -DCMAKE_INSTALL_PREFIX=./install .. && make -j4 && make install
mv ./express/libMNN_Express.so install/lib/. && mv ./source/backend/vulkan/libMNN_Vulkan.so install/lib/.
mv install ${DIR_ARTIFACTS}/ubuntu-vulkan
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
mv ./express/libMNN_Express.so install/lib/. && mv ./source/backend/vulkan/libMNN_Vulkan.so install/lib/.
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
mv ./express/libMNN_Express.so install/lib/. && mv ./source/backend/vulkan/libMNN_Vulkan.so install/lib/.
mv install ${DIR_ARTIFACTS}/armv7-vulkan
cd ../ && rm -rf build

# Cross Build (Android)
# cd ${DIR_MNN}
# ./schema/generate.sh
mkdir ${DIR_ARTIFACTS}/android-vulkan

mkdir build && cd build
cmake ../ \
-DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
-DCMAKE_BUILD_TYPE=Release \
-DANDROID_ABI="arm64-v8a" \
-DANDROID_STL=c++_static \
-DMNN_USE_SSE=OFF \
-DMNN_SUPPORT_BF16=OFF \
-DCMAKE_INSTALL_PREFIX=install \
-DANDROID_NATIVE_API_LEVEL=android-21  \
-DMNN_BUILD_FOR_ANDROID_COMMAND=true \
-DNATIVE_LIBRARY_OUTPUT=. -DNATIVE_INCLUDE_OUTPUT=. \
-DMNN_VULKAN=ON
make -j4 && make install && mv libMNN*.so install/lib/
mv install ${DIR_ARTIFACTS}/android-vulkan/arm64-v8a
cd ../ && rm -rf build

mkdir build && cd build
cmake ../ \
-DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
-DCMAKE_BUILD_TYPE=Release \
-DANDROID_ABI="armeabi-v7a" \
-DANDROID_STL=c++_static \
-DMNN_USE_SSE=OFF \
-DMNN_SUPPORT_BF16=OFF \
-DCMAKE_INSTALL_PREFIX=install \
-DANDROID_NATIVE_API_LEVEL=android-14  \
-DANDROID_TOOLCHAIN=clang \
-DMNN_BUILD_FOR_ANDROID_COMMAND=true \
-DNATIVE_LIBRARY_OUTPUT=. -DNATIVE_INCLUDE_OUTPUT=. \
-DMNN_VULKAN=ON
make -j4 && make install && mv libMNN*.so install/lib/
mv install ${DIR_ARTIFACTS}/android-vulkan/armeabi-v7a
cd ../ && rm -rf build


# Build Converter (linux_x64)
cd ${DIR_MNN}
./schema/generate.sh
mkdir build_tool
cd build_tool
cmake .. -DMNN_BUILD_CONVERTER=on -DMNN_BUILD_QUANTOOLS=on -DMNN_BUILD_SHARED_LIBS=off
make -j4
mkdir tools-ubuntu
find . -maxdepth 1  -executable -type f | xargs -I% mv % tools-ubuntu/
mv tools-ubuntu ${DIR_ARTIFACTS}/tools-ubuntu

# Compress artifacts
cd ${DIR_TOP}
tar czvf mnn_prebuilt_linux.tgz -C ${DIR_ARTIFACTS}/../ mnn_prebuilt
