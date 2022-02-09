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
${L_SUDO} apt install -y python python3 python3-pip
pip3 install numpy
# wget https://github.com/bazelbuild/bazel/releases/download/3.7.2/bazel-3.7.2-installer-linux-x86_64.sh
# bash ./bazel-3.7.2-installer-linux-x86_64.sh
wget https://github.com/bazelbuild/bazel/releases/download/4.2.1/bazel-4.2.1-installer-linux-x86_64.sh
${L_SUDO} bash ./bazel-4.2.1-installer-linux-x86_64.sh

## For TensorFlow Lite Android
${L_SUDO} apt install -y --no-install-recommends default-jdk
wget https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip
unzip commandlinetools-linux-7583922_latest.zip
mkdir android-sdk
yes | ./cmdline-tools/bin/sdkmanager "platform-tools"  --sdk_root=./android-sdk
./cmdline-tools/bin/sdkmanager "platforms;android-30"  --sdk_root=./android-sdk
./cmdline-tools/bin/sdkmanager "build-tools;30.0.3"  --sdk_root=./android-sdk
# apt install android-sdk
export ANDROID_SDK_HOME=`pwd`/android-sdk

wget https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip
unzip android-ndk-r21e-linux-x86_64.zip
export ANDROID_NDK_HOME=`pwd`/android-ndk-r21e
# wget https://dl.google.com/android/repository/android-ndk-r23b-linux.zip
# unzip android-ndk-r23b-linux.zip
# export ANDROID_NDK_HOME=`pwd`/android-ndk-r23b


# Get code
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
DIR_TFLITE=`pwd`
git checkout ${TFLITE_VERSION_TAG}


# Native Build (linux_x64)
PYTHON_BIN_PATH=/usr/bin/python3 \
PYTHON_LIB_PATH=/usr/lib/python3/dist-packages \
TF_NEED_ROCM=0 \
TF_NEED_CUDA=0 \
TF_DOWNLOAD_CLANG=0 \
CC_OPT_FLAGS="-Wno-sign-compare" \
TF_SET_ANDROID_WORKSPACE=False \
python3 configure.py

bazel build //tensorflow/lite:libtensorflowlite.so \
-c opt \
--copt -O3 \
--strip always \
--define tflite_with_xnnpack=true

bazel build  //tensorflow/lite/delegates/gpu:libtensorflowlite_gpu_delegate.so \
-c opt \
--copt -DTFLITE_GPU_BINARY_RELEASE \
--copt -DMESA_EGL_NO_X11_HEADERS \
--copt -DEGL_NO_X11

mkdir -p ${DIR_ARTIFACTS}/ubuntu
cp bazel-bin/tensorflow/lite/libtensorflowlite.so ${DIR_ARTIFACTS}/ubuntu/.
cp bazel-bin/tensorflow/lite/delegates/gpu/libtensorflowlite_gpu_delegate.so ${DIR_ARTIFACTS}/ubuntu/.


# Cross Build (aarch64)
bazel build //tensorflow/lite:libtensorflowlite.so \
-c opt \
--copt -O3 \
--strip always \
--config elinux_aarch64  \
--define tflite_with_xnnpack=true
# --define tensorflow_mkldnn_contraction_kernel=0 \

# bazel build  //tensorflow/lite/delegates/gpu:libtensorflowlite_gpu_delegate.so \
# -c opt \
# --copt -O3 \
# --strip always \
# --config elinux_aarch64 \
# --copt -DTFLITE_GPU_BINARY_RELEASE \
# --copt -DMESA_EGL_NO_X11_HEADERS \
# --copt -DEGL_NO_X11

mkdir -p ${DIR_ARTIFACTS}/aarch64
cp bazel-bin/tensorflow/lite/libtensorflowlite.so ${DIR_ARTIFACTS}/aarch64/.
# cp bazel-bin/tensorflow/lite/delegates/gpu/libtensorflowlite_gpu_delegate.so ${DIR_ARTIFACTS}/aarch64/.


# Cross Build (armv7)
bazel build //tensorflow/lite:libtensorflowlite.so \
-c opt \
--copt -O3 \
--copt -fno-tree-pre \
--copt -fpermissive \
--copt -march=armv7-a \
--copt -mfpu=neon-vfpv4 \
--define raspberry_pi_with_neon=true \
--strip always \
--config elinux_armhf \
--define tflite_with_xnnpack=false
# --define tensorflow_mkldnn_contraction_kernel=0 \

# bazel build  //tensorflow/lite/delegates/gpu:libtensorflowlite_gpu_delegate.so \
# -c opt \
# --config elinux_armhf \
# --copt -DTFLITE_GPU_BINARY_RELEASE \
# --copt -DMESA_EGL_NO_X11_HEADERS \
# --copt -DEGL_NO_X11

mkdir -p ${DIR_ARTIFACTS}/armv7
cp bazel-bin/tensorflow/lite/libtensorflowlite.so ${DIR_ARTIFACTS}/armv7/.
# cp bazel-bin/tensorflow/lite/delegates/gpu/libtensorflowlite_gpu_delegate.so ${DIR_ARTIFACTS}/armv7/.


# Cross Build (Android armv8)
## Patch for NNAPI support
awk ' \
$0 ~ "name = \"framework_experimental\"," {found_target=1} \
found_target {found_target=!sub("\"//tensorflow/lite/schema:schema_fbs\",", "\"//tensorflow/lite/schema:schema_fbs\",\"//tensorflow/lite/delegates/nnapi:nnapi_delegate\",\"//tensorflow/lite/nnapi:nnapi_implementation\",")} \
1' tensorflow/lite/BUILD > temp.txt
mv temp.txt tensorflow/lite/BUILD

## Build
PYTHON_BIN_PATH=/usr/bin/python3 \
PYTHON_LIB_PATH=/usr/lib/python3/dist-packages \
TF_NEED_ROCM=0 \
TF_NEED_CUDA=0 \
TF_DOWNLOAD_CLANG=0 \
CC_OPT_FLAGS="-Wno-sign-compare" \
TF_SET_ANDROID_WORKSPACE=True \
ANDROID_NDK_API_LEVEL=28 \
ANDROID_API_LEVEL=30 \
ANDROID_BUILD_TOOLS_VERSION=30.0.3 \
python3 configure.py

bazel build //tensorflow/lite:libtensorflowlite.so \
-c opt \
--copt -O3 \
--strip always \
--config android_arm64  \
--define tflite_with_xnnpack=true

bazel build //tensorflow/lite/delegates/gpu:libtensorflowlite_gpu_delegate.so \
-c opt \
--copt -O3 \
--strip always \
--copt -DTFLITE_GPU_BINARY_RELEASE \
--config android_arm64

mkdir -p ${DIR_ARTIFACTS}/android/arm64-v8a
cp bazel-bin/tensorflow/lite/libtensorflowlite.so ${DIR_ARTIFACTS}/android/arm64-v8a/.
cp bazel-bin/tensorflow/lite/delegates/gpu/libtensorflowlite_gpu_delegate.so ${DIR_ARTIFACTS}/android/arm64-v8a/.

# Cross Build (Android armv7)
bazel build //tensorflow/lite:libtensorflowlite.so \
-c opt \
--config android_arm \
--copt -O3 \
--strip always \
--define tflite_with_xnnpack=true

bazel build //tensorflow/lite/delegates/gpu:libtensorflowlite_gpu_delegate.so \
-c opt \
--copt -O3 \
--strip always \
--copt -DTFLITE_GPU_BINARY_RELEASE \
--config android_arm

mkdir -p ${DIR_ARTIFACTS}/android/armeabi-v7a
cp bazel-bin/tensorflow/lite/libtensorflowlite.so ${DIR_ARTIFACTS}/android/armeabi-v7a/.
cp bazel-bin/tensorflow/lite/delegates/gpu/libtensorflowlite_gpu_delegate.so ${DIR_ARTIFACTS}/android/armeabi-v7a/.

# Compress artifacts
cd ${DIR_TOP}
tar czvf tflite_prebuilt_linux.tgz -C ${DIR_ARTIFACTS}/../ tflite_prebuilt
