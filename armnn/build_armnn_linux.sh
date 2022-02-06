# docker create  -v /mnt/c/iwatake/devel:/root/devel -v /etc/localtime:/etc/localtime:ro -it --name=ubuntu18_build_00 ubuntu:18.04
# docker start ubuntu18_build_00
# docker exec -it ubuntu18_build_00 bash

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
ARMNN_VERSION_TAG=v21.05

# Prepare output directory
DIR_TOP=`pwd`
DIR_ARTIFACTS=`pwd`/armnn_prebuilt/
mkdir ${DIR_ARTIFACTS}
DIR_ARM_DEV=`pwd`/armnn-devenv/
mkdir ${DIR_ARM_DEV}

# Install requirements
# Note: I use a cross-compiler provided by the distribution, but you can also use 
#   - http://releases.linaro.org/components/toolchain/binaries/latest-7/  , or 
#   - https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads
${L_SUDO} apt update
${L_SUDO} apt install -y build-essential git cmake wget unzip crossbuild-essential-arm64
${L_SUDO} apt install -y autoconf libtool g++ scons xxd
# ${L_SUDO} apt install -y libprotobuf-dev protobuf-compiler flatbuffers-compiler

# Build and install Google's Protobuf library
cd ${DIR_ARM_DEV}
git clone -b v3.12.0 https://github.com/google/protobuf.git protobuf
cd protobuf
git submodule update --init --recursive
./autogen.sh

mkdir x86_64_build && cd x86_64_build
../configure --prefix=${DIR_ARM_DEV}/google/x86_64_pb_install
make install -j4
cd ..

mkdir arm64_build && cd arm64_build
CC=aarch64-linux-gnu-gcc \
CXX=aarch64-linux-gnu-g++ \
../configure --host=aarch64-linux \
--prefix=${DIR_ARM_DEV}/google/arm64_pb_install \
--with-protoc=${DIR_ARM_DEV}/google/x86_64_pb_install/bin/protoc
make install -j4


# Build Boost library for arm64
cd ${DIR_ARM_DEV}
wget https://boostorg.jfrog.io/artifactory/main/release/1.64.0/source/boost_1_64_0.tar.gz
tar -zxvf boost_1_64_0.tar.gz
cd boost_1_64_0

./bootstrap.sh --prefix=${DIR_ARM_DEV}/boost_x86_64_install
./b2 install link=static cxxflags=-fPIC --with-test --with-log --with-program_options -j4

echo "using gcc : arm : aarch64-linux-gnu-g++ ;" > user_config.jam
./bootstrap.sh --prefix=${DIR_ARM_DEV}/boost_arm64_install
./b2 install toolset=gcc-arm link=static cxxflags=-fPIC --with-test --with-log --with-program_options -j4 --user-config=user_config.jam


# Build Flatbuffer
cd ${DIR_ARM_DEV}
wget -O flatbuffers-1.12.0.tar.gz https://github.com/google/flatbuffers/archive/v1.12.0.tar.gz
tar xf flatbuffers-1.12.0.tar.gz
cd flatbuffers-1.12.0
rm -f CMakeCache.txt
mkdir build
cd build
CXXFLAGS="-fPIC --std=c++14" cmake .. -DFLATBUFFERS_BUILD_FLATC=1 \
     -DCMAKE_INSTALL_PREFIX:PATH=${DIR_ARM_DEV}/flatbuffers \
     -DFLATBUFFERS_BUILD_TESTS=0
make all install

cd ..
mkdir build-arm64
cd build-arm64
# Add -fPIC to allow us to use the libraries in shared objects.
CXXFLAGS="-fPIC" cmake .. -DCMAKE_C_COMPILER=/usr/bin/aarch64-linux-gnu-gcc \
     -DCMAKE_CXX_COMPILER=/usr/bin/aarch64-linux-gnu-g++ \
     -DFLATBUFFERS_BUILD_FLATC=1 \
     -DCMAKE_INSTALL_PREFIX:PATH=${DIR_ARM_DEV}/flatbuffers-arm64 \
     -DFLATBUFFERS_BUILD_TESTS=0
make all install


# Build Onnx
cd ${DIR_ARM_DEV}
git clone https://github.com/onnx/onnx.git
cd onnx
git fetch https://github.com/onnx/onnx.git 553df22c67bee5f0fe6599cff60f1afc6748c635 && git checkout FETCH_HEAD
LD_LIBRARY_PATH=${DIR_ARM_DEV}/google/x86_64_pb_install/lib:$LD_LIBRARY_PATH \
${DIR_ARM_DEV}/google/x86_64_pb_install/bin/protoc \
onnx/onnx.proto --proto_path=. --proto_path=../google/x86_64_pb_install/include --cpp_out ${DIR_ARM_DEV}/onnx


# Build TfLite
cd ${DIR_ARM_DEV}
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow/
git checkout fcc4b966f1265f466e82617020af93670141b009
cd ..
mkdir tflite
cd tflite
cp ../tensorflow/tensorflow/lite/schema/schema.fbs .
../flatbuffers-1.12.0/build/flatc -c --gen-object-api --reflect-types --reflect-names schema.fbs


# Build Compute Library
cd ${DIR_ARM_DEV}
git clone https://github.com/ARM-software/ComputeLibrary.git
cd ComputeLibrary
git checkout $ARMNN_VERSION_TAG
# scons arch=x86_64 extra_cxx_flags="-fPIC" -j4 build_dir=x86_64
scons arch=arm64-v8a neon=1 opencl=1 embed_kernels=1 extra_cxx_flags="-fPIC" -j4 build_dir=arm64


# Build Arm NN
cd ${DIR_ARM_DEV}
git clone https://github.com/ARM-software/armnn.git
cd armnn
git checkout $ARMNN_VERSION_TAG
git pull

mkdir build-x86_64 && cd build-x86_64
cmake .. \
-DCMAKE_CXX_FLAGS=--std=c++14 \
-DBUILD_UNIT_TESTS=OFF \
-DARMCOMPUTE_ROOT= \
-DARMCOMPUTE_BUILD_DIR= \
-DBOOST_ROOT=${DIR_ARM_DEV}/boost_x86_64_install \
-DARMCOMPUTENEON=0 -DARMCOMPUTECL=0 -DARMNNREF=1 \
-DONNX_GENERATED_SOURCES=${DIR_ARM_DEV}/onnx \
-DBUILD_ONNX_PARSER=1 \
-DBUILD_TF_LITE_PARSER=1 \
-DTF_LITE_GENERATED_PATH=${DIR_ARM_DEV}/tflite \
-DFLATBUFFERS_ROOT=${DIR_ARM_DEV}/flatbuffers \
-DFLATC_DIR=${DIR_ARM_DEV}/flatbuffers-1.12.0/build \
-DPROTOBUF_ROOT=${DIR_ARM_DEV}/google/x86_64_pb_install \
-DPROTOBUF_ROOT=${DIR_ARM_DEV}/google/x86_64_pb_install \
-DPROTOBUF_LIBRARY_DEBUG=${DIR_ARM_DEV}/google/x86_64_pb_install/lib/libprotobuf.so.23.0.0 \
-DPROTOBUF_LIBRARY_RELEASE=${DIR_ARM_DEV}/google/x86_64_pb_install/lib/libprotobuf.so.23.0.0 \
-DCMAKE_INSTALL_PREFIX=./install
make -j4
make install
# tar czvf armnn_${ARMNN_VERSION_TAG}_x86_64.tgz install
# cp armnn_${ARMNN_VERSION_TAG}_x86_64.tgz  $OUT_DIR/.
cd ..

mkdir build-arm64 && cd build-arm64
CXX=aarch64-linux-gnu-g++ CC=aarch64-linux-gnu-gcc cmake .. \
-DARMCOMPUTE_ROOT=${DIR_ARM_DEV}/ComputeLibrary \
-DARMCOMPUTE_BUILD_DIR=${DIR_ARM_DEV}/ComputeLibrary/build/arm64 \
-DBOOST_ROOT=${DIR_ARM_DEV}/boost_arm64_install \
-DARMCOMPUTENEON=1 -DARMCOMPUTECL=1 -DARMNNREF=1 \
-DONNX_GENERATED_SOURCES=${DIR_ARM_DEV}/onnx \
-DBUILD_ONNX_PARSER=1 \
-DBUILD_TF_LITE_PARSER=1 \
-DTF_LITE_GENERATED_PATH=${DIR_ARM_DEV}/tflite \
-DFLATBUFFERS_ROOT=${DIR_ARM_DEV}/flatbuffers-arm64 \
-DFLATC_DIR=${DIR_ARM_DEV}/flatbuffers-1.12.0/build \
-DPROTOBUF_ROOT=${DIR_ARM_DEV}/google/x86_64_pb_install \
-DPROTOBUF_ROOT=${DIR_ARM_DEV}/google/x86_64_pb_install \
-DPROTOBUF_LIBRARY_DEBUG=${DIR_ARM_DEV}/google/arm64_pb_install/lib/libprotobuf.so.23.0.0 \
-DPROTOBUF_LIBRARY_RELEASE=${DIR_ARM_DEV}/google/arm64_pb_install/lib/libprotobuf.so.23.0.0 \
-DCMAKE_INSTALL_PREFIX=./install
make -j4
make install
# tar czvf armnn_${ARMNN_VERSION_TAG}_arm64.tgz install
# cp armnn_${ARMNN_VERSION_TAG}_arm64.tgz  $OUT_DIR/.
cd ..


# Make tar ball
cd ${DIR_ARTIFACTS}
mv ${DIR_ARM_DEV}/armnn/build-x86_64/install ${DIR_ARTIFACTS}/ubuntu
mv ${DIR_ARM_DEV}/armnn/build-arm64/install ${DIR_ARTIFACTS}/aarch64
mkdir ${DIR_ARTIFACTS}/protobuf_lib && mkdir ${DIR_ARTIFACTS}/protobuf_lib/ubuntu && mkdir ${DIR_ARTIFACTS}/protobuf_lib/aarch64
cp -r ${DIR_ARM_DEV}/google/x86_64_pb_install/lib/*.so* ${DIR_ARTIFACTS}/protobuf_lib/ubuntu/.
cp -r ${DIR_ARM_DEV}/google/arm64_pb_install/lib/*.so* ${DIR_ARTIFACTS}/protobuf_lib/aarch64/.
cd ${DIR_TOP}
tar czvf armnn_prebuilt_linux.tgz -C ${DIR_ARTIFACTS}/../ armnn_prebuilt
